#############################################################################
#
# Abstract:
#  Airbus Flight Management System for A380. Builds Flight Plans and manages
#  the waypoints in the autopilot. Provides the interface between the MCDU panel
#  and the Route-Manager plan.
#
# Author: Scott Hamilton  - Sept 2009.
# Version: V1.0.3
#
#   Copyright (C) 2009 Scott Hamilton
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Modification History:
# When		Who     Version		What
# 01-SEP-2009	S.H.	V1.0		Initial version
# 13-DEC-2009	S.H.	V1.0.3		Calculate descent where more than one WP has unknown altitude
# 28-APR-2010	S.H.	V1.0.6		Roughly calculate Vr and V2 based on Vso
#
# 



currentField = "";
currentFieldPos = 0;
inputValue = "";
trace = 0;         ## Set to 0 to turn off all tracing messages
depDB = nil;
arvDB = nil;
version = "V1.0.15";

routeClearArm = 0;



#### CONSTANTS ####
#trigonometric values for glideslope calculations
FD_TAN3DEG = 0.052407779283;
FD_SIN3DEG = 0.052335956243;
FD_COS3DEG = 0.998629534755;

FD_TAN15DEG = 0.2679491924311227332;
FD_SIN30DEG = 0.5;
FD_TAN2_5DEG = 0.04366094290851206068;
FD_SIN5DEG = 0.08715574274765816587;

PI = 3.141592653589793116;
PI2 = 1.570796326794896558;
TWOPI=6.283185307179586232;
DEG2RAD = 0.01745329251994329509;
RAD2DEG = 57.29577951308232311;
RAD2NM  = 3437.7475;
MSEC2KT=1.946;
FPM2MSEC=0.00508;
KT2MSEC=0.514;
MSEC2KMH=3.6;
KMH2MSEC=0.28;
NM2MTRS = 1852;
METRE2NM = 0.000539956803;
lur_koeff1 = 5.661872017348443498;   #=g*tan(30deg)
CLmax = 2.3;



CODE_ERR=3;
CODE_WARN=2;
CODE_INFO=1;




#############################################################################
#  output a debug message to stdout or file.
#############################################################################
tracer = func(msg) {
  var timeStr = getprop("/sim/time/gmt-string");
  var curAltStr = getprop("/position/altitude-ft");
  var curVnav   = getprop("/instrumentation/flightdirector/vnav");
  var curLnav   = getprop("/instrumentation/flightdirector/lnav");
  var curSpd    = getprop("/instrumentation/flightdirector/spd");
  var athrStr   = getprop("/instrumentation/flightdirector/at-on");
  var ap1Str     = getprop("/instrumentation/flightdirector/ap");
  var altHold = getprop("/autopilot/settings/target-altitude-ft");
  var vsHold  = getprop("/autopilot/settings/vertical-speed-fpm");
  var spdHold = getprop("/autopilot/settings/target-speed-kt");
  if (curVnav == nil) curVnav = "0";
  if (curLnav == nil) curLnav = "0";
  if (curSpd  == nil) curSpd  = "0";
  if (trace > 0) {
    print("[FMS] time: "~timeStr~" - "~msg);
    if (trace > 1) {
      print("[FMS0] vnav: "~vnavStr[curVnav]~", lnav: "~lnavStr[curLnav]~", spd: "~spdStr[curSpd]);
    }
  }
}


init_mcdu = func() {
  print("Init FMS "~version);
    setprop("/instrumentation/mcdu[0]/page","active.init");
    setprop("/instrumentation/mcdu[1]/page","active.init");
    setprop("/instrumentation/afs/current-fpln","primary");

    setprop("/instrumentation/mcdu[0]/sid-arm",0);
    setprop("/instrumentation/mcdu[0]/star-arm",0);
    setprop("/instrumentation/mcdu[1]/sid-arm",0);
    setprop("/instrumentation/mcdu[1]/star-arm",0);
    setprop("/instrumentation/mcdu[0]/opt-scroll",0);
    setprop("/instrumentation/mcdu[1]/opt-scroll",0);
    setprop("/instrumentation/mcdu[0]/opt-error-display",0);
    setprop("/instrumentation/mcdu[1]/opt-error-display",0);
  
    setprop("/instrumentation/afs/routeClearArm",0);

    var depapt = airportinfo();
    setprop("/instrumentation/afs/FROM",depapt["id"]);
    #setprop("/instrumentation/afs/depart-runway","");

}


selectField = func(field) {
   currentField = field;
   tracer("set current field to: "~currentField);
   var attr = "/instrumentation/afs/"~field;
   inputValue = getprop(attr);
   if (inputValue == nil) {
     inputValue = "";
   }
}


keyPress = func(key) {
  if (num(inputValue) != nil) {
    ##print("convert inputValue to String");
    inputValue = sprintf("%0.0f",inputValue);
    #if (inputValue == "0") {
    #  inputValue = "";
    #}
  }
  if (key == "DEL") {
    var len = (size(inputValue))-1;
    if (len < 0) {
      len = 0;
    }
    inputValue = substr(inputValue,0,len);
  } else {
   inputValue = inputValue~key;
  }
  if (num(inputValue) != nil) {
    inputValue = num(inputValue);
  }  
  var attr = "/instrumentation/afs/"~currentField;
  tracer("set field: "~attr~", with value: "~inputValue);
  setprop(attr, inputValue);

  if (currentField == "CRZ_FL") {
    var cruiseFt = num(inputValue);
    if (cruiseFt == nil) {
      #print("CRZ_FL: inputValue: "~inputValue);
      cruiseFt = int(inputValue)
    }
    if (cruiseFt != nil) {
      cruiseFt = int(cruiseFt*100);
      setprop("/instrumentation/afs/thrust-cruise-alt",cruiseFt);
    }
  }
}

################
## general menu action function.
changePage = func(unit,page) {
  tracer("**** Start changePage("~page~")");
  var crzFl = getprop("/instrumentation/afs/CRZ_FL");
  setprop("/instrumentation/mcdu["~unit~"]/opt-error-display",0);

  for(r =0; r != 8; r=r+1) {
      var optAttr = sprintf("/instrumentation/mcdu[%i]/opt%02i",unit,r+1);
      var col1Attr = sprintf("/instrumentation/mcdu[%i]/col01-opt%02i",unit,r+1);
      var col2Attr = sprintf("/instrumentation/mcdu[%i]/col02-opt%02i",unit,r+1);
     
      setprop(optAttr,"");
      setprop(col1Attr,"");
      setprop(col2Attr,"");
  }

  ### active.departure.dep
  if (page == "active.departure.dep") {
    var rwyScroll = getprop("/instrumentation/mcdu["~unit~"]/opt-scroll");
    var depApt = airportinfo(getprop("/instrumentation/afs/FROM"));

    var arvApt = call(func airportinfo(getprop("/instrumentation/afs/TO")),nil, var err = []);
    if (size(err)) {
      arvApt = nil;
    }
    if (depApt != nil and arvApt != nil) {    
      if (trace > 0) {
        debug.dump(arvApt);
      }
      if (getprop("/instrumentation/afs/routeClearArm") == 0) {
        setprop("/autopilot/route-manager/cruise/flight-level",crzFl);
        setprop("/autopilot/route-manager/cruise/altitude-ft",crzFl*100);
        setprop("/autopilot/route-manager/active",0);
	tracer("/autopilot/route-manager/input,@clear");
        setprop("/autopilot/route-manager/input","@clear");
        
        setprop("/instrumentation/afs/routeClearArm",1);
        setprop("/instrumentation/afs/thrust-cruise-alt",crzFl*100);
      }

    var depCourse = getprop("/instrumentation/afs/dep-course");
    depCourse = calcOrthHeadingDeg(depApt.lat,depApt.lon,arvApt.lat,arvApt.lon);
    setprop("/instrumentation/afs/dep-course",depCourse);
    var runWays = depApt["runways"];
    tracer("runways len: "~size(runWays));
    setprop("/instrumentation/mcdu["~unit~"]/opt-size",size(runWays));
    if (rwyScroll > int(size(runWays)/8)) {
      rwyScroll = 0;
    }
    var ks = keys(runWays);
    var max = size(ks);
    if (max > (rwyScroll*8)+8) {
      max = (rwyScroll*8)+8;
    }
    var pos = 0;
    for(r = (rwyScroll*8); r != max; r=r+1) {
      var key = ks[r];
      var run = runWays[key];
      if (run["length"] > 2000) {
        pos = pos+1;
        var rwyAttr = sprintf("/instrumentation/mcdu[%i]/opt%02i",unit,pos);
        var rwyLenAttr = sprintf("/instrumentation/mcdu[%i]/col01-opt%02i",unit,pos);
        var rwyHdgAttr = sprintf("/instrumentation/mcdu[%i]/col02-opt%02i",unit,pos);
        tracer("[MCDU] set attr: "~rwyAttr~", run val: "~key);
        setprop(rwyAttr,key);
        var lenStr = sprintf("%im",run["length"]);
        var crsStr = sprintf("%03i", run["heading"]);
        setprop(rwyLenAttr, lenStr);
        setprop(rwyHdgAttr, crsStr);
      }
    }
    setprop("/instrumentation/mcdu["~unit~"]/star-arm",0);
    setprop("/instrumentation/mcdu["~unit~"]/sid-arm",0);
    var rwy = getprop("/instrumentation/afs/dep-rwy");
    if (rwy != nil) {
      if (size(rwy) > 0) {
        setprop("/instrumentation/mcdu["~unit~"]/sid-arm",1);
      }
    }
    } else {
      print("[MCDU] failed to find either DEPART or ARRIVAL Airport in FMS data");
      print("  check the README file on how to add FMS database files");
      setprop("/instrumentation/mcdu["~unit~"]/opt-error","ARPT NOT IN DB");
      setprop("/instrumentation/mcdu["~unit~"]/opt-error-display",CODE_WARN);
    }
  }

  ### active.departure.arv
  if (page == "active.departure.arv") {
    var rwyScroll = getprop("/instrumentation/mcdu["~unit~"]/opt-scroll");
    var depApt = airportinfo(getprop("/instrumentation/afs/FROM"));
    var arvApt = airportinfo(getprop("/instrumentation/afs/TO"));
    if (trace > 0) {
      debug.dump(arvApt);
    }
    var depCourse = getprop("/instrumentation/afs/dep-course");
    if (depCourse == nil) {
      depCourse = calcOrthHeadingDeg(depApt.lat,depApt.lon,arvApt.lat,arvApt.lon);
      setprop("/instrumentation/afs/dep-course",depCourse);
    }
    ## var routeRoot = props.globals.getNode("autopilot/route-manager/route",1); 
    

    var runWays = arvApt["runways"];
    tracer("runways len: "~size(runWays));
    setprop("/instrumentation/mcdu["~unit~"]/opt-size",size(runWays));
    var ks = keys(runWays);
    var max = size(ks);
    if (max > (rwyScroll*8)+8) {
      max = (rwyScroll*8)+8;
    }
    var pos = 0;
    for(r = (rwyScroll*8); r != max; r=r+1) {
      var key = ks[r];
      var run = runWays[key];
      if (run["length"] > 2000) {
        pos = pos+1;
        var rwyAttr = sprintf("/instrumentation/mcdu[%i]/opt%02i",unit,pos);
        var rwyLenAttr = sprintf("/instrumentation/mcdu[%i]/col01-opt%02i",unit,pos);
        var rwyHdgAttr = sprintf("/instrumentation/mcdu[%i]/col02-opt%02i",unit,pos);
        tracer("[MCDU] set attr: "~rwyAttr~", run val: "~key);
        setprop(rwyAttr,key);
        var lenStr = sprintf("%im",run["length"]);
        var crsStr = sprintf("%03i", run["heading"]);
        setprop(rwyLenAttr, lenStr);
        setprop(rwyHdgAttr, crsStr);
      }
    }
    setprop("/instrumentation/mcdu["~unit~"]/sid-arm",0);
    setprop("/instrumentation/mcdu["~unit~"]/star-arm",0);
    var rwy = getprop("/instrumentation/afs/arv-rwy");
    if (rwy != nil) {
      if (size(rwy) > 0) {
        setprop("/instrumentation/mcdu["~unit~"]/star-arm",1);
      }
    }
  }

  #### active.departure.sid
  if (page == "active.departure.sid") {
    if (depDB == nil) {
      depDB = fmsDB.new(getprop("/instrumentation/afs/FROM"));
    }
    ####   setup the array of SID options to be displayed
    if (depDB != nil) {
      var sidList = depDB.getSIDList(getprop("/instrumentation/afs/dep-rwy"));
      var rwyScroll = getprop("/instrumentation/mcdu["~unit~"]/opt-scroll");
      var max = size(sidList);
      setprop("/instrumentation/mcdu["~unit~"]/opt-size",size(sidList));
      if (max > (rwyScroll*8)+8) {
        max = (rwyScroll*8)+8;
      }
      var pos = 0;
      for(var p = (rwyScroll*8); p != size(sidList); p=p+1) {
        var sidAttr = sprintf("/instrumentation/mcdu[%i]/opt%02i",unit,pos+1);
        var sidNumWptAttr = sprintf("/instrumentation/mcdu[%i]/col01-opt%02i",unit,pos+1);
        var sidTransAttr = sprintf("/instrumentation/mcdu[%i]/col02-opt%02i",unit,pos+1);
        var proc = sidList[p];
        tracer("[MCDU] found SID procedure: "~proc.wp_name~", with "~size(proc.wpts)~" waypoints and "~size(proc.transitions)~" transitions");
        setprop(sidAttr,proc.wp_name);
        var wptLen = sprintf("%2i",size(proc.wpts));
        setprop(sidNumWptAttr, wptLen);
        if (proc.transitions != nil and size(proc.transitions) > 0) {
          var transStr = "";
          # make a comma seperated string of transition wp for display
          foreach(var tr; proc.transitions) {
            if (tr.trans_type == "sid") {
              transStr = transStr~", "~tr.trans_name;
            }
          }
          setprop(sidTransAttr, transStr);
        } else {
          setprop(sidTransAttr, "");
        }
        pos = pos+1;
      }
      setprop("/autopilot/route-manager/departure/airport",getprop("/instrumentation/afs/FROM"));
      setprop("/autopilot/route-manager/departure/runway",getprop("/instrumentation/afs/dep-rwy"));
    } else {
      print("[MCDU] failed to find Depart Airport in FMS data");
      print("  check the README file on how to add FMS database files");
      setprop("/instrumentation/mcdu["~unit~"]/opt-error","ARPT NOT IN DB");
      setprop("/instrumentation/mcdu["~unit~"]/opt-error-display",CODE_WARN);
    }
  }

  ### active.departure.star
  if (page == "active.departure.star") {
    if (arvDB == nil) { 
      arvDB = fmsDB.new(getprop("/instrumentation/afs/TO"));
    }
    if (arvDB != nil) {
      var rwyScroll = getprop("/instrumentation/mcdu["~unit~"]/opt-scroll");
      starList = arvDB.getSTARList(getprop("/instrumentation/afs/arv-rwy"));
      var max = size(starList);
      setprop("/instrumentation/mcdu["~unit~"]/opt-size",size(starList));
      if (max > (rwyScroll*8)+8) {
        max = (rwyScroll*8)+8;
      }
      var pos = 0;
      for(var p = (rwyScroll*8); p != size(starList); p=p+1) {
        var starAttr = sprintf("/instrumentation/mcdu[%i]/opt%02i",unit,pos+1);
        var starTransAttr = sprintf("/instrumentation/mcdu[%i]/col02-opt%02i",unit,pos+1);
        var starNumWptAttr = sprintf("/instrumentation/mcdu[%i]/col01-opt%02i",unit,pos+1);
        var proc = starList[p];
        tracer("[MCDU] found STAR procedure: "~proc.wp_name~", with "~size(proc.wpts)~" waypoints and "~size(proc.transitions)~" transitions");
        setprop(starAttr,proc.wp_name);
	var wptLen = sprintf("%2i",size(proc.wpts));
        setprop(starNumWptAttr, wptLen);
        if (proc.transitions != nil and size(proc.transitions) > 0) {
          var transStr = "";
          foreach(var tr; proc.transitions) {
            transStr = transStr~", "~tr.trans_name;
          }
          setprop(starTransAttr, transStr);
        } else {
          setprop(starTransAttr, "");
        }
        pos = pos+1;
      }
      setprop("/autopilot/route-manager/destination/airport",getprop("/instrumentation/afs/TO"));
      setprop("/autopilot/route-manager/destination/runway",getprop("/instrumentation/afs/arv-rwy"));
      #setprop("/autopilot/route-manager/active",1);
      #setprop("/autopilot/route-manager/cruise/flight-level",crzFl);
      #setprop("/autopilot/route-manager/cruise/altitude-ft",(crzFl*100));
      
    } else {
      print("[MCDU] failed to find Arrival Airport in FMS data");
      print("  check the README file on how to add FMS database files");
      setprop("/instrumentation/mcdu["~unit~"]/opt-error","ARPT NOT IN DB");
      setprop("/instrumentation/mcdu["~unit~"]/opt-error-display", CODE_WARN);
    }
  }
  
  ### active.departure.sid.trans
  if (page == "active.departure.sid.trans") {
     if (depDB == nil) {
      depDB = fmsDB.new(getprop("/instrumentation/afs/FROM"));
    }
    if (depDB != nil) {
      var sidVal = getprop("/instrumentation/afs/sid");
      var sid = depDB.getSid(sidVal);
      setprop("/instrumentation/mcdu["~unit~"]/opt-size",size(sid.transitions));
      var pos = 1;
      foreach(var proc; sid.transitions) {
        if (proc.trans_type == "sid") {
          var sidAttr = sprintf("/instrumentation/mcdu[%i]/opt%02i",unit,pos);
          var sidNumWptAttr = sprintf("/instrumentation/mcdu[%i]/col01-opt%02i",unit,pos);
          var sidTransAttr = sprintf("/instrumentation/mcdu[%i]/col02-opt%02i",unit,pos);
          setprop(sidAttr, proc.trans_name);
          setprop(sidNumWptAttr, size(proc.trans_wpts));
          pos = pos+1;
        }
      }
    } else {
      print("[MCDU] failed to find Depart Airport in FMS data");
      print("  check the README file on how to add FMS database files");
      setprop("/instrumentation/mcdu["~unit~"]/opt-error","ARPT NOT IN DB");
      setprop("/instrumentation/mcdu["~unit~"]/opt-error-display", CODE_WARN);
    }
  }

  if (page == "active.to_perf") {
     #V = √( 2 W g / ρ S Clmax )
     #
     #where:
     #  V = Stall Speed M/s
     #  ρ (rho) = air density KG/M^3 (about 1.25 kg/m3)
     #  g = 9.81 m s^-2
     #  S = wing area M^2
     #  Cl_max = Max Coefficient of Lift
     #  W = weight KG

     tracer(" active.to-perf calc Vso, Vr, V2");
     var Vso = getprop("/velocities/Vso");
     var Vr  = (Vso*1.4);
     var V2  = (Vso*1.5)+10;
     setprop("/instrumentation/afs/Vr", Vr);
     setprop("/instrumentation/afs/V2", V2);
     tracer("  Vso: "~Vso~", Vr: "~Vr~", V2: "~V2);

     var fltMode    = getprop("/instrumentation/ecam/flight-mode");
     if (fltMode == 2) {
       setprop("/instrumentation/ecam/flight-mode", fltMode+1);
       setprop("/instrumentation/ecam/to-data", 1);
     }
  }
  tracer("**** End changePage("~page~")");
  setprop("/instrumentation/mcdu["~unit~"]/page",page);
}



#####################
##  Dispatch option value to either selectRwyAction or selectSidAction

dispatchAction = func(val, unit) {
   tracer("**** Start dispatchAction("~val~")");
   var page = getprop("/instrumentation/mcdu["~unit~"]/page");
   if (page == "active.departure.dep" or page == "active.departure.arv") {
     selectRwyAction(val, unit);
   }
   if (page == "active.departure.sid" or page == "active.departure.star") {
     selectSidAction(val, unit);
   }
   if (page == "active.departure.sid.trans") {
     selectSidTransAction(val, unit);
   }
   tracer("**** End dispatchAction("~val~")");
}




###################
## From the departure page, set the depart and arrival runways 
selectRwyAction = func(rwy, unit) {
  var direct = "dep";
  if (getprop("/instrumentation/mcdu["~unit~"]/page") == "active.departure.arv") {
    direct = "arv";
    setprop("/instrumentation/mcdu[0]/sid-arm",0);
    setprop("/instrumentation/mcdu[0]/star-arm",1);
  } else {
    setprop("/instrumentation/mcdu[0]/sid-arm",1);
    setprop("/instrumentation/mcdu[0]/star-arm",0);
  }
  var rwyAttr = sprintf("/instrumentation/afs/%s-rwy",direct);
  var rwyVal = getprop("/instrumentation/mcdu["~unit~"]/"~rwy);
  setprop(rwyAttr,rwyVal);
  if (direct == "dep") {
    var apt = airportinfo(getprop("/instrumentation/afs/FROM"));
    var mhz = getILS(apt,rwyVal);
    if (mhz != nil) {
    tracer("depart ILS: "~mhz);
    ##setprop("/instrumentation/nav[0]/selected-mhz",mhz);
    setprop("/instrumentation/nav[0]/frequencies/selected-mhz",mhz);
    ##setprop("/instrumentation/nav[0]/frequencies/selected-mhz-fmt",mhz);
    }
  } else {
    var apt = airportinfo(getprop("/instrumentation/afs/TO"));
    var mhz = getILS(apt,rwyVal);
    if (mhz != nil) {
    tracer("arrive ILS: "~mhz);
    ##setprop("/instrumentation/nav[0]/standby-mhz",mhz);
    setprop("/instrumentation/nav[0]/frequencies/standby-mhz",mhz);
    ##setprop("/instrumentation/nav[0]/frequencies/standby-mhz-fmt",mhz);
    }
  }
  tracer("[MCDU] set: "~rwyAttr~", runway: "~rwyVal);
}


######################
## From Sid or Star page, set tmp-fpln sid/star opt.
selectSidAction = func(opt, unit) {
  var direct = "sid";
  
  if (getprop("/instrumentation/mcdu["~unit~"]/page") == "active.departure.star") {
    direct = "star";
  } 
  var nextPage = "active.init";
  var sidAttr = sprintf("/instrumentation/afs/%s",direct);
  var sidVal = getprop("/instrumentation/mcdu["~unit~"]/"~opt);
  setprop(sidAttr,sidVal);
  tracer("[MCDU] set: "~sidAttr~", with: "~sidVal);
  if (direct == "sid") {
    var sid = depDB.getSid(sidVal);
    var pos = 0;
    var crzFl = getprop("/instrumentation/afs/CRZ_FL");
    tracer("Got back sid: "~sid.wp_name~", with: "~size(sid.wpts)~" wp");
    for(var w=0; w != size(sid.wpts);w=w+1) {
      var wpIns = "";
      var wp = sid.wpts[w];
      tracer(" add sid wp: "~wp.wp_name);
      if (w == size(sid.wpts)-1) {
        wp.alt_csrt = (crzFl*100);
      }
      var wpLen = getprop("/autopilot/route-manager/route/num");
      if (wp.alt_csrt != nil and wp.alt_csrt > 0) {
        wpIns = sprintf("%i:%s@%i",wpLen,wp.wp_name,int(wp.alt_csrt));
      } else {
        wpIns = sprintf("%i:%s@-1",wpLen,wp.wp_name);
      }
      tracer("[FMS] Insert route: "~wpIns~", of type: "~wp.wp_type);
      if (wp.wp_type == "Normal") {
	tracer("/autopilot/route-manager/input, @insert "~wpIns);
        setprop("/autopilot/route-manager/input", "@insert "~wpIns);
      }
    }
    var transArm = 0;
    if (sid.transitions != nil and size(sid.transitions) > 0) {
      foreach(var tr; sid.transitions) {
        if (tr.trans_type == "sid") {
          transArm = 1;
        }
      }
    }
    if (transArm == 1) {
      nextPage = "active.departure.sid.trans";
    } else {
      nextPage = "active.departure.arv";
    }

    ####  calculate T/C
    var wpLen = getprop("/autopilot/route-manager/route/num");
    
    for(var v=0; v != wpLen; v=v+1) {
      var wpId = getprop("/autopilot/route-manager/route/wp["~v~"]/id");
      var wpAlt = getprop("/autopilot/route-manager/route/wp["~v~"]/altitude-ft");

    }
  }
  if (direct == "star") {
    var star = arvDB.getStar(sidVal);
    var wpLen = getprop("/autopilot/route-manager/route/num");
    var crzFl = getprop("/instrumentation/afs/CRZ_FL");
    ###   calculate the T/D
    var firstWp = star.wpts[0];
    var arvApt = airportinfo(getprop("/instrumentation/afs/TO"));
    var crzFt  = getprop("/instrumentation/afs/thrust-cruise-alt");
    ## work around bug 189 for the meanwhile..
    var wptIdx = wpLen-1;
    var badAlt = getprop("/autopilot/route-manager/route/wp["~wptIdx~"]/altitude-ft");
    var appId  = getprop("/autopilot/route-manager/route/wp["~wptIdx~"]/id");
    tracer("update elevation for id: "~appId~", route/wp["~wptIdx~"]/altitude-ft = "~badAlt);
    if (badAlt < -9999 and substr(appId,0,4) == arvApt.id) {
      var appLat = getprop("/autopilot/route-manager/route/wp["~wptIdx~"]/latitude-deg");
      var appLon = getprop("/autopilot/route-manager/route/wp["~wptIdx~"]/longitude-deg");
      tracer("add new airport WPT");
      insertAbsWP(appId,wptIdx,appLat,appLon,int(arvApt.elevation));
      setprop("/autopilot/route-manager/input", "@delete "~(wpLen));
    }
    tracer(">>>>>>>>>>>>>> current thrust-cruise-alt: "~crzFt);
    var prevCoord = geo.Coord.new();
    prevCoord.set_latlon(getprop("/autopilot/route-manager/route/wp["~(wpLen-2)~"]/latitude-deg"), getprop("/autopilot/route-manager/route/wp["~(wpLen-2)~"]/longitude-deg"), crzFt);
    ### calc Pythagorean Theorem of each phase
    var totalDist = 0;
    var sidebNM = calcDistAtAngle(2, 10000);
    tracer(" 2deg dist: "~sidebNM~" nm");
    totalDist = totalDist+sidebNM;
    var difAlt = (crzFt-arvApt.elevation)-10000;
    sidebNM = calcDistAtAngle(3, difAlt);
    tracer(" 3deg dist: "~sidebNM~" nm for: "~difAlt~"ft");
    totalDist = totalDist+sidebNM;
    var remainDist = gcd2(arvApt.lat, arvApt.lon, firstWp.wp_lat, firstWp.wp_lon, "nm");
    tracer("T/D is at: "~totalDist~"nm from arrival apt, first wp of STAR is: "~remainDist~"nm from airport");
    if (totalDist > remainDist) {

      var difDist = totalDist-remainDist;
      var firstWpCoord = geo.Coord.new();
      firstWpCoord.set_latlon(firstWp.wp_lat, firstWp.wp_lon, crzFt);
      #var NextStarWp = star.wpts[1];
      #if (size(star.wpts) == 1) {
      #  
      #}
      
      #var NextStarWpCoord = geo.Coord.new();
      #NextStarWpCoord.set_latlon(NextStarWp.wp_lat, NextStarWp.wp_lon, crzFt);
      #var starHdg = NextStarWpCoord.course_to(firstWpCoord);
      var prevHdg = firstWpCoord.course_to(prevCoord); 
      #var difHdg = starHdg-prevHdg;
      #tracer("[FMS] diff heading between enroute "~prevHdg~" and star "~starHdg~" is: "~difHdg);
      tracer("[FMS] enroute hdg: "~prevHdg);
      var hdg = prevHdg;
      #if (difHdg > 10 or difHdg < -10) {
      #  tracer("[FMS] heading difference too great, reducing...");
      #  difHdg = difHdg/2;
      #  hdg = starHdg+difHdg;
      #  if (hdg > 360) {
      #    hdg = hdg-360;
      #  }
      #  if (hdg < 0) {
      #    hdg = 360+hdg;
      #  }
      #  tracer("[FMS] difHdg: "~difHdg~", new T/D heading: "~hdg);
      #}
      ###var hdg = calcOrthHeadingDeg(firstWp.wp_lat, firstWp.wp_lon, prevRtLat, prevRtLon);
      tracer("[FMS] find point at course: "~hdg~", dist: "~difDist~"nm from: "~firstWp.wp_name);
    
      #var tdCoord = calcDistancePointDeg(hdg, difDist, firstWp.wp_lat, firstWp.wp_lon);
      var tdCoord = firstWpCoord.apply_course_distance(hdg, difDist*NM2MTRS);
      var tdLat = tdCoord.lat();
      var tdLon = tdCoord.lon();
      tracer("T/D lat: "~tdLat~", lon: "~tdLon);
      var tdIns = sprintf("@insert %i:%s,%s@%i",wpLen-1,tdLon,tdLat,int(crzFt));
      tracer("insert T/D: "~tdIns);
      ##setprop("/autopilot/route-manager/input",tdIns);
      insertAbsWP("T/D",wpLen-1,tdLat,tdLon,int(crzFt));
      wpLen = getprop("/autopilot/route-manager/route/num");
      tracer("wpLen now: "~wpLen);
      #var wpStr = "/autopilot/route-manager/route/wp["~(wpLen-2)~"]";
      #print("[FMS] using wpStr: "~wpStr);
      #setprop(wpStr~"/id","TD");
      #setprop(wpStr~"/name","TD");
    }

    foreach(var w; star.wpts) {
      var wpIns = "";
      wpLen = getprop("/autopilot/route-manager/route/num");
      if (w.alt_csrt > 0) {
        wpIns = sprintf("%i:%s@%i",wpLen-1,w.wp_name,int(w.alt_csrt));
      } else {
        wpIns = sprintf("%i:%s@-1",wpLen-1,w.wp_name);
      }
      tracer("Insert star route: "~wpIns~", of type: "~w.wp_type);
      if (w.wp_type == "Normal") {
	tracer("/autopilot/route-manager/input, @insert "~wpIns);
        setprop("/autopilot/route-manager/input", "@insert "~wpIns);
      }
    }
    var transArm = 0;
    if (star.transitions != nil and size(star.transitions) > 0) {
      foreach(var tr; star.transitions) {
        if (tr.trans_type == "star") {
          transArm = 1;
        }
      }
    }
    if (transArm == 1) {
      nextPage = "active.departure.arv";
    } else {
      nextPage = "active.departure.arv";
    }
    var appr = arvDB.getApproachList(getprop("/instrumentation/afs/arv-rwy"));
    if (size(appr) == 1) {
      var iap = appr[0];
      tracer("star approach avail: "~iap.wp_name~", with "~size(iap.wpts)~" wps");
      foreach(var trans; iap.transitions) {
        if (trans.trans_name == sidVal) {
          tracer("transition to approach has "~size(trans.trans_wpts)~" wps");
          foreach(var twp; trans.trans_wpts) {
            if (twp.wp_type == "Normal" or twp.wp_type == "Outer Marker") {
              wpLen = getprop("/autopilot/route-manager/route/num");
              var wpIns = "";
              var idExists = 0;
              for(var r=0; r != wpLen; r=r+1) {
                var rId = getprop("/autopilot/route-manager/route/wp["~r~"]/id");
                if (rId == twp.wp_name) {
                  idExists = 1;
                }
              }
              if (idExists == 0) {
                var wpName = twp.wp_name;
                var wpAlt = -1;
                if (twp.alt_csrt > 0) {
                  wpAlt = int(twp.alt_csrt);
                }
                if (twp.wp_type == "Outer Marker") {
                  wpName = sprintf("%i:%s,%s",wpLen-1,twp.wp_lon,twp.wp_lat);
                  insertAbsWP("OM",wpLen-1,wp_lat,wp_lon,wpAlt);
                  tracer("insert approach OM");
                } else {
                  wpIns = sprintf("%i:%s@%i",wpLen-1,wpName,wpAlt);
                  tracer("Insert approach transition: "~wpIns~", of type: "~twp.wp_type);
		  tracer("/autopilot/route-manager/input, @insert "~wpIns);
                  setprop("/autopilot/route-manager/input", "@insert "~wpIns);
                }
              }
            }
            
          }
        }
      }
      var runwayTransArm = 0;
      foreach(var awp; iap.wpts) {
        tracer("[Star.IAP] approach wp: "~awp.wp_name~", type: "~awp.wp_type);
        if (awp.wp_type == "Runway") {
              runwayTransArm = 1;   #Don't include GA in approach.
              break;
        }
        if ((awp.wp_type == "Normal" or awp.wp_type == "Outer Marker" or awp.wp_type == "Middle Marker") and runwayTransArm == 0) {
          wpLen = getprop("/autopilot/route-manager/route/num");
          var wpIns = "";
          var idExists = 0;
          for(var r=0; r!= wpLen; r=r+1) {
            var rId = getprop("/autopilot/route-manager/route/wp["~r~"]/id");
            if (rId == awp.wp_name) {
              tracer("[Star.IAP] awp: "~awp.wp_name~" already exists!");
              idExists = 1;
            }
          }
          if (idExists == 0) {
            wpLen = getprop("/autopilot/route-manager/route/num");
            var wpName = awp.wp_name;
            var wpAlt = -1;
            if (awp.alt_csrt >0) {
              wpAlt = int(awp.alt_csrt);
            }
            if (awp.wp_type == "Outer Marker" or awp.wp_type == "Middle Marker") {
              var type = "O.M";
              if (awp.wp_type == "Middle Marker") {
                type = "M.M";
              }
              insertAbsWP(type,wpLen-1,awp.wp_lat,awp.wp_lon,wpAlt);
            } else {
              wpIns = sprintf("%i:%s@%i",wpLen-1,wpName,wpAlt);
              tracer("Insert approach route: "~wpIns~", of type: "~awp.wp_type);
	      tracer("/autopilot/route-manager/input, @insert "~wpIns);
              setprop("/autopilot/route-manager/input", "@insert "~wpIns);
            }
          }
        }
      }
    } else {
      tracer("[MCDU] WARN: found "~size(appr)~" approaches, can't use any!!");
    }
    setprop("/autopilot/route-manager/cruise/flight-level",crzFl);
    setprop("/autopilot/route-manager/cruise/altitude-ft",(crzFl*100));
    setprop("/autopilot/route-manager/cruise/speed-kts",480);
    updateApproachAlts();
    tracer("/autopilot/route-manager/input, @ACTIVATE");
    setprop("/autopilot/route-manager/input", "@ACTIVATE");
    ##setprop("/autopilot/route-manager/active",1);
  }
  setprop("/instrumentation/mcdu["~unit~"]/opt-scroll", 0);
  changePage(unit, nextPage);
}



#####################################
#
#
selectSidTransAction = func(val, unit) {
    
    var sidTransVal = getprop("/instrumentation/mcdu["~unit~"]/"~val);
    setprop("/instrumentation/afs/sid-trans", sidTransVal);
    tracer("[MCDU] set sid transition with: "~sidTransVal);
    var sidVal = getprop("/instrumentation/afs/sid");
    var sid = depDB.getSid(sidVal);
    var pos = 0;
    var crzFl = getprop("/instrumentation/afs/CRZ_FL");
    var wpLen = getprop("/autopilot/route-manager/route/num");
    foreach(var sidTran; sid.transitions) {
      if (sidTran.trans_name == sidTransVal) {
        for(var w=0; w != size(sidTran.trans_wpts);w=w+1) {
          var wpIns = "";
          var wp = sidTran.trans_wpts[w];
          tracer(" add sid wp: "~wp.wp_name);
          if (w == size(sidTran.trans_wpts)-1) {
            wp.alt_csrt = (crzFl*100);
          }
          if (wp.alt_csrt != nil and wp.alt_csrt > 0) {
            wpIns = sprintf("%i:%s@%i",(wpLen+w),wp.wp_name,int(wp.alt_csrt));
          } else {
            wpIns = sprintf("%i:%s@-1",(wpLen+w),wp.wp_name);
          }
          tracer("[FMS] Insert route: "~wpIns~", of type: "~wp.wp_type);
          if (wp.wp_type == "Normal") {
	    tracer("/autopilot/route-manager/input, @insert "~wpIns);
            setprop("/autopilot/route-manager/input", "@insert "~wpIns);
          }
        }
      }
    }

  changePage(unit, "active.departure.dep");
}

updateApproachAlts = func() {
### we need to calculate diff alt.
     tracer(" update approach heights..");
     var rtSize = getprop("/autopilot/route-manager/route/num");
     var crzFt  = getprop("/instrumentation/afs/thrust-cruise-alt");
     tracer(">>>>>>>>>>>>>> current thrust-cruise-alt: "~crzFt);
     var crzArm = 0;
     for(var r=0; r < rtSize-1; r=r+1) {
       rtSize = getprop("/autopilot/route-manager/route/num");
       var rtAlt = getprop("/autopilot/route-manager/route/wp["~r~"]/altitude-ft");
       if (crzArm == 1 and rtAlt < 0 and (r+1) <= rtSize) {
         var rtLat = getprop("/autopilot/route-manager/route/wp["~r~"]/latitude-deg");
         var rtLon = getprop("/autopilot/route-manager/route/wp["~r~"]/longitude-deg");
         var rtId  = getprop("/autopilot/route-manager/route/wp["~r~"]/id");
         var nextLat = getprop("/autopilot/route-manager/route/wp["~(r+1)~"]/latitude-deg");
         var nextLon = getprop("/autopilot/route-manager/route/wp["~(r+1)~"]/longitude-deg");
         var nextAlt = getprop("/autopilot/route-manager/route/wp["~(r+1)~"]/altitude-ft");
         var prevLat = getprop("/autopilot/route-manager/route/wp["~(r-1)~"]/latitude-deg");
         var prevLon = getprop("/autopilot/route-manager/route/wp["~(r-1)~"]/longitude-deg");
         var prevAlt = getprop("/autopilot/route-manager/route/wp["~(r-1)~"]/altitude-ft");
         
         var nextWpLat = 0.0;
         var nextWpLon = 0.0;
         var nextWpAlt = 1;
         if (r+2 <= rtSize) {
           nextWpAlt = getprop("/autopilot/route-manager/route/wp["~(r+1)~"]/altitude-ft");
         }

         tracer("[FMS] start - r="~r~" of "~rtSize);
         tracer("[FMS] rtId="~rtId~" prev trans lat: "~prevLat~"/lon: "~prevLon~", next lat: "~nextLat~"/lon: "~nextLon~", this lat: "~rtLat~"/lon: "~rtLon);
         tracer("[FMS] prev trans alt: "~prevAlt~", next alt: "~nextAlt);
         var prevDist = gcd2(prevLat, prevLon, rtLat, rtLon, "nm");
         var nextDist = gcd2(rtLat, rtLon, nextLat, nextLon, "nm");
         if (nextAlt == -1) {
           var lastWpLat = nextLat;
           var lastWpLon = nextLon;
           tracer("[FMS] begin calc intermediate: nextWpAlt: "~nextWpAlt~", nextDist: "~nextDist);
           for(var rplus = r+2; rplus <= rtSize and (nextWpAlt == -1); rplus=rplus+1) {
             nextWpLat = getprop("/autopilot/route-manager/route/wp["~(rplus)~"]/latitude-deg");
             nextWpLon = getprop("/autopilot/route-manager/route/wp["~(rplus)~"]/longitude-deg");
             nextWpAlt = getprop("/autopilot/route-manager/route/wp["~(rplus)~"]/altitude-ft");
             var tmpDist = gcd2(lastWpLat, lastWpLon, nextWpLat, nextWpLon, "nm");
             tracer("[FMS] add intermediate WP dist: "~tmpDist);
             nextDist = nextDist+tmpDist;
             lastWpLat = nextWpLat;
             lastWpLon = nextWpLon;
           }
           #####nextAlt = nextWpAlt;
           tracer("[FMS] total intermediate distance: "~nextDist~", nextAlt: "~nextAlt);
           nextAlt = nextWpAlt;
         }

         if (nextAlt == -1) {
           var angle = 3;
           if ((prevAlt-5000) < 11000) {
             angle = 2;
           }
           var tmpHeight = calcHeightAtAngle(angle,(prevDist+nextDist));
           nextAlt = prevAlt-tmpHeight;
           tracer("[FMS] invalid nextAlt recalc - nextAlt: "~nextAlt~", tmpHeight: "~tmpHeight~", angle: "~angle);
         }
         tracer("[FMS] end - prev trans Dist: "~prevDist~"nm, nextDist: "~nextDist~"nm");
         var thisAlt = int(prevAlt-(((prevAlt-nextAlt)/(prevDist+nextDist))*prevDist));
         if (thisAlt < 100) {
           tracer("***** [FMS] incorrect calculation!!  thisAlt: "~thisAlt);
         }
	 tracer("/autopilot/route-manager/input, @delete "~(r));
         setprop("/autopilot/route-manager/input","@delete "~(r));
         var rpIns = sprintf("@insert %i:%s@%i",(r),rtId,thisAlt);
         tracer("[FMS] update idx["~r~"] for id: "~rtId~" with alt: "~thisAlt);
         if (rtId == "O.M" or rtId == "T/D" or rtId == "M.M" or rtId == "T/C") {
           insertAbsWP(rtId,r,rtLat,rtLon,thisAlt);
         } else {
	   tracer("/autopilot/route-manager/input, "~rpIns);
           setprop("/autopilot/route-manager/input",rpIns);
         }
         #setprop("/autopilot/route-manager/route/wp["~r~"]/altitude-ft", thisAlt);
         #setprop("/autopilot/route-manager/route/wp["~r~"]/altitude-m", thisAlt*0.3);
         tracer("[FMS] update wp: "~rtId~", with alt: "~thisAlt);
         if (prevAlt == crzFt and thisAlt < crzFt) {
           tracer("[FMS] update thrust descent alt: "~thisAlt);
           setprop("/instrumentation/afs/thrust-descent-alt",thisAlt);
         }
       }
       if (rtAlt == crzFt) {
         crzArm = 1;
       }
     }
}


##################
## scroll more runways
scrollRwy = func(unit,direct) {
  var rwyScroll = getprop("/instrumentation/mcdu["~unit~"]/opt-scroll");
  var maxRwy    = getprop("/instrumentation/mcdu["~unit~"]/opt-size");
  if (direct == "more") {
    rwyScroll = rwyScroll+1;
  } else {
    rwyScroll = rwyScroll-1;
  }
  if (rwyScroll > int(maxRwy/8)) {
    rwyScroll = int(maxRwy/8);
  }
  if (rwyScroll < 0) {
    rwyScroll = 0;
  }
  for(r =0; r != 8; r=r+1) {
      var rwyAttr = sprintf("/instrumentation/mcdu[%i]/opt%02i",unit,r+1);
      var rwyLenAttr = sprintf("/instrumentation/mcdu[%i]/col01-opt%02i",unit,r+1);
      var rwyHdgAttr = sprintf("/instrumentation/mcdu[%i]/col02-opt%02i",unit,r+1);
     
      setprop(rwyAttr,"");
      setprop(rwyLenAttr,0);
      setprop(rwyHdgAttr,0);
  }
  setprop("/instrumentation/mcdu["~unit~"]/opt-scroll",rwyScroll);
  changePage(unit,getprop("/instrumentation/mcdu["~unit~"]/page"));
}

##############################################
## get ILS frequency from airportinfo.
var getILS = func(apt, rwy) {
   if (trace > 0) {
     debug.dump(apt);
   }
   var mhz = nil;
   var runways = apt["runways"];
   var ks = keys(runways);
   for(var r=0; r != size(runways); r=r+1) {
     var run = runways[ks[r]];
     if (run.id == rwy and contains(run, "ils_frequency_mhz")) {
       mhz = sprintf("%3.1f",run.ils_frequency_mhz);
       return mhz;
     }
   }
   return mhz;
}

#####################################################
# removed from "active.departure.dep"
addMissingDeparture = func() {
  var wpLen = getprop("/autopilot/route-manager/route/num");
  var foundWp = 0;
  var strLen = size(depApt.id);
  for(w=0; w < wpLen; w=w+1) {
    var wpName = substr(getprop("/autopilot/route-manager/route/wp["~w~"]/id"),0,strLen);
    if (wpName == depApt.id) {
            foundWp = 1;
    }
  }
  if (foundWp == 0) {
    var wpIns = sprintf("%s@%i",depApt.id,depApt.elevation);
    tracer("clear route-manager, add depart airport: "~wpIns);
    tracer("/autopilot/route-manager/input, "~wpIns);
    setprop("/autopilot/route-manager/input",wpIns);
  }
}


########################################################
#  removed from active.departure.arv
addMissingArrival = func() {
var wpLen = getprop("/autopilot/route-manager/route/num");
    var foundWp = 0;
    var strLen = size(arvApt.id);
    for(w=0; w < wpLen; w=w+1) {
        var wpName = substr(getprop("/autopilot/route-manager/route/wp["~w~"]/id"),0,strLen);
        if (wpName == arvApt.id) {
          foundWp = 1;
        }
    }
    if (foundWp == 0) {
      var wpIns = sprintf("%s@%i",arvApt.id, arvApt.elevation);
      tracer("/autopilot/route-manager/input, "~wpIns);
      setprop("/autopilot/route-manager/input", wpIns);
    }
}


#################################################
#   basic mathematic functions not in Nasal :(
#################################################

var acos = func(x) { 
  math.atan2(math.sqrt(1-x*x), x) 
}

var asin = func(x) {
 math.atan2(x,math.sqrt(math.pow(2,1-x)));
}

var degMin2rad = func(deg, min) {
  var d1 = deg+(min/60);
  return d1*(math.pi/180);
}

var nm2rad = func(d) {
 return d*math.pi/(180*60);
}

var calcDistAtAngle = func(angleX, height) {
    var anglexinradians = angleX*(math.pi/180);
    # solve for side b
    var sideb = height/math.tan(anglexinradians);
    var sidebNM = sideb/6076;
    return sidebNM;
}

var calcHeightAtAngle = func(angleX, dist) {
    var anglexinradians = angleX*(math.pi/180);
    var sidec = dist/math.cos(anglexinradians);
    var sidecNM = sidec/6076;
    return sidecNM;
}


##################################################
#  calculate Great Circle distance between two points
#    unit = ("km", "mi", "nm")
#
var gcd2 = func(lat1, lon1, lat2, lon2, unit) {
  var earth_radius = 6372.795;
  var lng_rad0 = lon1*DEG2RAD;
  var lat_rad0 = lat1*DEG2RAD;
  var lng_rad1 = lon2*DEG2RAD;
  var lat_rad1 = lat2*DEG2RAD;

  var sin_lat0 = math.sin(lat_rad0);
  var cos_lat0 = math.cos(lat_rad0);
  var sin_lat1 = math.sin(lat_rad1);
  var cos_lat1 = math.cos(lat_rad1);

  var delta_lng = lng_rad1-lng_rad0;
  var cos_delta_lng = math.cos(delta_lng);
  var sin_delta_lng = math.sin(delta_lng);

  var central_angle = math.acos(sin_lat0 * sin_lat1 + cos_lat0 * cos_lat1 * cos_delta_lng);

  var clsdl = (cos_lat1 * sin_delta_lng);
  if (clsdl < 0) {
    clsdl = clsdl*-1.0;
  }
  var p1 = math.pow(clsdl, 2);

  var csscc = (cos_lat0 * sin_lat1 - sin_lat0 * cos_lat1 * cos_delta_lng);
  if (csscc < 0) {
    csscc = csscc*-1.0;
  }
  var p2 = math.pow(csscc, 2);
  var sq1 = math.sqrt(p1 + p2);
  var p3 = sin_lat0 * sin_lat1 + cos_lat0 * cos_lat1 * cos_delta_lng;
  var gcdx = math.atan2(sq1,p3);

  var km = gcdx*earth_radius;
  if (unit == "km") {
    km = gcdx*earth_radius;
  } 
  if (unit == "mi") {
    km = (gcdx*earth_radius)*0.621371192;
  }
  if (unit == "nm" ) {
    km = (gcdx * earth_radius) / 1.852;
  }
  return km;
}



####################################################################
# calculate great circle true course using radians and distance in nm.
####################################################################
var calcGCTrueCourse = func(d, lat1, lon1, lat2, lon2) {
  var tc1 = 0;
  if(math.sin(lon2-lon1)<0) {      
   tc1=acos((math.sin(lat2)-math.sin(lat1)*math.cos(d))/(math.sin(d)*math.cos(lat1)));
  } else {   
   var d1 = (math.sin(lat2)-math.sin(lat1)*math.cos(d));
   var d2 = (math.sin(d)*math.cos(lat1));
   var dd1 = d1/d2;
   tracer("[calcTC] d1: "~d1~", d2: "~d2~", dd1: "~dd1);
   tc1=(2*math.pi)-math.acos(dd1);
  }
  return tc1;
}

#######################################################################
#  calculate lat,lon of point that is d distance from lat,lon by tc true course in radians
#######################################################################
var calcDistancePoint = func(tc, d, lat1, lon1) {
  tracer("tc: "~tc~", d: "~d~", lat1: "~lat1~", lon1: "~lon1);
  var lat = math.asin(math.sin(lat1)*math.cos(d)+math.cos(lat1)*math.sin(d)*math.cos(tc));
  #print("lat: "~lat);
  var dlon = math.atan2(math.sin(tc)*math.sin(d)*math.cos(lat1),math.cos(d)-math.sin(lat1)*math.sin(lat));
  #print("dlon: "~dlon);
  var lon = math.mod(lon1-dlon+math.pi,2*math.pi )-math.pi;
  #print("lon: "~lon);
  var latDeg = lat*RAD2DEG;
  var lonDeg = lon*RAD2DEG;
  tracer("[calcDistPoint] latDeg: "~latDeg~", lonDeg: "~lonDeg);
  var dest = geo.Coord.new();
  dest.set_latlon(latDeg, lonDeg, 0);
  #print("final lat: "~latDeg~", lon: "~lonDeg);
  return dest;
}

var calcDistancePointDeg = func(tc, d, lat1, lon1) {
  return calcDistancePoint(tc*DEG2RAD, nm2rad(d), (lat1*DEG2RAD), (lon1*DEG2RAD));
}

######################################################################
# calc straight line course between two points
######################################################################
var calcOrthHeadingDeg = func(lat1, lon1, lat2, lon2) {
 tracer("[calcOrth] lat1: "~lat1~", lon1: "~lon1~", lat2: "~lat2~", lon2: "~lon2);
 lat1 *= DEG2RAD;
 lon1 *= DEG2RAD;
 lat2 *= DEG2RAD;
 lon2 *= DEG2RAD;
 
 sin_lat1 = math.sin(lat1);
 cos_lat1 = math.cos(lat1);
 sin_lat2 = math.sin(lat2);
 cos_lat2 = math.cos(lat2);
 dlon = lon2-lon1;
   
 Aorth = math.atan2(math.sin(dlon)*cos_lat2, cos_lat1*sin_lat2-sin_lat1*cos_lat2*math.cos(dlon));
 while ( Aorth >= TWOPI ) {Aorth -= TWOPI};
 if(Aorth<0) Aorth+= TWOPI;
 return (Aorth*RAD2DEG);
}

insertAbsWP = func(id, index, lat, lon, alt) {
  tracer("/instrumentation/gps/scratch/altitude-ft, "~alt);
  setprop("/instrumentation/gps/scratch/altitude-ft",alt);
  tracer("/instrumentation/gps/scratch/ident, "~id);
  setprop("/instrumentation/gps/scratch/ident",id);
  tracer("/instrumentation/gps/scratch/index, "~index);
  setprop("/instrumentation/gps/scratch/index",index);
  tracer("/instrumentation/gps/scratch/latitude-deg, "~lat);
  setprop("/instrumentation/gps/scratch/latitude-deg",lat);
  tracer("/instrumentation/gps/scratch/longitude-deg, "~lon);
  setprop("/instrumentation/gps/scratch/longitude-deg",lon);
  tracer("/instrumentation/gps/scratch/name, "~id);
  setprop("/instrumentation/gps/scratch/name",id);
  tracer("/instrumentation/gps/scratch/type, waypoint");
  setprop("/instrumentation/gps/scratch/type","waypoint");
  tracer("/instrumentation/gps/command, route-insert-before");
  setprop("/instrumentation/gps/command","route-insert-before");
}




### Call the init_mcdu after a few seconds to give time for other systems to settle.
#  after all the function names have been parsed and are available.
# 
settimer(init_mcdu, 2);
