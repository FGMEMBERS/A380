# A380 systems
#
# updated by S.Hamilton from 787 codebase.
#

#
# mode - 1=PWR, 2=ENG Start, 3=TO Data,4=WOW+>80kt, 5=WOW+>120kt, 6=liftoff, 7=<400ft||15sec,
#        8=>1500ft || 120sec, Cruise until LG extend, 9=Gear extend+<800ft, 10=WOW, 11=<80kt, 12=eng off || 5min
#

## mode constants
LNAV_OFF=0;
LNAV_HDG=1;
LNAV_TRACK=2;
LNAV_LOC=3;
LNAV_FMS=4;
LNAV_RWY=5;

VNAV_OFF=0;
VNAV_ALT=1;
VNAV_VS=2;
VNAV_OPCLB=3;
VNAV_FPA=4;
VNAV_OPDES=5;
VNAV_CLB=6;
VNAV_ALTCRZ=7;
VNAV_DES=8;
VNAV_GS=9;
VNAV_SRS=10;

SPD_OFF=0;
SPD_TOGA=1;
SPD_FLEX=2;
SPD_THRCLB=3;
SPD_SPEED=4;
SPD_MACH=5;
SPD_CRZ=6;
SPD_THRIDL=7;

aircraft.livery.init("Aircraft/A380/XML/Liveries");

baro =0.0;
inhg = 0;
kpa= 0;
rev1 = nil;
r1 = nil;
r2 = nil;
v1 = nil;
cl = 0.0;
c2 = 0.0;
hpsi = 0.0;
pph1=0.0;
pph2=0.0;
fuel_density=0.0;
n_offset=0;
nm_calc=0.0;
spdbrake=0.0;
et_base=0.0;
et_hr=0.0;
et_min=0.0;
et_min_start=0.0;
force = 0.0;
test = 0.0;
tgt_offset=0.0;
test_dist=0.0;
test1_dist=0.0;
norm_dist=0.0;
true_heading=0.0;
ai_craft="";
mp_craft="";
apu_running=0;
ecamRequestRef=0;
radarLastCnt=0;
radarLastAirportCnt=0;

NM2MTRS = 1852;
METRE2NM = 0.000539956803;
MSEC2KT=1.946;
FPM2MSEC=0.00508;
KT2MSEC=0.514;
MSEC2KMH=3.6;
KMH2MSEC=0.28;
METRE2FT=3.28083989501;
FT2METRE=0.3048;
CLmax = 2.4;

###srsFlapTarget = [263.0, 220.0, 210.0, 196.0, 182.0];   # copied from Airbus_fms.nas
srsFlapTarget = [263.0, 222.0, 210.0, 196.0, 182.0];   #another copy in system.nas
flapPos       = [0, 0.2424, 0.5151, 0.7878, 1.0];

trace = 0;
version = "1.1.8";

strobe_switch = props.globals.getNode("/controls/switches/strobe", 0);
aircraft.light.new("sim/model/A380/lighting/strobe", [0.05, 1.2], strobe_switch);
beacon_switch = props.globals.getNode("/controls/lighting/beacon", 0);
aircraft.light.new("sim/model/A380/lighting/beacon", [0.05, 1.25], beacon_switch);

ewdChecklist = TextRegion.new(5, 50, "/instrumentation/ewd/checklists");



init_controls = func {
#setprop("/instrumentation/mk-viii/serviceable","true");
##setprop("/instrumentation/mk-viii/configuration-module/category-1","254");
#setprop("/instrumentation/gps/wp/wp/waypoint-type","airport");
#setprop("/instrumentation/gps/wp/wp/ID",getprop("/sim/tower/airport-id"));
#setprop("/instrumentation/gps/serviceable","true");
setprop("/engines/engine[0]/fuel-flow_pph",0.0);
setprop("/engines/engine[1]/fuel-flow_pph",0.0);
setprop("/engines/engine[2]/fuel-flow_pph",0.0);
setprop("/engines/engine[3]/fuel-flow_pph",0.0);
setprop("/engines/engine[4]/fuel-flow_pph",0.0);   # APU
setprop("/engines/engine[4]/off-start-run",0);     # APU state, 0=OFF, 1=START, 2=RUN
setprop("/consumables/fuel/total-fuel-kg",0);
setprop("/instrumentation/efis/baro",0.0);
setprop("/instrumentation/efis/baro-std-mode",0);
setprop("/instrumentation/efis/inhg",0);
setprop("/instrumentation/efis/kpa",0);
setprop("/instrumentation/efis/stab",0);
setprop("/instrumentation/efis/baro-mode",1);
setprop("/instrumentation/efis/fixed-temp",0.0);
setprop("/instrumentation/efis/fixed-stab",0.0);
setprop("/instrumentation/efis/fixed-pitch",0.0);
setprop("/instrumentation/efis/fixed-vs",0.0);
setprop("/instrumentation/efis/alt-mode",0.0);
setprop("/instrumentation/efis_fo/baro",0.0);
setprop("/instrumentation/efis_fo/baro-mode",1);
setprop("/instrumentation/efis_fo/alt-mode",0.0);
setprop("/instrumentation/ecam/flight-mode",1);    # A380 has 12 phases of flight
setprop("/instrumentation/ecam/synoptic","door");  # the page that should be displayed on SD
setprop("/instrumentation/ecam/page","door");      # the current page displayed on SD
setprop("/instrumentation/gear/wow",1);            # to capture WOW events better
setprop("/instrumentation/ecam/egt_limit_arm",0.0);
setprop("/instrumentation/ecam/to-data", 0);
setprop("/instrumentation/mcdu/field-select",1); 
##setprop("/controls/engines/reverser-position",0.0);
setprop("/controls/engines/engine[0]/master",0);
setprop("/controls/engines/engine[1]/master",0);
setprop("/controls/engines/engine[2]/master",0);
setprop("/controls/engines/engine[3]/master",0);
setprop("/controls/engines/engine[0]/thrust-lever",0);
setprop("/controls/engines/engine[1]/thrust-lever",0);
setprop("/controls/engines/engine[2]/thrust-lever",0);
setprop("/controls/engines/engine[3]/thrust-lever",0);
setprop("/environment/turbulence/use-cloud-turbulence","true");
setprop("/sim/current-view/field-of-view",60.0);
setprop("/controls/gear/brake-parking",1.0);
setprop("/controls/engines/ign-start",0);        # the IGN start switch on the OH
setprop("/controls/APU/run",0);                  # what should we do with the APU (engine[4])
setprop("/controls/afs/alt-inc-select",1000);
setprop("/systems/electrical/apu-test",0);
setprop("/instrumentation/annunciator/master-caution",0.0);
setprop("/instrumentation/switches/seat-belt-sign",0.0);
setprop("/systems/hydraulic/pump-psi[0]",0.0);
setprop("/systems/hydraulic/pump-psi[1]",0.0);
var tanks = props.globals.getNode("/consumables/fuel").getChildren("tank");
for(t=0; t< size(tanks);t=t+1) {
  setprop("/consumables/fuel/tank["~t~"]/density-ppg", 6);
  setprop("/consumables/fuel/tank["~t~"]/density-kgpl",(6*0.119826427));
}
fuel_density=getprop("/consumables/fuel/tank[0]/density-ppg");
setprop("/surface-positions/speedbrake-pos-norm",0.0);
setprop("/instrumentation/clock/ET-min",0);
setprop("/instrumentation/clock/ET-hr",0);
##setprop("/instrumentation/mk-viii/speaker/volume",5);
setprop("/instrumentation/wxradar/display-mode",2);   #is 'arc'

#payload - Crew, PAX, Cargo
setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[0]",350);
setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[1]",48420);
setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[2]",28350);
setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[3]",21000);
setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[4]",14328);
setprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[5]",1200);

reset_et();

DOORS.doorsystem.aftCargoDoor.open();
DOORS.doorsystem.forwardCargoDoor.open();
DOORS.doorsystem.paxLeftLow1Door.open();
DOORS.doorsystem.paxLeftUp1Door.open();

settimer(update_systems,0);
setprop("/systems/electrical/apu-test",0);
print("Aircraft systems initialised");
}

reset_et = func {
  et_base = getprop("/sim/time/elapsed-sec");
  et_min_start = et_base;
  et_hr=0.0;
  et_min=0.0;
}

# ESTIMATED TIME CALCULATIONS 

update_radar = func {
  var true_heading = getprop("/orientation/heading-deg");
  var mag_heading  = getprop("orientation/heading-magnetic-deg");
  var myAlt = getprop("/position/altitude-ft");
  var currentPos = geo.Coord.new();
  currentPos.set_latlon(getprop("/position/latitude-deg"), getprop("/position/longitude-deg"), getprop("/position/altitude-ft"));

  ## set NAV[1] (R VOR) to always be our ref navaid
  #
  var refNavFreq = getprop("/instrumentation/gps/ref-navaid/frequency-mhz");
  var currNav1Freq = getprop("/instrumentation/nav[1]/frequencies/selected-mhz");
  if (refNavFreq != nil and refNavFreq != currNav1Freq) {
    setprop("/instrumentation/nav[1]/frequencies/selected-mhz", refNavFreq);
  }


  ## plot AI aircraft on radar
  ##
  ai_craft = props.globals.getNode("/ai/models").getChildren("aircraft");
  var aiPos = 0;
  for(i=0; i<size(ai_craft);i=i+1) {
    var inRange = getprop("/ai/models/aircraft["~i~"]/radar/in-range");
    setprop("instrumentation/radar/ai["~aiPos~"]/valid",0);
    setprop("instrumentation/radar/ai["~aiPos~"]/brg-offset",0);
    setprop("instrumentation/radar/ai["~aiPos~"]/norm-dist",0);
    setprop("instrumentation/radar/ai["~aiPos~"]/diff-alt-fl",0);
    setprop("instrumentation/radar/ai["~aiPos~"]/callsign","");
    if (inRange == 1) {
      tgt_offset=getprop("/ai/models/aircraft[" ~ i ~ "]/radar/bearing-deg");
      if(tgt_offset == nil) {
        tgt_offset = 0.0;
      }
      tgt_offset -= true_heading;
      if (tgt_offset < 0){
        tgt_offset = 360-tgt_offset;
      }
      if (tgt_offset > 360){
        tgt_offset -=360;
      }
      setprop("/instrumentation/radar/ai[" ~ aiPos ~ "]/brg-offset",tgt_offset);
      test_dist=getprop("/instrumentation/radar/range");
      test1_dist = getprop("/ai/models/aircraft[" ~ i ~ "]/radar/range-nm");
      if(test1_dist == nil) {
        test1_dist=0.0;
      }
      norm_dist = (1 / test_dist) * test1_dist;
      setprop("/instrumentation/radar/ai[" ~ aiPos ~ "]/norm-dist", norm_dist);
      var aiAlt = getprop("ai/models/aircraft["~i~"]/position/altitude-ft");
      var diffAlt = (myAlt-aiAlt)/100;
      setprop("/instrumentation/radar/ai["~aiPos~"]/diff-alt-fl", diffAlt);
      setprop("/instrumentation/radar/ai["~aiPos~"]/valid",1);
      setprop("/instrumentation/radar/ai["~aiPos~"]/callsign", getprop("/ai/models/aircraft["~i~"]/callsign"));
      aiPos = aiPos + 1;
    }
  }

  ## plot multiplayer aircraft
  ##
  var radarRange = getprop("/instrumentation/radar/range");
  mp_craft = props.globals.getNode("/ai/models").getChildren("multiplayer");
  var mpPos = 0;
  for(i=0; i<size(mp_craft);i=i+1) {
    var aiHdg = getprop("/ai/models/multiplayer["~i~"]/radar/bearing-deg");
    var valid    = getprop("/ai/models/multiplayer["~i~"]/valid");
    setprop("/instrumentation/radar/mp["~mpPos~"]/valid",valid);
    setprop("/instrumentation/radar/mp["~mpPos~"]/callsign", "");
    setprop("/instrumentation/radar/mp["~mpPos~"]/norm-dist",-1);
    setprop("/instrumentation/radar/mp["~mpPos~"]/brg-offset", 0);
    setprop("/instrumentation/radar/mp["~mpPos~"]/altitude-offset", 0);
    if (aiHdg != nil and valid == 1) {
      var callsign = getprop("/ai/models/multiplayer["~i~"]/callsign");
      var tgt_offset = aiHdg-true_heading;
      if (tgt_offset < 0){
        tgt_offset = 360-tgt_offset;
      }
      if (tgt_offset > 360){
        tgt_offset -=360;
      }
      ###test_dist=getprop("/instrumentation/radar/range");
      test1_dist = getprop("/ai/models/multiplayer[" ~ i ~ "]/radar/range-nm");
      if(test1_dist == nil) {
        test1_dist=0.0;
      }
      norm_dist= (1 / radarRange) * test1_dist;
      if (norm_dist <= 1) {
        var aiAlt = getprop("/ai/models/multiplayer["~i~"]/position/altitude-ft");
        var diffAlt = (aiAlt-myAlt)/100;
        setprop("/instrumentation/radar/mp["~mpPos~"]/altitude-offset", diffAlt);
        setprop("/instrumentation/radar/mp["~mpPos~"]/brg-offset",tgt_offset);
        setprop("/instrumentation/radar/mp["~mpPos~"]/norm-dist", norm_dist);
        setprop("/instrumentation/radar/mp["~mpPos~"]/callsign", callsign);
        mpPos += 1;
      }
    }
  }

  ## plot waypoints
  ##
  var wpCnt = 0;
  var wp_points = props.globals.getNode("/autopilot/route-manager/route").getChildren("wp");
  for(i=1;i <size(wp_points); i=i+1) {
    var tgt_offset = -9999;
    var wpDist = 9999;
    var wpLat = getprop("/autopilot/route-manager/route/wp["~i~"]/latitude-deg");
    var wpLon = getprop("/autopilot/route-manager/route/wp["~i~"]/longitude-deg");
    var wpId  = getprop("/autopilot/route-manager/route/wp["~i~"]/id");
    if (wpLat != nil and wpLon != nil) {
      var wpPos = geo.Coord.new();
      wpPos.set_latlon(wpLat, wpLon, 0);
      var wpCourse = currentPos.course_to(wpPos);
      wpDistMetre   = currentPos.distance_to(wpPos);
      wpDist = wpDistMetre*METRE2NM;
      if (true_heading < wpCourse) {
        tgt_offset = wpCourse-true_heading;
        #print("[radar] "~wpId~" true_head: "~true_heading~", wpCourse: "~wpCourse~", tgt_offset: "~tgt_offset);
      } else {
        tgt_offset = 360-(true_heading-wpCourse);
        #print("[radar] "~wpId~" true_head: "~true_heading~", wpCourse: "~wpCourse~", tgt_offset: "~tgt_offset);
      }
      if (tgt_offset < 0){
        tgt_offset = 360-tgt_offset;
      }
      if (tgt_offset > 360){
        tgt_offset -=360;
      }
    }
    if (wpDist <= radarRange) {
      var base = props.globals.getNode("/instrumentation/radar/wp["~wpCnt~"]",1);
      wpCnt = wpCnt + 1;
      var valid = base.getNode("valid",1);
      valid.setBoolValue(1);
      var brg = base.getNode("brg-offset",1);
      brg.setDoubleValue(tgt_offset);
      var dist = base.getNode("dist-norm", 1);
      dist.setDoubleValue(wpDist/radarRange);
      var id = base.getNode("id",1);
      id.setValue(wpId);
    }
  }
  if (wpCnt < radarLastCnt) {
    for(i=wpCnt;i<=radarLastCnt;i=i+1) {
      var base = props.globals.getNode("/instrumentation/radar/wp["~i~"]",0);
      if (base != nil) {
        var valid = base.getNode("valid",1);
        valid.setBoolValue(0);
        var brg = base.getNode("brg-offset",1);
        brg.setDoubleValue(0);
        var dist = base.getNode("dist-norm", 1);
        dist.setDoubleValue(0);
        var id = base.getNode("id",1);
        id.setValue("");
      }
    }
  }
  radarLastCnt = wpCnt;

  ## plot the GPS ref navaid on radar
  ##
  var navBrg  = getprop("/instrumentation/gps/ref-navaid/bearing-deg");
  var navBrgMag  = getprop("/instrumentation/gps/ref-navaid/mag-bearing-deg");
  var navDist = getprop("/instrumentation/gps/ref-navaid/distance-nm");
  if (navBrg != nil) {
    var tgt_offset = navBrg-mag_heading;    ##+true_heading;
    if (tgt_offset < 0) {
      tgt_offset +=360;
    }
    if (tgt_offset > 360) {
      tgt_offset -=360;
    }
    var navaidId = getprop("/instrumentation/gps/ref-navaid/id");
    if (navDist < radarRange and navaidId != '') {
      setprop("/instrumentation/radar/navaid-valid",1);
      setprop("/instrumentation/radar/navaid-id", navaidId);
    } else {
      setprop("/instrumentation/radar/navaid-valid",0);
      setprop("/instrumentation/radar/navaid-id", "");
    }
    setprop("/instrumentation/radar/navaid-brg",tgt_offset);
    setprop("/instrumentation/radar/navaid-dist-norm",navDist/radarRange);
  }
  
  ## plot nearest airports
  ##
  #setprop("/instrumentation/gps/scratch/type", "airport");
  #setprop("/instrumentation/gps/scratch/max-results", 10);
  #setprop("/instrumentation/gps/command", "nearest");
  #var pos = 0;
  #var resultCnt = getprop("/instrumentation/gps/scratch/result-count");
  #for(var r = 0; r <= resultCnt; r=r+1) {
  #  var ident = getprop("/instrumentation/gps/scratch/ident");
  #  var distNM = getprop("/instrumentation/gps/scratch/distance-nm");
  #  var base = props.globals.getNode("/instrumentation/radar/airports["~pos~"]",1);
  #  var valid = base.getNode("valid",1);
  #  valid.setBoolValue(0);
  #  var brg = base.getNode("brg-offset",1);
  #  brg.setDoubleValue(0.0);
  #  var dist = base.getNode("dist-norm", 1);
  #  dist.setDoubleValue(0.0);
  #  var id = base.getNode("id",1);
  #  id.setValue("");
  #  if (distNM <= radarRange) {
  #    var airportBearing = getprop("/instrumentation/gps/scratch/mag-bearing-deg");
  #    var tgt_offset = airportBearing-true_heading;
  #    if (tgt_offset < 0){
  #      tgt_offset = 360-tgt_offset;
  #    }
  #    if (tgt_offset > 360){
  #      tgt_offset -=360;
  #    }
  #    var norm_dist = (1 / radarRange) * distNM;
  #    valid.setBoolValue(1);
  #    brg.setDoubleValue(tgt_offset);
  #    dist.setDoubleValue(norm_dist);
  #    id.setValue(ident);
  #    pos = pos + 1;
  #  }
  #  setprop("/instrumentation/gps/command", "next");
  #}
  #for(var i = pos; i <= 10; i=i+1) {
  #  var base = props.globals.getNode("/instrumentation/radar/airports["~i~"]",1);
  #  var valid = base.getNode("valid",1);
  #  valid.setBoolValue(0);
  #  var brg = base.getNode("brg-offset",1);
  #  brg.setDoubleValue(0.0);
  #  var dist = base.getNode("dist-norm", 1);
  #  dist.setDoubleValue(0.0);
  #  var id = base.getNode("id",1);
  #  id.setValue("");
  #}

  seatCtrl = getprop("/controls/switches/seat-belt");
  if (seatCtrl == 1) {
    ##curAlt   = getprop("/instrumentation/altimeter/indicated-altitude-ft");
    curAlt   = getprop("/position/altitude-ft");
    seatStat = getprop("/instrumentation/switches/seatbelt-sign");
    if (curAlt > 10000 and seatStat > 0) {
      tracer("SeatCtrl: "~seatCtrl~", curAlt: "~curAlt~", seatStat: "~seatStat);
      setprop("/instrumentation/switches/seatbelt-sign",0);
    }
    if (curAlt < 10001 and seatStat == 0) {
      tracer("SeatCtrl: "~seatCtrl~", curAlt: "~curAlt~", seatStat: "~seatStat);
      setprop("/instrumentation/switches/seatbelt-sign",1);
    }
  }
  var spd    = getprop("/instrumentation/flightdirector/spd");
  var currFlapPos = getprop("/fdm/jsbsim/fcs/flap-cmd-norm");
  if (spd == SPD_THRCLB and currFlapPos > 0) {
    var flapConfig = 0;
    if (currFlapPos == 0.2424) {
      flapConfig = 1;
    }
    if (currFlapPos == 0.5151) {
      flapConfig = 2;
    }
    if (currFlapPos == 0.7878) {
      flapConfig = 3;
    }
    if (currFlapPos == 1.0) {
      flapConfig = 4;
    }
    #tracer("flapConfig: "~flapConfig);
    var iasKt = int(getprop("/instrumentation/airspeed-indicator/indicated-speed-kt"));
    if (iasKt != nil and iasKt != 0) {
      tracer("ias: "~iasKt);
      flapSpd = int(srsFlapTarget[flapConfig])+10;
      #tracer("flapSpd: "~flapSpd);
      if (iasKt > flapSpd) {
        print("WARN: Flap overspeed, retracting flaps!");
        flapConfig -= 1;
        #var newFlapPos = flapPos[flapConfig];
        #print("new flap config: "~flapConfig);
        setprop("/instrumentation/ewd/flap-overspeed",1);
      } else {
        if (getprop("/instrumentation/ewd/flap-overspeed") == 1) {
          setprop("/instrumentation/ewd/flap-overspeed",0);
        }
      }
    }
  }
  var fobLbs = getprop("/fdm/jsbsim/propulsion/total-fuel-lbs");
  var fobKg  = fobLbs*0.45359237;
  setprop("/consumables/fuel/total-fuel-lbs",fobLbs);
  setprop("/consumables/fuel/total-fuel-kg", fobKg);
  var cgX    = getprop("/fdm/jsbsim/inertia/cg-x-in");
  var gwcg   = (1629.615473-cgX);
  setprop("/fdm/jsbsim/inertia/gwcg",gwcg);

   var rho = getprop("/environment/density-slugft3");
   var S   = getprop("/fdm/jsbsim/metrics/Sw-sqft");
   var W   = getprop("/fdm/jsbsim/inertia/weight-lbs");
   var tat = getprop("/fdm/jsbsim/propulsion/tat-c");
   var oat = getprop("/environment/temperature-degc");
   var cs  = 38.967854*math.sqrt(oat+273.15);
   var Vsfts = math.sqrt(W*2/(rho * CLmax * S));
   var Vso = ((Vsfts*60)*FPM2MSEC)*MSEC2KT;
   var Vb  = Vso*2.049;
   var Mb  = convertKtMach(Vb);
   var Mso = convertKtMach(Vso);
   var Mra = (0.89-Mso)/2+Mso;
   setprop("/velocities/Vso",Vso);
   setprop("/velocities/Mso",Mso);
   setprop("/velocities/Vb", Vb);
   setprop("/velocities/Mb", Mb);
   setprop("/velocities/Mra", Mra);

   #   update fuel tank KG weight
   var density = getprop("/consumables/fuel/tank/density-kgpl");
   var tanks = props.globals.getNode("/consumables/fuel").getChildren("tank");
   for(i=0; i<size(tanks);i=i+1) {
     var tank = tanks[i];
     var levelLbs = tank.getChild("level-lbs").getValue();
     tank.getChild("level-kg",0,1).setValue(levelLbs*density);
   }
  settimer(update_radar, 1.0);
}


var convertKtMach = func(kts) {
   var TEMPSL = 518.67;
   var RHOSL = 0.00237689;
   var PRESSSL = 2116.22;
   var saTheta = 1.0;
   var saSigma = 1.0;
   var saDelta = 1.0;

   var h = getprop("/position/altitude-ft");
   var v = kts*1.6878099;

   if ( h > 232939 ){
      saTheta = 0.0;
      saSigma = 0.0;
      saDelta = 0.0;
   }
 
   if ( h<232940 ){
      saTheta = 1.434843 - h/337634;
      saSigma = math.pow( 0.79899-h/606330, 11.20114 );
      saDelta = math.pow( 0.838263-h/577922, 12.20114 );
   }
   if ( h<167323 ){
      saTheta = 0.939268;
      saSigma = 0.00116533 * math.exp( (h-154200)/-25992 );
      saDelta = 0.00109456 * math.exp( (h-154200)/-25992 );
   }
   if ( h<154199 ){
      saTheta = 0.482561 + h/337634;
      saSigma = math.pow( 0.857003+h/190115, -13.20114 );
      saDelta = math.pow( 0.898309+h/181373, -12.20114 );
   }
   if ( h<104987 ){
      saTheta = 0.682457 + h/945374;
      saSigma = math.pow( 0.978261+h/659515, -35.16319 );
      saDelta = math.pow( 0.988626+h/652600, -34.16319 );
   }
   if ( h<65617 ){
      saTheta = 0.751865;
      saSigma = 0.297076 * math.exp( (36089-h)/20806 );
      saDelta = 0.223361 * math.exp( (36089-h)/20806 );
   }
   if ( h<36089 ){
      saTheta = 1.0 - h/145442;
      saSigma = math.pow( 1.0-h/145442, 4.255876 );
      saDelta = math.pow( 1.0-h/145442, 5.255876 );
   }

   var tempVal = TEMPSL * saTheta;
   var rhoVal = RHOSL * saSigma;
   var pVal = PRESSSL * saDelta;
   var viscVal = 0.0000000226968*math.pow( tempVal, 1.5 ) / ((tempVal)+198.72);
   var soundVal = math.sqrt( 1.4*1716.56*(tempVal) );

   var machVal = v/soundVal;
   var qVal = 0.7*pVal*machVal*machVal;
   ##var reynolds = v*rl*rhoVal/viscVal;
   ##var cfturb = 0.455/math.pow((Math.log(reynolds)/Math.log(10)),2.58);
   ##var cflam = 1.328/math.sqrt(reynolds);
   return machVal;
}


# update EWD checklists
update_ewd = func {
  var flt_mode = getprop("/instrumentation/ecam/flight-mode");
  if (getprop("/controls/switches/seat-belt") == 0 and  flt_mode < 10) {
    ewdChecklist.append("SEAT BELTS");
  }
  if (getprop("/controls/switches/seat-belt") == 1 and  flt_mode > 11) {
    ewdChecklist.append("SEAT BELTS");
  }
  if (getprop("/controls/switches/smoking") == 0 and flt_mode < 11) {
    ewdChecklist.append("NO SMOKING");
  }
  if (getprop("/controls/gear/brake-parking") == 1) {
    ewdChecklist.append("PARK BRAKE ON");
  }
  if (getprop("/controls/engines/engine[4]/bleed") == 1) {
    ewdChecklist.append("APU BLEED");
  }
  if (flt_mode > 2 and flt_mode < 5 and getprop("/controls/flight/flaps") < 0.01) {
    ewdChecklist.append("FLAP CONFIG");
  }
  if (flt_mode > 1 and flt_mode < 8 and getprop("/instrumentation/ecam/to-data") != 1) {
    ewdChecklist.append("T.O. DATA");
  }
  if (getprop("/instrumentation/ecam/egt_limit_arm") == 1) {
      ewdChecklist.append("EGT OVERLIMIT");
  }
  if (getprop("/instrumentation/ewd/flap-overspeed") == 1) {
    ewdChecklist.append("FLAP OVERSPEED");
  }
  if (flt_mode == 7 and getprop("/controls/gear/gear-down") == 1) {
    ewdChecklist.append("GEARS");
  }
  if (getprop("/controls/flight/speedbrake") > 0) {
    ewdChecklist.append("SPEEDBRAKE");
  }
  var battVolts = getprop("/system/electrical/suppliers/battery");
  if (battVolts == nil) {
    battVolts = 28;
  }
  if (battVolts < 26) {
    ewdChecklist.append("BATT LOW");
  }
  ewdChecklist.reset();
  settimer(update_ewd, 2);
}


# UPDATE CLOCK 
update_clock = func {
  sec = getprop("/sim/time/elapsed-sec") - et_min_start;
  if(sec >= 60.0){et_min += 1;
    et_min_start = getprop("/sim/time/elapsed-sec");
  }
  if(et_min ==60){et_min = 0; et_hr += 1;}

  etmin = props.globals.getNode("/instrumentation/clock/ET-min");
  if (etmin !=nil) {
    etmin.setIntValue(et_min);
  }
  ethr = props.globals.getNode("/instrumentation/clock/ET-hr");
  if (ethr !=nil) {
    ethr.setIntValue(et_hr);
  }
}


# UPDATE ENGINES
update_engines = func {

  # update engine data and start engines
  for(e=0; e < 4; e=e+1) {
    ign = getprop("/controls/engines/ign-start");
    e_start  = getprop("/controls/engines/engine["~e~"]/starter");
    e_master = getprop("/controls/engines/engine["~e~"]/master");
    e_ign    = getprop("/controls/engines/engine["~e~"]/ignition");
    hpsi     = getprop("/engines/engine["~e~"]/n2");
    if(hpsi == nil){
      hpsi =0.0;
    }
    if(hpsi > 30.0){
      setprop("/systems/hydraulic/pump-psi["~e~"]",60.0);
    }else{
      setprop("/systems/hydraulic/pump-psi["~e~"]",hpsi * 2);
    }
    pph1=getprop("/engines/engine["~e~"]/fuel-flow-pph");
    if(pph1 == nil){
      pph1 = getprop("/fdm/jsbsim/propulsion/engine["~e~"]/fuel-flow-rate-pps")*60;
    }
    ##  this goes from gallons/sec to lbs/hour (and kg/h)
    var fuel_density_metric = getprop("/consumables/fuel/tank[0]/density-kgpl");
    if (fuel_density_metric == nil) {
      fuel_density_metric = 0;
    }
    setprop("engines/engine["~e~"]/fuel-flow_pph",pph1*fuel_density);
    setprop("/engines/engine["~e~"]/fuel-flow_kgph",(pph1*fuel_density_metric));
    if (ign == 1 and e_start == 1 and e_master == 1) {
      tracer("Engine "~e~" in start phase, N2: "~hpsi);
      if (hpsi > 20 and hpsi < 22 and getprop("/controls/engines/engine["~e~"]/cutoff") == 1) {
        setprop("/controls/engines/engine["~e~"]/cutoff",0);
      }
      if (hpsi >= 26 and hpsi < 50) {
        tracer("engine igniter");
        setprop("/controls/engines/engine["~e~"]/ignition",1);
        #setprop("/controls/engines/engine["~e~"]/starter",0);
        setprop("/controls/pneumatic/engine["~e~"]/bleed",1);
      }
    }
    if (hpsi >= 50 and ign == 1 and e_ign == 1) {
         tracer("shut engine igniter");
         setprop("/controls/engines/engine["~e~"]/ignition",0);
         setprop("/controls/engines/engine["~e~"]/generator",1);
         settimer(check_all_start, 10);
    }
    var eng_egtF = getprop("/engines/engine["~e~"]/egt_degf");
    if (eng_egtF == nil) {
      eng_egtF = getprop("/engines/engine["~e~"]/egt-degf");
    }
    eng_egtC = (5/9)*(eng_egtF-32);
    setprop("/engines/engine["~e~"]/egt_degc",eng_egtC);
    limit = getprop("/instrumentation/ecam/egt_limit_arm");
    if (eng_egtC > 920 and limit != 1) {
      settimer(check_egt_overlimit, 20);
      setprop("/instrumentation/ecam/egt_limit_arm",1);
    }
  }

  # update APU status and start/stop APU  
  apu_state = getprop("/engines/engine[4]/off-start-run");
  if (apu_state == 1) {
    start_apu();
  }
  if (apu_state == 2 and getprop("/engines/engine[4]/cutoff") == 1 and getprop("/engines/engine[4]/n2") < 50) {
    setprop("/engines/engine[4]/off-start-run",0);
    settimer(update_sd, 10);
  }
  var apuN2 = getprop("/engines/engine[4]/n2");
  if (apuN2 == nil) {
    apuN2 = 0.0;
  }
  if (apuN2 > 50) {
    setprop("/controls/engines/engine[4]/bleed",1);
  } else {
    setprop("/controls/engines/engine[4]/bleed",0);
  }
  var apu_egtF = getprop("/engines/engine[4]/egt_degf");
  if (apu_egtF == nil) {
    apu_egtF = getprop("/engines/engine[4]/egt-degf");
  }
  apu_egtC = (5/9)*(apu_egtF-32);
  setprop("/engines/engine[4]/egt_degc",apu_egtC);

  # update status of WOW so we only get 1 event in the listener
  wow = getprop("/instrumentation/gear/wow");
  wow1 = getprop("/gear/gear[1]/wow");
  wow2 = getprop("/gear/gear[2]/wow");
  if ((wow1 != wow) or (wow2 != wow)) {
    if (wow1 != wow) {
      setprop("/instrumentation/gear/wow",wow1);
    } else {
      setprop("/instrumentation/gear/wow",wow2);
    }
  }

  # other Flight Mode checks
  flt_mode = getprop("/instrumentation/ecam/flight-mode");
  grnd_spd = getprop("/velocities/groundspeed-kt");
  if (flt_mode > 1 and flt_mode < 4 and grnd_spd >= 80) {
    flt_mode = 4;
    setprop("/instrumentation/ecam/flight-mode",flt_mode);
  }
  if (flt_mode == 4 and grnd_spd > 130) {
    flt_mode = 5;
    setprop("/instrumentation/ecam/flight-mode",flt_mode);
  }
  if (flt_mode == 10 and grnd_spd < 80) {
    flt_mode = 11;
    setprop("/instrumentation/ecam/flight-mode",flt_mode);
  }
  alt = getprop("/instrumentation/altimeter/indicated-altitude-ft");
  if (alt > 400 and flt_mode == 6) {
    flt_mode = 7;
    setprop("/instrumentation/ecam/flight-mode",flt_mode);
  }
  if (alt > 1500 and flt_mode == 7) {
    flt_mode = 8;
    setprop("/instrumentation/ecam/flight-mode",flt_mode);
  }
  gear_pos = getprop("/gear/gear[0]/position-norm");
  fpm      = getprop("/instrumentation/vertical-speed-indicator/indicated-speed-fpm");
  #if (flt_mode > 4 and flt_mode < 10 and flt_mode != 8) {
  #tracer("flt_mode: "~flt_mode~", alt: "~alt~", gear: "~gear_pos~", fpm: "~fpm); 
  #}
  if (flt_mode == 8 and (alt < 800 and gear_pos == 1)) {
    flt_mode = 9;
    setprop("/instrumentation/ecam/flight-mode",flt_mode);
  }

  settimer(update_engines, 0.60);  
}

check_acquire_mode = func {
   var acquireMode = getprop("/instrumentation/flightdirector/alt-acquire-mode");
   if (acquireMode == 1) {
     var alt = getprop("/position/altitude-ft");
     var vsSpeed = getprop("/velocities/vertical-speed-fps");
     var selectAlt = getprop("/instrumentation/afs/target-altitude-ft");
     if (vsSpeed > 0) {
       if (alt >= (selectAlt-300)) {
         setprop("/instrumentation/flightdirector/vnav", VNAV_ALT);
         setprop("/instrumentation/flightdirector/alt-acquire-mode",0);
         var aFMS = AirbusFMS.new();
         setprop("/instrumentation/flightdirector/vnav-arm", aFMS.evaluateManagedVNAV());
       }
     }
     if (vsSpeed < 0) {
       if (alt <= (selectAlt+300)) {
         setprop("/instrumentation/flightdirector/vnav", VNAV_ALT);
         setprop("/instrumentation/flightdirector/alt-acquire-mode",0);
         var aFMS = AirbusFMS.new();
         setprop("/instrumentation/flightdirector/vnav-arm", aFMS.evaluateManagedVNAV());
       }
     }
   }
}


##
#
check_egt_overlimit = func {
   limit = getprop("/instrumentation/ecam/egt_overlimit");
   for(e=0; e < 4; e=e+1) {
     egt_degC = getprop("/engines/engine["~e~"]/egt_degc");
     if (egt_degC > 920 and limit != 1) {
       limit = 1;
       # reduce thrust according to SPD and VNAV...
       print("EGT Overlimit");
     }
     setprop("/instrumentation/ecam/egt_limit_arm",0);
     setprop("/instrumentation/ecam/egt_overlimit",limit);
   }
}

trim_fuel_tanks = func {
  # keep the four feed tanks full
  for(t=0; t!= 3; t=t+1) {
    ## tank = getprop("/consumables/fuel/tank["~t~"]/level-lbs");
    t1 = getprop("/controls/engines/engine["~t~"]/feed_tank");
    if (t1 == nil or t1 < 0) {
      t1 = t;
      setprop("/controls/engines/engine["~t~"]/feed_tank",t1);
    }
    tank = getprop("/consumables/fuel/tank["~t1~"]/level-lbs");
    # reserve 1000kg in feed for pump

    if (tank < 1000) { 
      for(factor = 1; factor != 3;factor=factor+1) {
        t2 = 2+(factor*2);
        if (getprop("/consumables/fuel/tank["~t2~"]/level-lbs") > 10) {
          print("switch engine "~t~" to tank "~t2~".");
          setprop("/controls/engines/engine["~t~"]/feed_tank",t2);
        }
      }
    }
  }
}


check_all_start = func {
  tt = 0;
  for(e=0; e < 4; e=e+1) {
    e_run  = getprop("/engines/engine["~e~"]/running");
    ##e_master = getprop("/controls/engines/engine["~e~"]/master");
    if (e_run == 1) {
      tt = tt+1;
    }
  }
  ##print("there are: "~tt~" engines running");
  if (tt == 4) {
    print("Complete engine start OK");
    setprop("/instrumentation/ecam/page","wheel");
  }
}


start_apu = func {
  n2 = getprop("/engines/engine[4]/n2");
  tracer("APU n2: "~n2);
  if (n2 > 25 and n2 < 27 and getprop("/controls/engines/engine[4]/cutoff") == 1) {
    tracer("start APU fuel flow");
    setprop("/controls/engines/engine[4]/cutoff",0);
  }
  if (n2 > 25 and n2 < 50) {
    tracer("start APU ignition");
    setprop("/controls/engines/engine[4]/ignition",1);
    #setprop("/controls/engines/engine[4]/starter",0);
    #setprop("/controls/engines/engine[4]/bleed",1);
  }
  if (n2 > 50) {
    tracer("stop APU ignition");
    setprop("/controls/engines/engine[4]/ignition",0);
    ##setprop("/controls/engines/engine[4]/starter",0);
    setprop("/engines/engine[4]/off-start-run",2);
    setprop("/controls/electric/engine[4]/generator", 1);
    setprop("/controls/electric/engine[4]/bus-tie", 1);
    setprop("/controls/electric/APU-generator", 1);
    settimer(update_sd, 10);
  }

}


# TOGGLE REVERSER
togglereverser = func {
  r1 = "/controls/engines/engine[1]"; 
  r2 = "/controls/engines/engine[2]"; 
  rv1 = "/surface-positions/reverser-pos-norm"; 

  val = getprop(rv1);
  if (val == 0 or val == nil) {
    interpolate(rv1, 1.0, 1.4);  
    setprop(r1,"reverser","true");
    setprop(r2,"reverser", "true");
  } else {
    if (val == 1.0){
      interpolate(rv1, 0.0, 1.4);  
      setprop(r1,"reverser",0);
      setprop(r2,"reverser",0);
    }
  }
}

# UPDATE SYSTEMS
update_systems = func {
  update_clock();
  ##update_radar();
  #update_fueltanks();
  check_acquire_mode();

  baro = getprop("/instrumentation/altimeter/setting-inhg");
  setprop("/instrumentation/efis/inhg",baro);
  setprop("/instrumentation/efis/kpa",int(baro * 33.8637526));
  setprop("/instrumentation/efis/stab",getprop("/controls/flight/elevator-trim") * 15);

  if(getprop("/instrumentation/efis/baro-mode")== 0){
    setprop("/instrumentation/efis/baro", baro );
  }else{
    setprop("/instrumentation/efis/baro",baro * 33.8637526);
  }
  if(getprop("/instrumentation/efis_fo/baro-mode")== 0){
    setprop("/instrumentation/efis_fo/baro", baro );
  }else{
    setprop("/instrumentation/efis_fo/baro",baro * 33.8637526);
  }

  test = getprop("/environment/temperature-degc");
  if(test < 0.00) { 
    test = -1 * test;
  }
  setprop("/instrumentation/efis/fixed-temp",test);

  test = getprop("/controls/flight/elevator-trim");
  if(test < 0.00){
    test = -1 * test;
  }
  setprop("/instrumentation/efis/fixed-stab",test);

  test = getprop("/orientation/pitch-deg");
  if(test < 0.00){
    test = -1 * test;
  }
  setprop("/instrumentation/efis/fixed-pitch",test);

  test = getprop("/autopilot/settings/vertical-speed-fpm");
  if(test == nil ){
    test=0.0;
  }
  if(test < 0.00){
    test = -1 * test;
  }
  setprop("/instrumentation/efis/fixed-vs",test);


  force = getprop("/accelerations/pilot-g");
  if(force == nil) {
    force = 1.0;
  }
  eyepoint = (getprop("sim/view/config/y-offset-m") - (force * 0.01));
  if(getprop("/sim/current-view/view-number") < 1){
    setprop("/sim/current-view/y-offset-m",eyepoint);
  }

  if(getprop("/controls/flight/speedbrake")== 1){
    interpolate("surface-positions/speedbrake-pos-norm", 1.0, 5.0);
    interpolate("controls/flight/spoilers", 1.0, 5.0);
  }
  if(getprop("/controls/flight/speedbrake")== 0){
    interpolate("surface-positions/speedbrake-pos-norm", 0.0, 5.0);
    interpolate("controls/flight/spoilers", 0.0, 5.0);
  }

  var jsbsimGrossWgt = getprop("/fdm/jsbsim/inertia/weight-lbs");
  var grossWgtKg    = jsbsimGrossWgt*0.45359237;
  setprop("/fdm/jsbsim/inertia/weight-kg",grossWgtKg);

  settimer(update_systems,0.5);
}


update_metric = func {
  var posAltitudeFt = getprop("/position/altitude-ft");
  var altIndicatedAltFt = getprop("/instrumentation/altimeter/indicated-altitude-ft");
  setprop("/position/altitude-m",posAltitudeFt*FT2METRE);
  setprop("/instrumentation/altimeter/indicated-altitude-m",altIndicatedAltFt*FT2METRE);
  settimer(update_metric, 1.0);
}


increment_flight_mode1 = func {
  flt_mode = getprop("/instrumentation/ecam/flight-mode");
  alt = getprop("/instrumentation/altimeter/indicated-altitude-ft");
  if (flt_mode == 6 and  alt < 400) {
    flt_mode = flt_mode+1;
    setprop("/instrumentation/ecam/flight-mode",flt_mode);
  }
}

increment_flight_mode2 = func {
  flt_mode = getprop("/instrumentation/ecam/flight-mode");
  alt = getprop("/instrumentation/altimeter/indicated-altitude-ft");
  if (flt_mode == 7 and alt < 1500) {
    flt_mode = flt_mode+1;
    setprop("/instrumentation/ecam/flight-mode",flt_mode);
  }
}

# revert the system page back to synoptic 30sec after manual change
revert_sd = func {
  if (ecamRequestRef == 1) {
    setprop("/instrumentation/ecam/page",getprop("/instrumentation/ecam/synoptic"));
  }
  if (ecamRequestRef > 0) {
    ecamRequestRef=ecamRequestRef-1;
  }
}

update_sd = func {
  flt_mode = getprop("/instrumentation/ecam/flight-mode");
  setprop("/instrumentation/ecam/flight-mode", flt_mode);
}

var stepSpeedbrake = func(step) {
    if(props.globals.getNode("/sim/spoilers") != nil) {
        stepProps("/controls/flight/speedbrake", "/sim/spoilers", step);
        return;
    }
    # Hard-coded spoilers movement in 4 equal steps:
    var val = 0.25 * step + getprop("/controls/flight/speedbrake");
    setprop("/controls/flight/speedbrake", val > 1 ? 1 : val < 0 ? 0 : val);
}


## FDM init
setlistener("/sim/signals/fdm-initialized", func {
 pph1=getprop("/engines/engine[0]/fuel-flow-gph");
 if(pph1 == nil){pph1 = 0.0};
 pph2=getprop("/engines/engine[1]/fuel-flow-gph");
 if(pph2 == nil){pph2 = 0.0};
  pph1=getprop("/engines/engine[2]/fuel-flow-gph");
 if(pph1 == nil){pph1 = 0.0};
 pph2=getprop("/engines/engine[3]/fuel-flow-gph");
 if(pph2 == nil){pph2 = 0.0};
 setprop("engines/engine[0]/fuel-flow_pph",pph1* fuel_density);
 setprop("engines/engine[1]/fuel-flow_pph",pph2* fuel_density);
 setprop("engines/engine[2]/fuel-flow_pph",pph1* fuel_density);
 setprop("engines/engine[3]/fuel-flow_pph",pph2* fuel_density);
#flight mode 
     setprop("/instrumentation/ecam/flight-mode",1);
     setprop("/instrumentation/ecam/synoptic","door");
     setprop("/instrumentation/ecam/page","door");
 update_engines();
 update_metric();
 settimer(update_radar,5);
 update_ewd();
});


# wait for master avionics to be on to start radar
#setlistener("/controls/switches/master-avionics", func(n) {
#  #print("Aircraft awake now! - "~n.getValue());
#  #update_radar();
#});

# 

# monitor eng 0 switch for ignition
setlistener("/controls/engines/engine[0]/master", func(n) {
  master = n.getValue();
  ign = getprop("/controls/engines/ign-start");
  apu = getprop("/engines/engine[4]/off-start-run");  # 2 for run.
  if (master == 1 and ign == 1 and apu == 2) {
    tracer("start and ignite engine 0");
    if (getprop("/instrumentation/ecam/flight-mode") == 1) {
      #print("[ECAM] set SD page: engine");
      setprop("/instrumentation/ecam/flight-mode",2);
    }
    setprop("/controls/engines/engine[0]/starter",1);
    setprop("/controls/pneumatic/engine[0]/bleed",1);
  }
  if (master == 0 and ign == 0) {
    tracer("cutoff engine 0");
    setprop("/controls/engines/engine[0]/cutoff",1);
  }
});

# monitor eng 1 switch for ignition
setlistener("/controls/engines/engine[1]/master", func(n) {
  master = n.getValue();
  ign = getprop("/controls/engines/ign-start");
  apu = getprop("/engines/engine[4]/off-start-run");  # 2 for run.
  if (master == 1 and ign == 1 and apu == 2) {
    tracer("start and ignite engine 1");
    if (getprop("/instrumentation/ecam/flight-mode") == 1) {
      #print("[ECAM] set SD page: engine");
      setprop("/instrumentation/ecam/flight-mode",2);
    }
    setprop("/controls/engines/engine[1]/starter","true");
    setprop("/controls/pneumatic/engine[1]/bleed",1);
  }
  if (master == 0 and ign == 0) {
    setprop("/controls/engines/engine[1]/cutoff",1);
  }
});

# monitor eng 2 switch for ignition
setlistener("/controls/engines/engine[2]/master", func(n) {
  master = n.getValue();
  ign = getprop("/controls/engines/ign-start");
  apu = getprop("/engines/engine[4]/off-start-run");  # 2 for run.
  if (master == 1 and ign == 1 and apu == 2) {
    tracer("start and ignite engine 2");
    if (getprop("/instrumentation/ecam/flight-mode") == 1) {
      #print("[ECAM] set SD page: engine");
      setprop("/instrumentation/ecam/flight-mode",2);
    }
    setprop("/controls/engines/engine[2]/starter","true");
    setprop("/controls/pneumatic/engine[2]/bleed",1);
  }
  if (master == 0 and ign == 0) {
    setprop("/controls/engines/engine[2]/cutoff",1);
  }
});

# monitor eng 3 switch for ignition
setlistener("/controls/engines/engine[3]/master", func(n) {
  master = n.getValue();
  ign = getprop("/controls/engines/ign-start");
  apu = getprop("/engines/engine[4]/off-start-run");  # 2 for run.
  flt_mode = getprop("/instrumentation/ecam/flight-mode");
  if (master == 1 and ign == 1 and apu == 2) {
    tracer("start and ignite engine 3");
    if (getprop("/instrumentation/ecam/flight-mode") == 1) {
      #print("[ECAM] set SD page: engine");
      setprop("/instrumentation/ecam/flight-mode",2);
    }
    setprop("/controls/engines/engine[3]/starter","true");
    setprop("/controls/pneumatic/engine[3]/bleed",1);
  }
  if (master == 0 and ign == 0) {
    setprop("/controls/engines/engine[3]/cutoff",1);
    if (flt_mode == 11) {
      flt_mode = 12;
      setprop("/instrumentation/ecam/flight-mode",flt_mode);
      
    }
  }
});


# monitor main gear wow
setlistener("/instrumentation/gear/wow", func(n) {
  touch = n.getValue();
  flt_mode = getprop("/instrumentation/ecam/flight-mode");
  if (flt_mode == nil) {
    flt_mode = 0;
  }
  ##
  autospd = getprop("/controls/flight/autospeedbrakes-armed");
  if (touch == 1) {
    if (flt_mode > 7 and flt_mode < 10) {
      flt_mode = 10;
      setprop("/instrumentation/ecam/flight-mode",flt_mode);
      tracer("Gear wow: "~touch~", flt_mode: "~flt_mode~", autospd: "~autospd);
      if (autospd == "true" or autospd == 1) {
        print("Enable auto-speedbrakes");
        setprop("/controls/flight/speedbrake",1);
        
      }
    }
    spd_eng = getprop("/controls/flight/speedbrake");
    if (flt_mode > 10 and spd_eng == 1) {
      setprop("/controls/flight/speedbrake",0);
      print("retract speedbrakes..");
    }
  }
  if (touch == 0) {
    if (flt_mode == 5) {
      flt_mode = 6;
      setprop("/instrumentation/ecam/flight-mode",flt_mode);
      settimer(increment_flight_mode1, 15);
      settimer(increment_flight_mode2, 120);
    }
  }
});

#  SD page will revert to synoptic page 30sec after manual change
setlistener("/instrumentation/ecam/page", func(n) {
  page = n.getValue();
  if (page != getprop("/instrumentation/ecam/synoptic")) {
    ecamRequestRef=ecamRequestRef+1;
    settimer(revert_sd, 30);
  }

});


##
#  flight mode for ECAM
#

## manage the System Display according to flt phase here.
setlistener("/instrumentation/ecam/flight-mode", func(n) {
  flt_mode = n.getValue();
  tracer("Flight phase: "~flt_mode);
  if (flt_mode == 1) {
    setprop("/instrumentation/ecam/synoptic","door");
  }
  if (flt_mode == 2) {
    setprop("/instrumentation/ecam/synoptic","engine");
  }
  if (flt_mode == 3) {
    setprop("/instrumentation/ecam/synoptic","engine");
  }
  if (flt_mode == 4) {
    setprop("/instrumentation/ecam/synoptic","engine");
  }
  if (flt_mode == 5) {
    setprop("/instrumentation/ecam/synoptic","engine");
  }
  if (flt_mode == 6) {
    setprop("/instrumentation/ecam/synoptic","engine");
  }
  # if in mode 7 - reduce TOGA to FLEX
  if (flt_mode == 7) { 
    setprop("/instrumentation/ecam/synoptic","engine");
  }
  if (flt_mode == 8) {
    setprop("/instrumentation/ecam/synoptic","cruise");
  }
  if (flt_mode == 9) { 
    setprop("/instrumentation/ecam/synoptic","wheel");
  }
  if (flt_mode == 10) {
    setprop("/instrumentation/ecam/synoptic","wheel");
  }
  if (flt_mode == 11) {
    setprop("/instrumentation/ecam/synoptic","wheel");
  }
  if (flt_mode == 12) {
    setprop("/instrumentation/ecam/synoptic","door");    
  }
  setprop("/instrumentation/ecam/page",getprop("/instrumentation/ecam/synoptic"));
});


# monitor APU start
setlistener("/controls/APU/run",func(n) {
  apu_req = n.getValue();
  flt_mode = getprop("/instrumentation/ecam/flight-mode");
  apu_run = getprop("/engines/engine[4]/off-start-run");
  tracer("APU run state: "~apu_run~" apu req state: "~apu_req);
  if (apu_req == 1 and apu_run == 0) {
    tracer("APU start/run:"~apu_run~", flt_mode:"~flt_mode);
    if(flt_mode == 1 or flt_mode > 10) {
      setprop("/instrumentation/ecam/synoptic","apu");
    }
    setprop("/instrumentation/ecam/page","apu");
    setprop("/engines/engine[4]/off-start-run",1);
    #setprop("/controls/engines/engine[4]/cutoff",1);
    ##setprop("/controls/engines/engine[4]/bleed",1);
    setprop("/controls/engines/engine[4]/starter", 1);
  }
  if (apu_req == 0 and apu_run == 2) {
    setprop("/controls/engines/engine[4]/cutoff",1);
    setprop("/controls/engines/engine[4]/ignition",0);
    setprop("/controls/engines/engine[4]/starter",0);
    setprop("/controls/engines/engine[4]/bleed",0);
    setprop("/instrumentation/ecam/synoptic","apu");
    setprop("/instrumentation/ecam/page","apu");
  }
    
});


setlistener("/controls/switches/seat-belt", func(n) {
  seat = n.getValue();
  ## seat belt switch to off
  if (seat == 0) {
    setprop("/instrumentation/switches/seatbelt-sign",0);
  }
  ## seat belt switch set to auto
  if (seat == 1) {
    if (getprop("/instrumentation/altimeter/indicated-altitude-ft") <10000 ) {
      setprop("/instrumentation/switches/seatbelt-sign",1);
    }
  }
  ## seat belt switch set to on
  if (seat == 2) {
    setprop("/instrumentation/switches/seatbelt-sign",1);
  }
});

# monitor efis Std baro mode
setlistener("/instrumentation/efis/baro-std-mode", func(n) {
  var stdMode = n.getValue();
  if (stdMode == 1) {
    setprop("/instrumentation/altimeter/setting-inhg",29.92);
  }
});

settimer(init_controls, 0);
