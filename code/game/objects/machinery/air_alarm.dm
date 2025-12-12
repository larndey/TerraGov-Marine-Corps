// Please note this is GONNA START WORKING NOW HAHAH
#define AALARM_SCREEN_MAIN 1
#define AALARM_SCREEN_VENT 2
#define AALARM_SCREEN_SCRUB 3
#define AALARM_SCREEN_MODE 4
#define AALARM_SCREEN_SENSORS 5

#define AALARM_REPORT_TIMEOUT 100

#define RCON_NO 1
#define RCON_AUTO 2
#define RCON_YES 3

#define MAX_TEMPERATURE 90
#define MIN_TEMPERATURE -40

//all air alarms in area are connected via magic
/area
	var/obj/machinery/air_alarm/master_air_alarm
	var/list/air_vent_names = list()
	var/list/air_scrub_names = list()
	var/list/air_vent_info = list()
	var/list/air_scrub_info = list()

/obj/machinery/air_alarm
	name = "air alarm"
	icon = 'icons/obj/machines/air_alarm.dmi'
	icon_state = "alarm_powered"
	anchored = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 80
	active_power_usage = 1000 //For heating/cooling rooms. 1000 joules equates to about 1 degree every 2 seconds for a single tile of air.
	power_channel = ENVIRON
	light_range = 1
	light_power = 0.5
	light_color = LIGHT_COLOR_EMISSIVE_GREEN
	req_one_access = list(ACCESS_CIVILIAN_ENGINEERING)

	var/alarm_id = null
	var/breach_detection = 1 // Whether to use automatic breach detection or not
	var/frequency = 1439
	//var/skipprocess = 0 //Experimenting
	var/alarm_frequency = 1437
	var/remote_control = 0
	var/rcon_setting = 2
	var/rcon_time = 0
	var/locked = TRUE
	var/aidisabled = FALSE
	var/shorted = FALSE
	var/obj/item/circuitboard/airalarm/electronics = null
	var/mode = AALARM_MODE_SCRUBBING
	var/screen = AALARM_SCREEN_MAIN
	var/area_uid
	var/area/alarm_area
	var/buildstage = 2 //2 is built, 1 is building, 0 is frame.

	var/target_temperature = T20C
	var/regulating_temperature = 0

	var/datum/radio_frequency/radio_connection

	var/list/TLV = list()

	var/danger_level = 0
	var/pressure_dangerlevel = 0
	var/oxygen_dangerlevel = 0
	var/co2_dangerlevel = 0
	var/phoron_dangerlevel = 0
	var/temperature_dangerlevel = 0
	var/other_dangerlevel = 0

	var/apply_danger_level = 1
	var/post_alert = 1

/obj/machinery/alarm/Initialize(mapload, direction, building = FALSE)
	. = ..()

	if(direction)
		setDir(direction)
	switch(dir)
		if(NORTH)
			pixel_y = -32
		if(SOUTH)
			pixel_y = 32
		if(EAST)
			pixel_x = -32
		if(WEST)
			pixel_x = 32

	if(building)
		buildstage = 0
		ENABLE_BITFIELD(machine_stat, PANEL_OPEN)

	wires = new /datum/wires/airalarm(src)

	set_frequency(frequency)

	first_run()


/obj/machinery/alarm/Destroy()
	if(radio_connection)
		SSradio.remove_object(src, frequency)
		radio_connection = null
	QDEL_NULL(wires)
	return ..()


/obj/machinery/alarm/proc/first_run()
	alarm_area = get_area(src)
	area_uid = alarm_area.uid
	if (name == "alarm")
		name = "[alarm_area.name] Air Alarm"

	// breathable air according to human/Life()
	TLV["oxygen"] = list(16, 19, 135, 140) // Partial pressure, kpa
	TLV["carbon dioxide"] = list(-1.0, -1.0, 5, 10) // Partial pressure, kpa
	TLV["phoron"] = list(-1.0, -1.0, 0.2, 0.5) // Partial pressure, kpa
	TLV["other"] = list(-1.0, -1.0, 0.5, 1.0) // Partial pressure, kpa
	TLV["pressure"] = list(ONE_ATMOSPHERE*0.80,ONE_ATMOSPHERE*0.90,ONE_ATMOSPHERE*1.10,ONE_ATMOSPHERE*1.20) /* kpa */
	TLV["temperature"] = list(T0C-26, T0C, T0C+40, T0C+66) // K


/obj/machinery/alarm/proc/handle_heating_cooling()
	return

/obj/machinery/alarm/proc/overall_danger_level(turf/T)
	pressure_dangerlevel = get_danger_level(T.return_pressure(), TLV["pressure"])
	temperature_dangerlevel = get_danger_level(T.return_temperature(), TLV["temperature"])

	return max(
		pressure_dangerlevel,
		temperature_dangerlevel
		)

// Returns whether this air alarm thinks there is a breach, given the sensors that are available to it.
/obj/machinery/alarm/proc/breach_detected()
	var/turf/location = loc

	if(!istype(location))
		return 0

	if(breach_detection	== 0)
		return 0

	var/pressure_levels = TLV["pressure"]

	if (location.return_pressure() <= pressure_levels[1])		//low pressures
		if (!(mode == AALARM_MODE_PANIC || mode == AALARM_MODE_CYCLE))
			return 1

	return 0

/obj/machinery/alarm/proc/get_danger_level(current_value, list/danger_levels)
	if((current_value >= danger_levels[4] && danger_levels[4] > 0) || current_value <= danger_levels[1])
		return 2
	if((current_value >= danger_levels[3] && danger_levels[3] > 0) || current_value <= danger_levels[2])
		return 1
	return 0

/obj/machinery/alarm/update_icon()
	if(buildstage != 2)
		icon_state = "alarm-b1"
		return
	if(CHECK_BITFIELD(machine_stat, PANEL_OPEN))
		icon_state = "alarmx"
		return
	if((machine_stat & (NOPOWER|BROKEN)) || shorted)
		icon_state = "alarmp"
		return

	var/icon_level = danger_level
	if (alarm_area?.atmosalm)
		icon_level = max(icon_level, 1)	//if there's an atmos alarm but everything is okay locally, no need to go past yellow

	icon_state = "alarm[icon_level]"

/obj/machinery/alarm/receive_signal(datum/signal/signal)
	if(machine_stat & (NOPOWER|BROKEN))
		return
	if(!signal)
		return
	var/id_tag = signal.data["tag"]
	if (!id_tag)
		return
	if (signal.data["area"] != area_uid)
		return
	if (signal.data["sigtype"] != "status")
		return

	var/dev_type = signal.data["device"]
	if(!(id_tag in alarm_area.air_scrub_names) && !(id_tag in alarm_area.air_vent_names))
		register_env_machine(id_tag, dev_type)
	if(dev_type == "AScr")
		alarm_area.air_scrub_info[id_tag] = signal.data
	else if(dev_type == "AVP")
		alarm_area.air_vent_info[id_tag] = signal.data

/obj/machinery/alarm/proc/register_env_machine(m_id, device_type)
	var/new_name
	if (device_type=="AVP")
		new_name = "[alarm_area.name] Vent Pump #[length(alarm_area.air_vent_names) + 1]"
		alarm_area.air_vent_names[m_id] = new_name
	else if (device_type=="AScr")
		new_name = "[alarm_area.name] Air Scrubber #[length(alarm_area.air_scrub_names) + 1]"
		alarm_area.air_scrub_names[m_id] = new_name
	else
		return
	spawn (10)
		send_signal(m_id, list("init" = new_name) )

/obj/machinery/alarm/proc/refresh_all()
	for(var/id_tag in alarm_area.air_vent_names)
		var/list/I = alarm_area.air_vent_info[id_tag]
		if (I && I["timestamp"]+AALARM_REPORT_TIMEOUT/2 > world.time)
			continue
		send_signal(id_tag, list("status") )
	for(var/id_tag in alarm_area.air_scrub_names)
		var/list/I = alarm_area.air_scrub_info[id_tag]
		if (I && I["timestamp"]+AALARM_REPORT_TIMEOUT/2 > world.time)
			continue
		send_signal(id_tag, list("status") )

/obj/machinery/alarm/proc/set_frequency(new_frequency)
	SSradio.remove_object(src, frequency)
	frequency = new_frequency
	radio_connection = SSradio.add_object(src, frequency, RADIO_TO_AIRALARM)

/obj/machinery/alarm/proc/send_signal(target, list/command)//sends signal 'command' to 'target'. Returns 0 if no radio connection, 1 otherwise
	if(!radio_connection)
		return 0

	var/datum/signal/signal = new
	signal.transmission_method = 1 //radio signal
	signal.source = src

	signal.data = command
	signal.data["tag"] = target
	signal.data["sigtype"] = "command"

	radio_connection.post_signal(src, signal, RADIO_FROM_AIRALARM)
	testing("Signal [command] Broadcasted to [target]")

	return 1

/obj/machinery/alarm/proc/apply_mode()
	switch(mode)
		if(AALARM_MODE_SCRUBBING)
			for(var/device_id in alarm_area.air_scrub_names)
				send_signal(device_id, list("power"= 1, "co2_scrub"= 1, "scrubbing"= 1, "panic_siphon"= 0) )
			for(var/device_id in alarm_area.air_vent_names)
				send_signal(device_id, list("power"= 1, "checks"= "default", "set_external_pressure"= "default") )

		if(AALARM_MODE_PANIC, AALARM_MODE_CYCLE)
			for(var/device_id in alarm_area.air_scrub_names)
				send_signal(device_id, list("power"= 1, "panic_siphon"= 1) )
			for(var/device_id in alarm_area.air_vent_names)
				send_signal(device_id, list("power"= 0) )

		if(AALARM_MODE_REPLACEMENT)
			for(var/device_id in alarm_area.air_scrub_names)
				send_signal(device_id, list("power"= 1, "panic_siphon"= 1) )
			for(var/device_id in alarm_area.air_vent_names)
				send_signal(device_id, list("power"= 1, "checks"= "default", "set_external_pressure"= "default") )

		if(AALARM_MODE_FILL)
			for(var/device_id in alarm_area.air_scrub_names)
				send_signal(device_id, list("power"= 0) )
			for(var/device_id in alarm_area.air_vent_names)
				send_signal(device_id, list("power"= 1, "checks"= "default", "set_external_pressure"= "default") )

		if(AALARM_MODE_OFF)
			for(var/device_id in alarm_area.air_scrub_names)
				send_signal(device_id, list("power"= 0) )
			for(var/device_id in alarm_area.air_vent_names)
				send_signal(device_id, list("power"= 0) )

/obj/machinery/alarm/proc/apply_danger_level(new_danger_level)
	if (apply_danger_level && alarm_area.atmosalert(new_danger_level))
		post_alert(new_danger_level)

	update_icon()

/obj/machinery/alarm/proc/post_alert(alert_level)
	if(!post_alert)
		return

	var/datum/radio_frequency/frequency = SSradio.return_frequency(alarm_frequency)
	if(!frequency)
		return

	var/datum/signal/alert_signal = new
	alert_signal.source = src
	alert_signal.transmission_method = 1
	alert_signal.data["zone"] = alarm_area.name
	alert_signal.data["type"] = "Atmospheric"

	if(alert_level==2)
		alert_signal.data["alert"] = "severe"
	else if (alert_level==1)
		alert_signal.data["alert"] = "minor"
	else if (alert_level==0)
		alert_signal.data["alert"] = "clear"

	frequency.post_signal(src, alert_signal)


/obj/machinery/alarm/can_interact(mob/user)
	. = ..()
	if(!.)
		return FALSE

	if(buildstage != 2)
		return FALSE

	if(shorted)
		return FALSE

	if(issilicon(user) && aidisabled)
		return FALSE

	return TRUE

	var/area/our_area = get_area(src)
	name = "[our_area.name] Air Alarm"
	update_icon()

/obj/machinery/alarm/interact(mob/user)
/obj/machinery/air_alarm/update_icon()
	. = ..()
	if(machine_stat & (NOPOWER|BROKEN))
		set_light(0)
		return

	set_light(initial(light_range))

/obj/machinery/air_alarm/update_icon_state()
	. = ..()
	if(machine_stat & (NOPOWER|BROKEN))
		icon_state = "alarm_unpowered"
	else
		icon_state = "alarm_powered"

/obj/machinery/air_alarm/update_overlays()
	. = ..()
	if(machine_stat & (NOPOWER|BROKEN))
		return
	. += emissive_appearance(icon, "[icon_state]_emissive", src)

/obj/machinery/air_alarm/crowbar_act(mob/living/user, obj/item/I)
	. = ..()
	balloon_alert_to_viewers("[user] starts trying to pry [src] off the wall..")
	playsound(loc, 'sound/items/crowbar.ogg', 25, 1)
	if(!do_after(user, 5 SECONDS, NONE, src))
		return

	qdel(src)
	new /obj/item/stack/sheet/metal(user.drop_location(), 2)
