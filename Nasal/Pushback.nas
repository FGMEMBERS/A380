togglepushback = func {
p1 = "/engines/engine[4]";
p2 = "/fdm/jsbsim/propulsion/engine[4]";
p3 = "/engines/engine[4]"; 
#p4 = "/controls/engines/engine[2]"; 
#p5 = "/sim/input/selected";
pv1 = "/engines/engine[4]/pushback"; 


val = getprop(pv1);
if (val == 0 or val == nil) {
interpolate(pv1, 1.0, 1.4); 
#interpolate(rv2, 1.0, 1.4);  
setprop(p1,"running","true");
setprop(p2,"thrust","8000");
setprop(p3,"cutoff","false");
#setprop(r4,"reverser", "true");
#setprop(r5,"engine", "false");
#setprop(r5,"engine[1]", "true");
#setprop(r5,"engine[2]", "true");
#setprop(r5,"engine[3]", "false");
} else {
if (val == 1.0){
interpolate(pv1, 0.0, 1.4);
#interpolate(rv2, 0.0, 1.4);   
setprop(p1,"running","false");
setprop(p2,"thrust","0");
#setprop(r3,"reverser",0);
#setprop(r4,"reverser",0);
#setprop(r5,"engine", "true");
#setprop(r5,"engine[1]", "true");
#setprop(r5,"engine[2]", "true");
#setprop(r5,"engine[3]", "true");

  }
 }
}
