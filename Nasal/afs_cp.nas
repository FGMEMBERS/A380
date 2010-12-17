#########################################################
#  A380 Auto Flight System Control Panel toggles
#
#  Abstract:
#    This is some nasal to toggle the various modes from the
#    AFS panel. The tree under /autopilot is the F11 (key) menu,
#    the tree under /instrumentation drives the flight director. 
#  
#  Author:  S.Hamilton
#  Version: V1.0
#
#
#   Copyright (C) 2009 Scott Hamilton
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
#  Modification History
#  Who     When        What
#  SH      1-APR-2009  Initial cut
#  SH      7-JUN-2009  Added Thrust detents
#  SH      18-MAY-2010 clean up toggling of various modes and displays
#  SH      17-OCT-2010 support both alt and v/s in selected mode
#
#

hdg_vs_select=0;
detent_repeat_time = 0.0;
throttleRates = [0.0, 0.67, 0.90, 0.97];
flexTempN1 = [96.6, 96.5, 96.5, 96.5, 96.4, 96.4, 96.4, 96.3, 96.3, 96.3, 96.1, 96.0, 95.8, 95.6, 95.5, 95.3, 95.2, 95.0, 94.9, 94.7, 94.5, 94.4, 94.2, 94.1, 93.9, 93.8, 93.6, 93.5, 93.3, 93.1, 93.0, 92.8, 92.7, 92.5, 92.4, 92.2, 92.1, 91.9, 91.7, 91.6, 91.4, 91.3, 91.1, 91.0, 90.8, 90.7, 90.5, 90.3, 90.2, 90.0, 89.9, 89.7, 89.6, 89.4, 89.3, 89.1, 88.9, 88.8, 88.6, 88.5, 88.3, 88.3, 88.2, 88.1, 88.0 ];

timer = {
    "vertical-alt-display": 0,
    "vertical-vs-display": 0,
    "spd-display": 0,
    "lateral-display": 0
};

## mode constants
LNAV_OFF=0;
LNAV_HDG=1;
LNAV_TRACK=2;
LNAV_LOC=3;
LNAV_FMS=4;
LNAV_RWY=5;

VNAV_OFF=0;
VNAV_ALTs=1;
VNAV_VS=2;
VNAV_OPCLB=3;
VNAV_FPA=4;
VNAV_OPDES=5;
VNAV_CLB=6;
VNAV_ALTCRZ=7;
VNAV_DES=8;
VNAV_GS=9;
VNAV_SRS=10;
VNAV_LEVEL=11;

SPD_OFF=0;
SPD_TOGA=1;
SPD_FLEX=2;
SPD_THRCLB=3;
SPD_SPEED=4;
SPD_MACH=5;
SPD_CRZ=6;
SPD_THRDES=7;
SPD_THRIDL=8;

# working memory
afs_trace = 0;
afs_version = "1.0.9";




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
  if (afs_trace > 0) {
    print("[afs] time: "~timeStr~" alt: "~curAltStr~", - "~msg);
    if (afs_trace > 1) {
      ###print("[afs] vnav: "~vnavStr[curVnav]~", lnav: "~lnavStr[curLnav]~", spd: "~spdStr[curSpd]);
    }
  }
}


toggle_fd = func() {
  if (getprop("/autopilot/locks/passive-mode") == 1) {
     setprop("/autopilot/locks/passive-mode",0);
     setprop("/instrumentation/flightdirector/fd-on",0);
  } else {
     setprop("/autopilot/locks/passive-mode",1);
     setprop("/instrumentation/flightdirector/fd-on",1);
  }
}

toggle_ap = func(n) {
      apeng = getprop("/controls/autoflight/autopilot["~n~"]/engage");
      if (apeng == 1) {
        setprop("/instrumentation/flightdirector/autopilot-on",0);
        setprop("/controls/autoflight/autopilot["~n~"]/engage","false");
      } else {
        setprop("/controls/autoflight/autopilot["~n~"]/engage","true");
	setprop("/instrumentation/flightdirector/autopilot-on",1);
      }
      setprop("instrumentation/flightdirector/alt-acquire-mode",0);
      ### called each of the modes to evaluate their current settings ###
      toggle_spd_select(0);
      toggle_hdg_select(0);
      toggle_alt_select(0);
      toggle_vs_select(0);
      
}

toggle_loc = func() {
      var curHead = getprop("/autopilot/locks/heading");
      tracer("current: "~curHead);
      if (curHead == "nav1-hold") {
	setprop("instrumentation/flightdirector/lnav",0);
        setprop("/autopilot/locks/heading","");
      } else {
        var inRange1 = getprop("/instrumentation/nav[0]/in-range");
        tracer("AFS: localizer inrange: "~inRange1);
        if ((inRange1 == 1) or (getprop("/instrumentation/nav[1]/in-range") == 1)) {
          setprop("/autopilot/locks/heading","nav1-hold");
          # notice that nav1 loc is different than APPR?
	  setprop("/instrumentation/flightdirector/lnav",LNAV_LOC);
          setprop("instrumentation/flightdirector/alt-acquire-mode",0);
        }
      }
}

toggle_alt = func() {
      if (getprop("/autopilot/locks/altitude") == "pitch-hold") {
        setprop("instrumentation/flightdirector/vnav",0);
        setprop("/autopilot/locks/altitude","");
      } else {
	setprop("/instrumentation/flightdirector/vnav",11);
      }
}

increment_alt = func() {
    time_reset_alt("vertical-alt-display");
    incAmt = getprop("/controls/afs/alt-inc-select");
    curAlt = getprop("/instrumentation/afs/target-altitude-ft");
    curAlt = curAlt+incAmt;
    if (curAlt > 49000) {
      curAlt = 49000;
    }
    var altSelect = getprop("/instrumentation/afs/vertical-alt-mode");
    var vsSelect  = getprop("/instrumentation/afs/vertical-vs-mode");
    if (altSelect == 0 and vsSelect == 0) {
      setprop("/instrumentation/flightdirector/vnav", VNAV_VS);
      setprop("/instrumentation/flightdirector/alt-acquire-mode",1);
      setprop("/instrumentation/flightdirector/vnav-arm", VNAV_ALTs);
    }
    setprop("/instrumentation/afs/target-altitude-ft",curAlt);
    if (getprop("/instrumentation/flightdirector/vnav") == VNAV_ALTs) {
      setprop("/autopilot/settings/target-altitude-ft", curAlt);
    }
}

decrement_alt = func() {
    time_reset_alt("vertical-alt-display");
    incAmt = getprop("/controls/afs/alt-inc-select");
    curAlt = getprop("/instrumentation/afs/target-altitude-ft");
    curAlt = curAlt+-incAmt;
    if (curAlt < 0) {
      curAlt = 0;
    }
    var altSelect = getprop("/instrumentation/afs/vertical-alt-mode");
    var vsSelect  = getprop("/instrumentation/afs/vertical-vs-mode");
    if (altSelect == 0 and vsSelect == 0) {
      setprop("/instrumentation/flightdirector/vnav", VNAV_VS);
      setprop("/instrumentation/flightdirector/alt-acquire-mode",1);
      setprop("/instrumentation/flightdirector/vnav-arm", VNAV_ALTs);
    }
    setprop("/instrumentation/afs/target-altitude-ft",curAlt);
    if (getprop("/instrumentation/flightdirector/vnav") == VNAV_ALTs) {
      setprop("/autopilot/settings/target-altitude-ft", curAlt);
    }
}

increment_vs = func() {
    time_reset_vs("vertical-vs-display");
    var curr = getprop("/instrumentation/afs/vertical-speed-fpm");
    curr += 100;
    if (curr > 9000) {
      curr = 9000;
    }
    if (curr < -9000) {
      curr = -9000;
    }
    setprop("/instrumentation/afs/vertical-speed-fpm",curr);
    if (getprop("/instrumentation/flightdirector/vnav") == VNAV_VS) {
      setprop("/autopilot/settings/vertical-speed-fpm",curr);
    }
}

decrement_vs = func() {
    time_reset_vs("vertical-vs-display");
    var curr = getprop("/instrumentation/afs/vertical-speed-fpm");
    curr -= 100;
    if (curr > 9000) {
      curr = 9000;
    }
    if (curr < -9000) {
      curr = -9000;
    }
    setprop("/instrumentation/afs/vertical-speed-fpm",curr);
    if (getprop("/instrumentation/flightdirector/vnav") == VNAV_VS) {
      setprop("/autopilot/settings/vertical-speed-fpm",curr);
    }
}

increment_hdg = func() {
    time_reset_hdg("lateral-display");
    var curr = getprop("/instrumentation/afs/heading-bug-deg");
    curr += 1;
    if (curr > 360) {
      curr = 0;
    }
    if (curr < 0) {
      curr = 360;
    }
    setprop("/instrumentation/afs/heading-bug-deg",curr);
    setprop("/autopilot/settings/heading-bug-deg",curr);
}

decrement_hdg = func() {
    time_reset_hdg("lateral-display");
    var curr = getprop("/instrumentation/afs/heading-bug-deg");
    curr -= 1;
    if (curr > 360) {
      curr = 0;
    }
    if (curr < 0) {
      curr = 360;
    }
    setprop("/instrumentation/afs/heading-bug-deg",curr);
    setprop("/autopilot/settings/heading-bug-deg",curr);
}

increment_spd = func() {
    time_reset_spd("spd-display");
    var curr = getprop("/instrumentation/afs/target-speed-kt");
    curr += 1;
    if (curr > 360) {
      curr = 360;
    }
    if (curr < 0) {
      curr = 0;
    }
    setprop("/instrumentation/afs/target-speed-kt",curr);
    if (getprop("/instrumentation/flightdirector/spd") == SPD_SPEED) {
      setprop("/autopilot/settings/target-speed-kt", curr);
    }
}

decrement_spd = func() {
    time_reset_spd("spd-display");
    var curr = getprop("/instrumentation/afs/target-speed-kt");
    curr -= 1;
    if (curr > 360) {
      curr = 360;
    }
    if (curr < 0) {
      curr = 0;
    }
    setprop("/instrumentation/afs/target-speed-kt",curr);
    if (getprop("/instrumentation/flightdirector/spd") == SPD_SPEED) {
      setprop("/autopilot/settings/target-speed-kt", curr);
    }
}

###  listeners so we can set AFS values either on the CP or in the AP dialog
setlistener("/autopilot/settings/heading-bug-deg", func(n) {
   var val = n.getValue();
   var mode = getprop("instrumentation/afs/lateral-mode");
   if (mode == 0) {
     setprop("/instrumentation/afs/heading-bug-deg",val);
   }
});

setlistener("/autopilot/settings/target-altitude-ft", func(n) {
   var val = n.getValue();
   var mode = getprop("instrumentation/afs/vertical-alt-mode");
   if (mode == 0) {
     setprop("/instrumentation/afs/target-altitude-ft",val);
   }
});

setlistener("/autopilot/settings/target-speed-kt", func(n) {
   var val = n.getValue();
   var mode = getprop("instrumentation/afs/speed-mode");
   if (mode == 0) {
     setprop("/instrumentation/afs/target-speed-kt",val);
   }
});

setlistener("/autopilot/settings/vertical-speed-fpm", func(n) {
   var val = n.getValue();
   var mode = getprop("/instrumentation/afs/vertical-vs-mode");
   if (mode == 0) {
     setprop("/instrumentation/afs/vertical-speed-fpm",val);
   }
});


toggle_vs_select = func(n) {
      mode = getprop("instrumentation/flightdirector/vnav");
      vs = getprop("instrumentation/afs/vertical-vs-mode");
      vs = vs+n;
      apMode = getprop("/instrumentation/flightdirector/autopilot-on");
      verticalMode = getprop("/instrumentation/afs/vertical-alt-mode");
      var finalVNAVMode = VNAV_OFF;
      if (vs < -1) {
        vs = -1;
      }
      if (vs > 0) {
        vs = 0;
      }
      setprop("/instrumentation/afs/vertical-vs-mode", vs);
      setprop("/instrumentation/flightdirector/alt-acquire-mode",0);
      tracer("toggle_vs_select - cur vnav: "~mode~" func: "~n~" vs mode: "~vs);

      var aFMS = AirbusFMS.new();
      var armMode = VNAV_OFF;
      finalVNAVMode = aFMS.evaluateVNAV();
      if (finalVNAVMode == VNAV_SRS) {
        armMode = VNAV_CLB;
      }
      if (finalVNAVMode == VNAV_VS) {
        armMode = aFMS.evaluateManagedVNAV();
        if (verticalMode == 0) {
          setprop("/autopilot/settings/vertical-speed-fpm",getprop("/instrumentation/afs/vertical-speed-fpm"));
          setprop("/instrumentation/flightdirector/alt-acquire-mode",1);
        }
      }
      if (finalVNAVMode == VNAV_OPCLB) {
        armMode = aFMS.evaluateManagedVNAV();
      }
      if (finalVNAVMode == VNAV_OPDES) {
        armMode = aFMS.evaluateManagedVNAV();
      }
      if (apMode == 0) {
        setprop("/autopilot/locks/alitutde","");
        finalVNAVMode = VNAV_OFF;
        setprop("instrumentation/flightdirector/alt-acquire-mode",0);
      }
      setprop("/instrumentation/flightdirector/vnav", finalVNAVMode);
      setprop("/instrumentation/flightdirector/vnav-arm", armMode);
      
      setprop("/instrumentation/afs/vertical-vs-display", vs);
}

toggle_alt_select = func(n) {
      mode = getprop("/instrumentation/flightdirector/vnav");
      vertical = getprop("/instrumentation/afs/vertical-alt-mode");
      vertical = vertical+n;
      apMode = getprop("/instrumentation/flightdirector/autopilot-on");
      vsMode = getprop("/instrumentation/afs/vertical-vs-mode");
      var finalVNAVMode = VNAV_OFF;
      if (vertical < -1) {
        vertical = -1;
      }
      if (vertical > 0) {
        vertical = 0;
      }
      setprop("/instrumentation/afs/vertical-alt-mode", vertical);
      setprop("/instrumentation/flightdirector/alt-acquire-mode",0);
      tracer("toggle_alt_select - cur vnav: "~mode~" func: "~n~" new vertical: "~vertical);
      
      var aFMS = AirbusFMS.new();
      var armMode = VNAV_OFF;
      finalVNAVMode = aFMS.evaluateVNAV();
      if (finalVNAVMode == VNAV_SRS) {
        armMode = VNAV_CLB;
      }
      if (finalVNAVMode == VNAV_VS and vertical == 0) {
        setprop("/autopilot/settings/vertical-speed-fpm",getprop("/instrumentation/afs/vertical-speed-fpm"));
        armMode = VNAV_ALTs;
        setprop("/instrumentation/flightdirector/alt-acquire-mode",1);
      }
      if (finalVNAVMode == VNAV_OPCLB) {
        armMode = VNAV_CLB;
      }
      if (finalVNAVMode == VNAV_OPDES) {
        armMode = VNAV_DES;
      }
      if (apMode == 0) {
        setprop("/autopilot/locks/alitutde","");
        finalVNAVMode = VNAV_OFF;
        setprop("instrumentation/flightdirector/alt-acquire-mode",0);
      }

      setprop("/instrumentation/flightdirector/vnav",finalVNAVMode);
      setprop("/instrumentation/flightdirector/vnav-arm", armMode);
      
      setprop("/instrumentation/afs/vertical-alt-display", vertical);
}

toggle_spd_select = func(n) {
      mode = getprop("/instrumentation/flightdirector/spd");
      speed = getprop("instrumentation/afs/speed-mode");
      speed = speed+n;
      apMode = getprop("/instrumentation/flightdirector/autopilot-on");
      if (speed < -1) {
        speed = -1;
      }
      if (speed > 0) {
        speed = 0;
      }
      tracer("toggle_spd_select - cur spd: "~mode~" func: "~n~" new speed: "~speed);
      if (apMode == 0) {
        setprop("/instrumentation/flightdirector/spd",0);
      }
      if (speed == -1) {
        curAlt = getprop("/position/altitude-ft");
        crzAlt = getprop("/instrumentation/afs/thrust-cruise-alt");
        accelAlt = getprop("/instrumentation/afs/thrust-accel-alt");
        desAlt = getprop("/instrumentation/afs/thrust-descent-alt");
        vnav   = getprop("/instrumentation/flightdirector/vnav");
        if (curAlt >= (crzAlt-50)) {
          if (apMode == 1) {
            setprop("/instrumentation/flightdirector/spd",SPD_CRZ);
          } else {
            setprop("/instrumentation/flightdirector/spd-arm",SPD_CRZ);
          }
        }
        if (curAlt >= accelAlt and curAlt < crzAlt and (vnav == VNAV_CLB or vnav == VNAV_SRS)) {
          if (apMode == 1) {
            setprop("/instrumentation/flightdirector/spd",SPD_THRCLB);
          } else {
            setprop("/instrumentation/flightdirector/spd-arm",SPD_THRCLB);
          }
        }
        if (curAlt > 5000 and curAlt < crzAlt and (vnav == VNAV_DES or vnav == VNAV_OPDES)) {
          if (apMode == 1) {
            setprop("/instrumentation/flightdirector/spd",SPD_THRDES);
          } else {
            setprop("/instrumentation/flightdirector/spd-arm",SPD_THRDES);
          }
        }
      }
      if (speed == 0) {
        if (apMode == 1) {
          setprop("/autopilot/settings/target-speed-kt", getprop("/instrumentation/afs/target-speed-kt"));
          setprop("/instrumentation/flightdirector/spd",SPD_SPEED);
        } else {
          setprop("/instrumentation/flightdirector/spd-arm",SPD_OFF);
        }
      }
      setprop("/instrumentation/afs/speed-mode", speed);
      setprop("/instrumentation/afs/spd-display", speed);
}

toggle_hdg_select = func(n) {
      mode = getprop("instrumentation/flightdirector/lnav");
      lateral = getprop("instrumentation/afs/lateral-mode");
      lateral = lateral+n;
      apMode = getprop("/instrumentation/flightdirector/autopilot-on");
      var vnav = getprop("/instrumentation/flightdirector/vnav");
      if (lateral < -1) {
        lateral = -1;
      }
      if (lateral > 0) {
        lateral = 0;
      }
      tracer("toggle_hdg_select - cur lnav: "~mode~" func: "~n~" new lateral: "~lateral);
      if (apMode == 0) {
        setprop("/instrumentation/flightdirector/lnav",0);
      }
      if (lateral == 1) {
	setprop("instrumentation/flightdirector/lnav",LNAV_HDG);
      }
      if (lateral == -1) {
        if (apMode == 1) {
          setprop("instrumentation/flightdirector/lnav",LNAV_FMS);
          if (vnav == VNAV_OPCLB) {
            tracer("change in NAV mode, set CLB");
            setprop("/instrumentation/flightdirector/vnav",VNAV_CLB);
            toggle_alt_select(0);
            toggle_spd_select(0);
          }
          if (vnav == VNAV_OPDES) {
            tracer("change in NAV mode, set DES");
            setprop("/instrumentation/flightdirector/vnav",VNAV_DES);
            toggle_alt_select(0);
            toggle_spd_select(0);
          }
        } else {
          setprop("instrumentation/flightdirector/lnav-arm",LNAV_FMS);
        }
      }
      if (lateral == 0) {
        if (apMode == 1) {
          var currVS = getprop("/instrumentation/vertical-speed-indicator/indicated-speed-fpm");
          setprop("instrumentation/flightdirector/lnav",LNAV_HDG);
          tracer("later: "~lateral~", vnav: "~vnav~" currVS: "~currVS);
          if (vnav == VNAV_CLB) {
            tracer("change in NAV mode, set OPCLB");
            setprop("/instrumentation/flightdirector/vnav",VNAV_OPCLB);
            setprop("/instrumentation/flightdirector/vnav-arm", VNAV_CLB);
            #setprop("/autopilot/settings/vertical-speed-fpm",currVS);
            #toggle_alt_select(0);
          }
          if (vnav == VNAV_DES) {
            tracer("change in NAV mode, set OPDES");
            setprop("/instrumentation/flightdirector/vnav",VNAV_OPDES);
            setprop("/instrumentation/flightdirector/vnav-arm", VNAV_DES);
            #setprop("/autopilot/settings/vertical-speed-fpm",currVS);
            #toggle_alt_select(0);
          }
        } else {
          setprop("instrumentation/flightdirector/lnav-arm",LNAV_HDG);
        }
      }
      setprop("/instrumentation/afs/lateral-mode",lateral);
      setprop("/instrumentation/afs/lateral-display",lateral);
}


toggle_appr = func() {
      if (getprop("/autopilot/locks/altitude") == "gs1-hold") {
        setprop("/instrumentation/flightdirector/vnav",0);
        setprop("/autopilot/locks/altitude","");
      } else {
        if ((getprop("/instrumentation/nav[0]/has-gs") == 1) or (getprop("/instrumentation/nav[1]/has-gs") == 1)) {
            tracer("AFS: nav1 or nav2 has GS");
            setprop("/autopilot/locks/altitude","gs1-hold");
        }
        ## but we'll set the instrumentation anyway. 
	setprop("/instrumentation/flightdirector/vnav",VNAV_GS);
      }

      if (getprop("/autopilot/locks/heading") == "nav1-hold") {
        setprop("/instrumentation/flightdirector/lnav",0);
        setprop("/autopilot/locks/heading","");
      } else {
        if ((getprop("/instrumentation/nav[0]/in-range") == 1) or (getprop("/instrumentation/nav[1]/in-range") == 1)) {
          tracer("AFS: nav1 or nav2 localiser in-range");
          setprop("/autopilot/locks/heading","nav1-hold");
        }
        ## but set instrumentation anyway.
	setprop("/instrumentation/flightdirector/lnav",LNAV_LOC);
      }
}

toggle_spd = func() {
      if (getprop("/autopilot/locks/speed") == "speed-with-throttle") {
	setprop("/instrumentation/flightdirector/at-on",0);
        setprop("/autopilot/locks/speed","");
      } else {
        setprop("/autopilot/locks/speed","speed-with-throttle");
        setprop("/instrumentation/flightdirector/at-on",1);
      }
}

#toggle_hdg_select = func(n) {
#    ap_hdg = getprop("/autopilot/locks/heading");
#    ap_alt = getprop("/autopilot/locks/altitude");
#    hdg_vs_select += n;
#    if (hdg_vs_select < -1) hdg_vs_select = -1;
#    if (hdg_vs_select > 1) hdg_vs_select = 1;
#    tracer("hdg_vs_select: "~hdg_vs_select);
#}

toggle_thrust_detent = func(n) {
   currTim = getprop("/sim/time/elapsed-sec");
   difTime = currTim-detent_repeat_time;
   ###tracer("A/THR detent repeat time: "~difTime);
   if (difTime > 0.268) {
     var currDetent = int(getprop("/instrumentation/flightdirector/athr"));
     #var currThrottle = int(getprop("/controls/engines/engine[0]/throttle"));
     var currThrottle = int(getprop("/controls/engines/engine[0]/thrust-lever"));
     var currFlexThrottle = int(getprop("/instrumentation/afs/flex-throttle"));
     tracer("[afs] start - currDetent: "~currDetent~", currThrottle: "~currThrottle~", curFlexThrottle: "~currFlexThrottle);
     if (currFlexThrottle == nil or currFlexThrottle == 0) {
       currFlexThrottle = throttleRates[2];
     }
     nearDetent = -1;
     if (currThrottle > throttleRates[3]) {
       if (n == -1) {
         nearDetent = 3;
       }
     }
     if (currThrottle > throttleRates[2] and currThrottle < throttleRates[3]) {
       if (n == 1) {
         nearDetent = 3;
       } else {
         nearDetent = 2;
       }
     }
     if (currThrottle > throttleRates[1] and currThrottle < throttleRates[2]) {
       if (n == 1) {
         nearDetent = 2;
       } else {
         nearDetent = 1;
       }
     }
     if (currThrottle < throttleRates[1] and currThrottle > throttleRates[0]) {
       if (n == 1) {
         nearDetent = 1;
       } else {
         nearDetent = 0;
       }
     }
     if (nearDetent != -1) {
       currDetent = nearDetent;
     } else {
       currDetent=currDetent+n;
     }
     if (currDetent > 3) {
       currDetent=3;
     }
     if (currDetent < 0) {
       currDetent=0;
     }
     tracer("[afs] end - currDetent: "~currDetent~", currThrottle: "~currThrottle~", curFlexThrottle: "~currFlexThrottle~", nearDetent: "~nearDetent);
     setprop("/instrumentation/flightdirector/athr",currDetent);
     setprop("/instrumentation/flightdirector/at-on",1);

     curAlt = getprop("/instrumentation/altimeter/indicated-altitude-ft");
     curFlightMode = getprop("/instrumentation/ecam/flight-mode");
     redAlt = getprop("/instrumentation/afs/thrust-reduce-alt");
     accAlt = getprop("/instrumentation/afs/thrust-accel-alt");
     crzAlt = getprop("/instrumentation/afs/thrust-cruise-alt");
     newThrottle = throttleRates[currDetent];
     if (currDetent == 1 and n == -1 and curAlt < crzAlt) {   # down to CL
       tracer("afs: set spd: 3");
       setprop("/instrumentation/flightdirector/spd",SPD_THRCLB);
       var grossWgtKg = getprop("/fdm/jsbsim/inertia/weight-kg");
       if (grossWgtKg > 500000) {
         newThrottle = 0.69;
       }
     }
     if (currDetent == 1 and curAlt >= crzAlt) {   # change to CL when at cruise alt
       tracer("afs: set spd: 6");
       setprop("/instrumentation/flightdirector/spd",6);
     }     
     if (currDetent == 2) {   # FLEX
       flexTempIdx = getprop("/instrumentation/flightdirector/flex-temp");
       var jsbsimGrossWgt = getprop("/fdm/jsbsim/inertia/weight-lbs");
       var grossWgtKg    = jsbsimGrossWgt*0.45359237;
       MTOW = 560000;
       tracer("FLX Gross weight: "~grossWgtKg~"kg MTOW: "~MTOW);
       var loadFactor = ((MTOW-grossWgtKg)/MTOW);
       var altFactor1 = math.pow(34,loadFactor);   # 34 was arrived at by guessing...
       ##var altFactor2 = math.exp(loadFactor);
       newThrottle = ((throttleRates[currDetent]*100)-altFactor1)/100;
       #throttleFactor = (30*loadFactor)/100;
       #tmpThrottle = throttleRates[currDetent]-throttleFactor;
       ##tracer("altFactor1: "~altFactor1~", loadFactor: "~loadFactor~", NEW Throttle: "~newThrottle);
       tracer("FLX loadFactor: "~loadFactor~", logFactor: "~altFactor1~", new throttle: "~newThrottle);
       setprop("/instrumentation/flightdirector/flex-n1-hold",flexTempN1[flexTempIdx]);
       setprop("/instrumentation/afs/flex-throttle",newThrottle);
       tracer("FLX: set N1 % "~flexTempN1[flexTempIdx]);
       tracer("afs: set spd: 2");
       setprop("/instrumentation/flightdirector/spd",SPD_FLEX);
     }
     if (currDetent == 3) {   # TOGA
       setprop("/instrumentation/flightdirector/spd",SPD_TOGA);
     }
     if (currDetent == 0) {
       setprop("/instrumentation/flightdirector/spd",SPD_THRIDL);
     }
     for(e=0; e <4; e=e+1) {
       ##interpolate("/controls/engines/engine["~e~"]/thrust-lever", throttleRates[currDetent], 1);
       setprop("/controls/engines/engine["~e~"]/thrust-lever", throttleRates[currDetent]);
       var curTh = getprop("/controls/engines/engine["~e~"]/throttle");
       tracer("Current Throttle: "~curTh~", set new throttle: "~newThrottle~", engine: "~e~", throttleRate: "~throttleRates[currDetent]);       
       if (currDetent == 1 and n == -1) {
         ##setprop("/controls/engines/engine["~e~"]/throttle",newThrottle);
         interpolate("/controls/engines/engine["~e~"]/throttle",newThrottle, 10);
         tracer("interpolate engine: "~e~" down to newThrottle: "~newThrottle);
       } else {
         setprop("/controls/engines/engine["~e~"]/throttle",newThrottle);
         tracer("set engine: "~e~" to newThrottle: "~newThrottle);
       }
     }
   }
   detent_repeat_time=currTim;
}

adjust_thrust = func(n) {
  tracer("[afs] adjust thrust: "~n);
  setprop("/instrumentation/flightdirector/at-on",0);
  setprop("/instrumentation/flightdirector/spd",0);
  for(var e=0; e < 4; e=e+1) {
    var curTh = getprop("/controls/engines/engine["~e~"]/thrust-lever");
    var inc = (n/100);
    var newThrust = curTh+inc;
    if (newThrust < 0.0) newThrust = 0.0;
    if (newThrust > 1.0) newThrust = 1.0;
    setprop("/controls/engines/engine["~e~"]/thrust-lever", newThrust);
    setprop("/controls/engines/engine["~e~"]/throttle", newThrust);
  }
}

change_radar_range = func(n) {
  var curRange = getprop("/instrumentation/radar/range");
  var newRange = curRange;
  if (n == 1) {
    newRange = curRange*2;
    if (newRange > 640) {
      newRange = 640;
    }
  } else {
    newRange = curRange/2;
    if (newRange < 5) {
      newRange = 5;
    }
  }
  setprop("/instrumentation/radar/range",newRange);
}

###############################################################
## timers to reset display on AFS CP.
###############################################################

time_reset_alt = func(attr) {
  var prop = "/instrumentation/afs/"~attr;
  var curMode = getprop(prop);
  if(timer[attr] == 0) {
    var preProp = "/instrumentation/afs/previous-"~attr;
    setprop(preProp,curMode);
  }
  #tracer("got prop: "~prop~" mode: "~curMode);
  timer[attr] += 1;
  settimer(reset_display_alt,10);
  setprop(prop,0);
}

reset_display_alt = func() {
    attr = "vertical-alt-display";
    timer[attr] -=1;
    if (timer[attr] == 0) {
      mode = getprop("/instrumentation/afs/previous-"~attr);
      if (getprop("/instrumentation/afs/vertical-alt-mode") == 0) {
        mode = 0;
      }
      var prop = "/instrumentation/afs/"~attr;
      #tracer("set prop: "~prop~", with value: "~mode);
      setprop(prop,mode);
    }
}

time_reset_vs = func(attr) {
  var prop = "/instrumentation/afs/"~attr;
  var curMode = getprop(prop);
  if(timer[attr] == 0) {
    var preProp = "/instrumentation/afs/previous-"~attr;
    setprop(preProp,curMode);
  }
  #tracer("got prop: "~prop~" mode: "~curMode);
  timer[attr] += 1;
  settimer(reset_display_vs,10);
  setprop(prop,0);
}

reset_display_vs = func() {
    attr = "vertical-vs-display";
    timer[attr] -=1;
    if (timer[attr] == 0) {
      mode = getprop("/instrumentation/afs/previous-"~attr);
      if (getprop("/instrumentation/afs/vertical-vs-mode") == 0) {
        mode = 0;
      }
      var prop = "/instrumentation/afs/"~attr;
      #tracer("set prop: "~prop~", with value: "~mode);
      setprop(prop,mode);
    }
}

time_reset_hdg = func(attr) {
  var prop = "/instrumentation/afs/"~attr;
  var curMode = getprop(prop);
  if(timer[attr] == 0) {
    var preProp = "/instrumentation/afs/previous-"~attr;
    setprop(preProp,curMode);
  }
  #tracer("got prop: "~prop~" mode: "~curMode);
  timer[attr] += 1;
  settimer(reset_display_hdg,10);
  setprop(prop,0);
}

reset_display_hdg = func() {
    attr = "lateral-display";
    timer[attr] -=1;
    if (timer[attr] == 0) {
      mode = getprop("/instrumentation/afs/previous-"~attr);
      if (getprop("/instrumentation/afs/lateral-mode") == 0) {
        mode = 0;
      }
      var prop = "/instrumentation/afs/"~attr;
      #tracer("set prop: "~prop~", with value: "~mode);
      setprop(prop,mode);
    }
}

time_reset_spd = func(attr) {
  var prop = "/instrumentation/afs/"~attr;
  var curMode = getprop(prop);
  if(timer[attr] == 0) {
    var preProp = "/instrumentation/afs/previous-"~attr;
    setprop(preProp,curMode);
  }
  #tracer("got prop: "~prop~" mode: "~curMode);
  timer[attr] += 1;
  settimer(reset_display_spd ,10);
  setprop(prop,0);
}

reset_display_spd = func() {
    attr = "spd-display";
    timer[attr] -=1;
    if (timer[attr] == 0) {
      mode = getprop("/instrumentation/afs/previous-"~attr);
      if (getprop("/instrumentation/afs/speed-mode") == 0) {
        mode = 0;
      }
      var prop = "/instrumentation/afs/"~attr;
      #tracer("set prop: "~prop~", with value: "~mode);
      setprop(prop,mode);
    }
}



var pow = func(x, y) { 
  math.exp(y * math.ln(x))
}


setlistener("/sim/signals/fdm-initialized", func {
  print("Airbus Auto Flight Control "~afs_version);
});