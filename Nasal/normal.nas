#Created by Ampere 
# ********* ********* ********* ********* ********* ********* ********* ********* ********* *********
#Purpose: 
#approximate the A380's flight control system under normal law.
#
#Brief Description:
#According to http://www.airbusdriver.net/ , the normal law implements the following functions:
#High AOA Protection
#Load Factor Limitation
#Pitch Attitude Protection
#High Speed Protection
#Flight Augmentation (Yaw)
#Bank Angle Protection
#
#implements 3 modes for different phases of flight:
#Ground Mode
#Flight Mode
#Flare Mode
#
#
#Also check out the second last page of the following file for information regarding A340's 
#protection systems: http://pwp.netcabo.pt/carlos.neto/files/A340PROCEDURES.PDF
#
# ********* ********* ********* ********* ********* ********* ********* ********* ********* *********
#Major revision dates:

#January 8, 2005
#
#At time of writing, the aircraft still lacks any flight control system.  We will therefore need to
#have some sort of ways to allow the pilot(s) to control the aircraft.
#
#At this stage, we want to keep things as simple as possible.  Therefore, this revision's objective 
#is to take pilot's commands, process them, and manipulate the control surfaces directly.  We can 
#simulate other essential subsystems at a later stage.


# ********* ********* ********* ********* ********* ********* ********* ********* ********* *********
#January 9, 2005
#A proof of concept test was done on this code using the c182.  The purpose of this test is to prove 
#whether nasal is up to the task of controlling the aircraft.  The specification of the test was that
#the code needs to prevent the aircraft from going outside of its flight envelope.  Dispite its best 
#effort, the code didn't pass the test.  However, nasal's performance as a language proved to be 
#aquadate for the task.
#
#At this stage, the code does the followings:
#. Take pilot's inputs from /controls/flight
#. Take flight's parameters from /sim/orientation
#. Modify inputs when pitch is approaching +30 and -15 degrees
#. Modify inputs when roll is appraoching  +/-67 degrees
#. Put modified inputs back into /controls/flight
#
#Problems:
#. Properties under /orientation seem to have taken on some other odd parameters after extreme
#attitudes.
#. The protection system gone insane when the plane went outside of its flight envelope.  Merely 
#adding corrections is not adquate.
#. Pilot's inputs were processed by the FDM first before outputs were sent to the FDM.  Hence, there
#were arbrut changes in FDM's inputs, and ultimately result in some extreme atitudes.  At this point,
#pilot's extreme inputs in an attempt to correct the attitudes of the aircraft, coupled with the poor
#reliability of the code, escalated the problem.
#
#Recommendations:
#. Take flight's parameters from a different source since there seem to be some anomonies associated
#with the parameters under /orientation.  Beside, taking parameters from /orientation is cheating.
#. Adding corrections (x + y) to the pilot's inputs don't seem to work correctly.  The next revision 
#should use multiplication to scale the pilot's input [(A * B) + C], before adding corrections.
#. Outputs should be placed under some new node, as opposed to placing them under /controls/flight
#. Modifications should be made to the aircraft's FDM configuration file so the FDM will take 
#parameters directly from the aforementioned new node.


# ********* ********* ********* ********* ********* ********* ********* ********* ********* *********
#January 10, 2005
#The recommendations were carry out today.  The code now does the followings:
#. Take inputs from /controls/flight
#. Take flight's parameters from /instrumentation/attitude-indicator.  Curt said that the "anomonies"
#are meant to replicate the effect of gyros' instability after excessive attitudes.  In other words,
#the anomonies are normal behaviours.
#. Multiply pilot's aileron input by a variable {-1 < n < 1} with an intention that the roll-rate
#will slowly decrease to zero as the aircraft's roll approaches +/-67 degrees.
#. Multiply pilot's elevator input by a variable {-1 < n < 1} with an intention that the pitch-rate 
#will slowly decrease to zero as the aircraft's pitch approaches +30 or -15 degrees.
#. Send inputs to /systems/data-buses/outputs
#. FDM now takes inputs from /systems/data-buses/outputs
#
#Problems:
#. The roll didn't stop at 33 degrees, but at 28 degrees (with extremely minor side-stick input).
#. The aircraft "bounced" on the limits.  Its severity is dependent on the amount of side-stick input.
#. When full side stick deflection was given at +/-33 degrees, the aircraft roll pass the limit as
#designed.  When +/-67 degrees are reached, the aircraft "bounced" on the limit again.  Its severity 
#is again dependent on the side-stick input.
#. When the limits are approached, the aircraft's roll rate did not slowly decrease to zero.  Rather, 
#it stops abrutly by a spring type force.
#. No test was performed on the pitch protection subroutines.  However, since the pitch protection
#subroutine is a minor derivative of the roll protection subroutine, similar faults should also be
#presented.
#
#Recommendations:
#. None is reached at this time.
#


# ********* ********* ********* ********* ********* ********* ********* ********* ********* *********
#January 13, 2005
#The problems identified on January 10, 2005 have been reduced.  However,
#. The aircraft still "bounced" on the limits, although it is not as severe as before.
#
#New problems have been identified:
#. Roll control got stucked at -33 degrees.  The pilot cannot bring the aircraft back to level flight
#unless he/she apply a full-right side-stick deflection.  This problem doesn't appear when the 
#aircraft is at +33 degrees bank.
#
#Recommendations:
#It should be noted that on Airbus FBW system and under normal law, roll rate is proportional to 
#side-stick deflection, but inproportional to air speed.  Therefore, the followings need to be 
#implemented:
#. The system should relie more on a feed-back system:
#Instead of manipulating the ailerons directly, the FCS should manipulate the roll-rate.  Utilizing
#feed backs, a seperate subroutine would *reach* the desired roll-rate by incrementing/decrementing 
#the ailerons' deflection; hence carrying out pilot's inputs indirectly.
#. Hard limits should affect the roll-rate instead of pilot's inputs.
#. Similar implementations should be carried out in the pitch control.
#. The code should also maintain zero pitch/roll-rate when there is no (or minimal when the mouse is
#being used) pilot's inputs.
#
#The above implementations present a new ways in thinking, which not only will cause the code to
#behave more similar to Airbus FBW System, but it should also eliminate any jamming issue identified 
#earlier.
# ********* ********* ********* ********* *********
AILERON0_NODE = "/surface-positions/left-aileron-pos-norm";
AILERON5_NODE = "/surface-positions/right-aileron-pos-norm";
ELEVATOR_NODE = "/surface-positions/elevator-pos-norm";

aileron0 = 0;
aileron5 = 0;
elevator0 = 0;


# Process pilot's inputs and modify flight control
# surfaces' positions.
Commands = func{
	if (getprop("/instrumentation/attitude-indicator/FBW-ON") == nil)
	{
		setprop("/instrumentation/attitude-indicator/FBW-ON", 1);
	}

	pitchCMD = getprop("/controls/flight/elevator");
	rollCMD = getprop("/controls/flight/aileron[0]");
	
	elevatorPOS = Pitch(pitchCMD);
	aileronPOS = Roll(rollCMD);
	
	setprop("/systems/data-buses/outputs/aileron", aileronPOS);
	setprop("/systems/data-buses/outputs/elevator", elevatorPOS);
	
	setprop(AILERON0_NODE, aileronPOS);
	setprop(AILERON5_NODE, -aileronPOS);
	setprop(ELEVATOR_NODE, elevatorPOS);
	
	# reschedule next loop.
	settimer(Commands, 0.1);
}

# Determine what mode we are in based on our 
# veritcal speed and alttitude:
mode = func {
	#where we make switch between ground mode and flight mode.
	#We may have undesirable effects with this value later on.
	PHASEBOUNDARY=50; 
	#adjust for slopes.
	MIN_VERTICAL_SPEED=10; 
	
	#adjust for position of radar.
	trueAltitude=(getprop("/position/altitude-agl-ft") - 22.323382);
	#vertical speed.
	verticalSpeed=("/instrumentation/vertical-speed-indicator/indicated-speed-fpm");
	
	phase=1; #always assume we are in flight mode unless proven otherwise.
	
	if (trueAltitude < PHASEBOUNDARY)
	{
		if (verticalSpeed < (MIN_VERTICAL_SPEED * -1))
		{ # flare mode
			phase = 2;
		}
		elsif (verticalSpeed < MIN_VERTICAL_SPEED)
		{ # ground mode
			phase = 0;
		}
	}
	
	return phase;
}

#. Scale pilot's input to 0 as roll approaches +/-67 degrees, thus forming a protection.
Roll = func{
	MAXBANK = 67;
	MIDBANK = 33;	# Maximum bank where the pilot doesn't have to apply full sidestick deflection.
	MAXDIFF = 5;	# How close should the limit be before the computer takes actions.
	
	bank = getprop("/instrumentation/attitude-indicator/indicated-roll-deg");
	absBank = math.sqrt(bank * bank);
	setprop("/instrumentation/attitude-indicator/abs-roll-deg", absBank);
	
	# default bank limit:
	limBank = MIDBANK;
	
	rollCMD = arg[0];
	absRollCMD = math.sqrt(rollCMD * rollCMD);
	
	# override bank limit if necessary.
	if (absBank >= (MIDBANK - MAXDIFF))
	{
		if (absRollCMD >= 0.9)
		{
			limBank = MAXBANK;
		}
	}
	
	diff = limBank - absBank;
	
	# Compute scaling: default is 1 (no correction)
	scale = 1;
	if (diff <= MAXDIFF)
	{
		scale = (diff)/MAXDIFF;
		if (scale < -1)
		{
			print ("roll protection: countering roll");
			scale = -1;
		}
		if (scale > 1 )
		{
			print ("roll protection: reducing roll");
			scale = 1;
		}
	}
	
	# Compute output:
	output = rollCMD * scale;
	
	# extreme case: apply correction if the aircraft is exceeding the flight envelope.
	if (absBank > limBank)
	{
		# Output is always opposite of current bank.
		output = (bank / absBank) * scale;
	}
	
	if (getprop("/instrumentation/attitude-indicator/FBW-ON") < 1)
	{	output = rollCMD;}
	return output;
}

GProt = func{
	glimit = 2.5;

}

Pitch = func{
	MAXDIFF = 5;
	MAXPITCH = 30;
	MINPITCH = -15;
	
	# Default pitch limit:
	limPitch = MAXPITCH;
	
	pitch = getprop("/instrumentation/attitude-indicator/indicated-pitch-deg");	
	absPitch = math.sqrt(pitch * pitch);
	
	pitchCMD = arg[0];
	# within the flight enevelope, diff is always positive.
	if (pitch < 0)
	{
		diff = MAXPITCH - pitch;
	}
	else
	{
		diff = pitch - MINPITCH;
	}
	
	# Compute scaling: default is 1 (no correction)
	scale = 1;
	if (diff <= MAXDIFF)
	{
		scale = (diff)/MAXDIFF;
		if (scale < -1)
		{
			scale = -1;
			print ("pitch protection: counter pitch");
		}
		if (scale > 1)
		{
			scale = 1;
			print ("pitch protection: reducing pitch");
		}
	}	

	# Compute output:
	output = pitchCMD * scale;
	
	# extreme case: apply correction if the aircraft is exceeding the flight envelope.
	if (absPitch > limPitch)
	{
		# Output is always opposite of the current pitch.
		output = (pitch / absPitch) * scale;
	}
	
	if (getprop("/instrumentation/attitude-indicator/FBW-ON") < 1)
	{	output = pitchCMD;}
	
	
	return output;
}