#Syd Adams
# Jet Engine electrical system.


battery = nil;
alternator = nil;

last_time = 0.0;
pwr_src = 0.0;

bat_bus_volts = 0.0;
emerg_bus_volts = 0.0;
Lmain_bus_volts = 0.0;
Rmain_bus_volts = 0.0;
AC_bus_amps = 0.0;
ammeter_ave = 0.0;

external_volts = 0.0;
load = 0.0;

init_electrical = func {
    print("Initializing Electrical System");
    battery = BatteryClass.new();
    alternator = AlternatorClass.new();
    setprop("/controls/switches/master-avionics", 1);
    setprop("/controls/electric/battery-switch", 1.0);
    setprop("/controls/electric/external-power", 0);
    setprop("/controls/electric/engine[0]/generator", 1);
    setprop("/controls/electric/engine[1]/generator", 1);
    setprop("/controls/electric/engine[2]/generator", 1);
    setprop("/controls/electric/engine[3]/generator", 1);
    setprop("/controls/electric/engine[4]/bus-tie", 0);
    setprop("/controls/electric/engine[4]/generator", 0);
    setprop("/controls/switches/inverter", 1);
 
    settimer(update_electrical, 0);
}

BatteryClass = {};

BatteryClass.new = func {
    obj = { parents : [BatteryClass],
            ideal_volts : 24.0,
            ideal_amps : 30.0,
            amp_hours : 12.75,
            charge_percent : 1.0,
            charge_amps : 7.0 };
    return obj;
}


BatteryClass.apply_load = func( amps, dt ) {
    amphrs_used = amps * dt / 3600.0;
    percent_used = amphrs_used / me.amp_hours;
    me.charge_percent -= percent_used;
    if ( me.charge_percent < 0.0 ) {
        me.charge_percent = 0.0;
    } elsif ( me.charge_percent > 1.0 ) {
        me.charge_percent = 1.0;
    }
    return me.amp_hours * me.charge_percent;
}


BatteryClass.get_output_volts = func {
    x = 1.0 - me.charge_percent;
    tmp = -(3.0 * x - 1.0);
    factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    return me.ideal_volts * factor;
}

BatteryClass.get_output_amps = func {
    x = 1.0 - me.charge_percent;
    tmp = -(3.0 * x - 1.0);
    factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    return me.ideal_amps * factor;
}

AlternatorClass = {};

AlternatorClass.new = func {
    obj = { parents : [AlternatorClass],
            rpm_source : "/engines/engine[0]/n2",
            rpm_threshold : 40.0,
            ideal_volts : 115.0,
            ideal_amps : 1304.0 };
    setprop( obj.rpm_source, 0.0 );
    return obj;
}

##
# Computes available amps and returns remaining amps after load is applied
#

AlternatorClass.apply_load = func( amps, dt, src ) {
    rpm = getprop(src);
    factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    available_amps = me.ideal_amps * factor;
    return available_amps - amps;
}


AlternatorClass.get_output_volts = func( src ) {
    rpm = getprop(src);
    if (rpm == 0) {
        factor = 0;
    } else {
        factor = math.ln(rpm)/4;
    }
    return me.ideal_volts * factor;
}


AlternatorClass.get_output_amps = func(src ){
    rpm = getprop( src );
    if (rpm == 0) {
        factor = 0;
    } else {
        factor = math.ln(rpm)/4;
    }
    return me.ideal_amps * factor;
}


update_electrical = func {
    time = getprop("/sim/time/elapsed-sec");
    dt = time - last_time;
    last_time = time;
    update_virtual_bus( dt );
    settimer(update_electrical, 0.1);
}

update_virtual_bus = func( dt ) {
    battery_volts = battery.get_output_volts();
    alternator_volts = alternator.get_output_volts("/engines/engine[0]/n2");
    alternator1_volts = alternator.get_output_volts("/engines/engine[1]/n2");
    alternator2_volts = alternator.get_output_volts("/engines/engine[2]/n2");
    alternator3_volts = alternator.get_output_volts("/engines/engine[3]/n2");
    external_volts = 0.0;
    load = 0.0;

    master_bat = getprop("/controls/electric/battery-switch");
    master_alt = getprop("/controls/electric/engine[0]/generator");
    master_alt1 = getprop("/controls/electric/engine[1]/generator");
    master_alt2 = getprop("/controls/electric/engine[2]/generator");
    master_alt3 = getprop("/controls/electric/engine[3]/generator");
    master_apu = getprop("/controls/electric/engine[4]/generator");

    # determine power source
    bat_bus_volts = 0.0;
    Lmain_bus_volts = 0.0;
    Rmain_bus_volts = 0.0;
    power_source = nil;
    apu_volts = 0.0;
    rbus_tie = 1;
    lbus_tie = 1;

#APU generator
    a_volts = alternator.get_output_volts("/engines/engine[4]/n2");
    if (a_volts < 0) {
      a_volts = 0;
    }
    setprop("/engines/engine[4]/volts",a_volts);
    if(getprop("/controls/electric/engine[4]/generator") == 1) {
      apu_volts = a_volts; 
    } else {
      apu_volts = 0;
    };

    if ( master_bat == 1.0 ) {
        bat_bus_volts = battery_volts;
        Lmain_bus_volts = bat_bus_volts;
        Rmain_bus_volts = bat_bus_volts;
        emerg_bus_volts = bat_bus_volts;
        power_source = "battery";
    }else{
      if ( master_bat == 2.0 ) {
        emerg_bus_volts = battery_volts;
        power_source = "battery";
      }
    }

    if ( master_alt and (alternator_volts > bat_bus_volts) ) {
        Lmain_bus_volts = alternator_volts+alternator2_volts;
        bat_bus_volts = alternator_volts;
        power_source = "alternator";
    }
    if ( master_alt1 and (alternator1_volts > bat_bus_volts) ) {
        Rmain_bus_volts = alternator1_volts+alternator3_volts;
        bat_bus_volts = alternator_volts;
        power_source = "alternator";
    }
    if ( external_volts > bat_bus_volts ) {
        bat_bus_volts = external_volts;
        power_source = "external";
    }
    if ( master_apu and (apu_volts > bat_bus_volts) ) {
        if(rbus_tie) {Rmain_bus_volts = apu_volts;};
        if(lbus_tie) {Lmain_bus_volts = apu_volts;};
        bat_bus_volts = apu_volts;
        emerg_bus_volts = apu_volts;
        power_source = "apu";
    }

    # left starter motor
    starter_switch = getprop("/controls/engines/engine[0]/starter");
    starter_volts = 0.0;
    if ( starter_switch ) {
        starter_volts = bat_bus_volts;
    }
    setprop("/systems/electrical/outputs/starter[0]", starter_volts);

    # right starter motor
    starter_switch = getprop("/controls/engines/engine[1]/starter");
    starter_volts = 0.0;
    if ( starter_switch ) {
        starter_volts = bat_bus_volts;
    }
    setprop("/systems/electrical/outputs/starter[1]", starter_volts);
    setprop("/systems/electrical/outputs/apu-bus", emerg_bus_volts);

    load += emergency_bus();
    load += cross_feed_bus();
    load += Left_Main_bus();
    load += Right_Main_bus();
    load += AC_bus();

    ammeter = 0.0;
    if ( bat_bus_volts > 1.0 ) {
        # normal load
        load += 15.0;

        # ammeter gauge
        if ( power_source == "battery" ) {
            ammeter = -load;
        } else {
            ammeter = battery.charge_amps;
        }
    }

    # charge/discharge the battery
    if ( power_source == "battery" ) {
        battery.apply_load( load, dt );
    } elsif ( bat_bus_volts > battery_volts ) {
        battery.apply_load( -battery.charge_amps, dt );
    }

    # filter ammeter needle pos
    ammeter_ave = 0.8 * ammeter_ave + 0.2 * ammeter;

    # outputs
    setprop("/systems/electrical/amps", ammeter_ave);
    setprop("/systems/electrical/volts", bat_bus_volts);
    setprop("/systems/electrical/ac_amps", AC_bus_amps);

    return load;
}

emergency_bus = func() {
    load = 0.0;
    setprop("/systems/electrical/outputs/nav[1]", emerg_bus_volts);
    setprop("/systems/electrical/outputs/com[0]", emerg_bus_volts);

    if ( getprop("/controls/switches/cabin-lights") ) {
        setprop("/systems/electrical/outputs/cabin-lights", emerg_bus_volts);
} else {
        setprop("/systems/electrical/outputs/cabin-lights", 0.0);
    }
    if ( getprop("/controls/switches/pitot-heat" ) ) {
        setprop("/systems/electrical/outputs/pitot-heat", emerg_bus_volts);
    } else {
        setprop("/systems/electrical/outputs/pitot-heat", 0.0);
    }
    return load;
}

cross_feed_bus = func() {
    if (Lmain_bus_volts > Rmain_bus_volts ) {
        Rmain_bus_volts = Lmain_bus_volts;
    } else {
     Lmain_bus_volts = Rmain_bus_volts;
    }
    load = 0.0;
    return load;
}

#Hydraulic pumps driven by N2 ,but relays controlled by 28 volt DC bus
#- so no DC power - no hydraulics

Left_Main_bus = func() {
load = 0.0;
setprop("/controls/hydraulic/system/engine-pump","false");
if(Lmain_bus_volts > 0.2){
setprop("/controls/hydraulic/system/engine-pump","true");
}

setprop("/systems/electrical/outputs/instr-ignition-switch", Lmain_bus_volts);

    if ( getprop("/controls/engines/engine[0]/fuel-pump") ) {
        setprop("/systems/electrical/outputs/fuel-pump", Lmain_bus_volts);
    } else {
        setprop("/systems/electrical/outputs/fuel-pump", 0.0);
    }

    if ( getprop("/controls/switches/landing-light-c") ) {
        setprop("/systems/electrical/outputs/landing-light-c",Lmain_bus_volts);
    } else {
        setprop("/systems/electrical/outputs/landing-light-c", 0.0 );
    }
    if ( getprop("/controls/switches/landing-light-l") ) {
        setprop("/systems/electrical/outputs/landing-light-l",Lmain_bus_volts);
    } else {
        setprop("/systems/electrical/outputs/landing-light-l", 0.0 );
    }
    if ( getprop("/controls/switches/landing-light-r") ) {
        setprop("/systems/electrical/outputs/landing-light-r",Lmain_bus_volts);
    } else {
        setprop("/systems/electrical/outputs/landing-light-r", 0.0 );
    }

    if ( getprop("/controls/switches/beacon" ) ) {
        setprop("/systems/electrical/outputs/beacon", Lmain_bus_volts);
        if ( bat_bus_volts > 1.0 ) { load += 7.5; }
    } else {
        setprop("/systems/electrical/outputs/beacon", 0.0);
    }
    setprop("/systems/electrical/outputs/flaps",Lmain_bus_volts);
    setprop("/systems/electrical/outputs/turn-coordinator", Lmain_bus_volts);

    if ( getprop("/controls/switches/nav-lights" ) ) {
        setprop("/systems/electrical/outputs/nav-lights", Lmain_bus_volts);
        if ( bat_bus_volts > 1.0 ) { load += 7.0; }
    } else {
        setprop("/systems/electrical/outputs/nav-lights", 0.0);
    }
    setprop("/systems/electrical/outputs/instrument-lights", Lmain_bus_volts);
    if ( getprop("/controls/switches/strobe" ) ) {
        setprop("/systems/electrical/outputs/strobe-lights", Lmain_bus_volts);
    } else {
        setprop("/systems/electrical/outputs/strobe-lights", 0.0);
    }
    if ( getprop("/controls/switches/taxi-lights" ) ) {
        setprop("/systems/electrical/outputs/taxi-lights", Lmain_bus_volts);
    } else {
        setprop("/systems/electrical/outputs/taxi-lights", 0.0);
    }
    if ( getprop("/controls/switches/logo-lights" ) ) {
        setprop("/systems/electrical/outputs/logo-lights", Lmain_bus_volts);
    } else {
        setprop("/systems/electrical/outputs/logo-lights", 0.0);
    }	
	    if ( getprop("/controls/switches/map-lights" ) ) {
        setprop("/systems/electrical/outputs/map-lights", Lmain_bus_volts);
    } else {
        setprop("/systems/electrical/outputs/map-lights", 0.0);
    }	
    return load;
}

Right_Main_bus = func() {
setprop("/controls/hydraulic/system[1]/engine-pump","false");
if(Rmain_bus_volts > 0.2){setprop("/controls/hydraulic/system[1]/engine-pump","true")};
    master_av = getprop("/controls/switches/master-avionics");
    load = 0.0;
if(master_av){
    setprop("/systems/electrical/outputs/avionics-fan",Rmain_bus_volts);
    setprop("/systems/electrical/outputs/gps", Rmain_bus_volts);
    setprop("/systems/electrical/outputs/hsi", Rmain_bus_volts);
    setprop("/systems/electrical/outputs/nav[0]", Rmain_bus_volts);
    setprop("/systems/electrical/outputs/dme", Rmain_bus_volts);
    setprop("/systems/electrical/outputs/audio-panel[0]",Rmain_bus_volts);
    setprop("/systems/electrical/outputs/annunciators", Rmain_bus_volts);
    setprop("/systems/electrical/outputs/audio-panel[1]", Rmain_bus_volts);
    setprop("/systems/electrical/outputs/transponder", Rmain_bus_volts);
    setprop("/systems/electrical/outputs/autopilot", Rmain_bus_volts);
    setprop("/systems/electrical/outputs/adf", Rmain_bus_volts);
    setprop("/systems/electrical/outputs/mk-viii",Rmain_bus_volts);
}
    return load;
}

AC_bus = func() {
AC_bus_amps = 0.0;
if(getprop("/controls/switches/inverter") > 0.0){
if(Rmain_bus_volts > 0.2){AC_bus_amps = 225};
if(Lmain_bus_volts > 0.2){AC_bus_amps = 225};
}else{
setprop("/instrumentation/annunciator/master-caution",1.0);
}
    load = 0.0;
    return load;
}


settimer(init_electrical, 0);
