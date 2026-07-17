// channel numbers for power
// These are indexes in a list, and indexes for "dynamic" and static channels should be kept contiguous
#define AREA_USAGE_EQUIP 1
#define AREA_USAGE_LIGHT 2
#define AREA_USAGE_ENVIRON 3
#define AREA_USAGE_STATIC_EQUIP 4
#define AREA_USAGE_STATIC_LIGHT 5
#define AREA_USAGE_STATIC_ENVIRON 6
#define AREA_USAGE_APC_CHARGE 7
#define AREA_USAGE_LEN AREA_USAGE_APC_CHARGE // largest idx

/// Index of the first dynamic usage channel
#define AREA_USAGE_DYNAMIC_START AREA_USAGE_EQUIP
/// Index of the last dynamic usage channel
#define AREA_USAGE_DYNAMIC_END AREA_USAGE_ENVIRON

/// Index of the first static usage channel
#define AREA_USAGE_STATIC_START AREA_USAGE_STATIC_EQUIP
/// Index of the last static usage channel
#define AREA_USAGE_STATIC_END AREA_USAGE_STATIC_ENVIRON

#define DYNAMIC_TO_STATIC_CHANNEL(dyn_channel) (dyn_channel + (AREA_USAGE_STATIC_START - AREA_USAGE_DYNAMIC_START))
#define STATIC_TO_DYNAMIC_CHANNEL(static_channel) (static_channel - (AREA_USAGE_STATIC_START - AREA_USAGE_DYNAMIC_START))


//Power use
/// dont use power
#define NO_POWER_USE 0
/// use idle_power_usage i.e. the power needed just to keep the machine on
#define IDLE_POWER_USE 1
/// use active_power_usage i.e. the power the machine consumes to perform a specific task
#define ACTIVE_POWER_USE 2

///Base global power consumption for idling machines
#define BASE_MACHINE_IDLE_CONSUMPTION (100 WATTS)
///Base global power consumption for active machines. The unit is ambiguous (joules or watts) depending on the use case for dynamic users.
#define BASE_MACHINE_ACTIVE_CONSUMPTION (BASE_MACHINE_IDLE_CONSUMPTION * 10)

/// Bitflags for a machine's preferences on when it should start processing. For use with machinery's `processing_flags` var.
#define START_PROCESSING_ON_INIT (1<<0) /// Indicates the machine will automatically start processing right after its `Initialize()` is ran.
#define START_PROCESSING_MANUALLY (1<<1) /// Machines with this flag will not start processing when it's spawned. Use this if you want to manually control when a machine starts processing.


//bitflags for door switches.
#define OPEN (1<<0)
#define IDSCAN (1<<1)
#define BOLTS (1<<2)
#define SHOCK (1<<3)
#define SAFE (1<<4)

//used in design to specify which machine can build it
#define IMPRINTER (1<<0)	//For circuits. Uses glass/chemicals.
#define PROTOLATHE (1<<1)	//New stuff. Uses glass/metal/chemicals
#define CRAFTLATHE (1<<2)	//Uses fuck if I know. For use eventually.
#define MECHFAB (1<<3) 	//Remember, objects utilising this flag should have construction_time and construction_cost vars.
#define BIOGENERATOR (1<<4) 	//Uses biomass
#define LIMBGROWER (1<<5) 	//Uses synthetic flesh
#define SMELTER (1<<6) 	//uses various minerals
#define NANITE_COMPILER (1<<7) //Prints nanite disks


#define FIREDOOR_OPEN 1
#define FIREDOOR_CLOSED 2


#define DOOR_NOT_FORCED 0
#define DOOR_FORCED_NORMAL 1


//Cables directions and helping
#define CABLE_NODE 0


#define UP_OR_DOWN 16

#define MACHINE_NOT_ELECTRIFIED 0
#define MACHINE_ELECTRIFIED_PERMANENT -1
#define MACHINE_DEFAULT_ELECTRIFY_TIME 30


#define TURRET_SAFETY (1<<0)
#define TURRET_LOCKED (1<<1)
#define TURRET_ON (1<<2)
#define TURRET_HAS_CAMERA (1<<3)
#define TURRET_ALERTS (1<<4)
#define TURRET_RADIAL (1<<5)
#define TURRET_IMMOBILE (1<<6)
#define TURRET_INACCURATE (1<<7)

#define SQUAD_LOCK (1<<0)
#define JOB_LOCK (1<<1)


#define HOLDING (1<<0)
#define CONNECTED (1<<1)
#define EMPTY (1<<2)
#define LOW (1<<3)
#define MEDIUM (1<<4)
#define FULL (1<<5)
#define DANGER (1<<6)


#define AALARM_MODE_SCRUBBING 1
#define AALARM_MODE_REPLACEMENT 2 //like scrubbing, but faster.
#define AALARM_MODE_PANIC 3 //constantly sucks all air
#define AALARM_MODE_CYCLE 4 //sucks off all air, then refill and switches to scrubbing
#define AALARM_MODE_FILL 5 //emergency fill
#define AALARM_MODE_OFF 6 //Shuts it all down.

