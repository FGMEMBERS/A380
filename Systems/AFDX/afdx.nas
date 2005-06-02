# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# This nasal script defines the AFDX system (including the AFDX buses) of the A380.
# 
# The AFDX system of the A380 is seperated into four domains:
# Cockpit domain
# * encompasses avionics functions
# * involves with interfacing with primary displays
# * comprises of four IMA cabinets
#
# Cabin domain
# * associates with functions associated with the passenger cabin
# * comprises of two IMA cabinets
# * contains two afdx switches
#
# Energy domain
# * associates with electrical and hydraulical power, as well as bleed air control
# * comprises of two IMA cabinets
#
# Utility domain
# * assoiates with landing gears control, fuel system, and steering.
# * comprises of two IMA cabinets
#
# Each domain has two afdx switches.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********

Network = {
	# Defines the AFDX system and put it on to the global name space.
	create : func{
		# Create switches and put them on to the global name space.
		globals.switch1 = Switch.new("cockpit_sw_1");
		globals.switch2 = Switch.new("cockpit_sw_2");
		
		# Misc.
		switch1.setVerbose(2);
		switch2.setVerbose(2);
		switch1.update();
		switch2.update();
		
		# Create buses and put them on to the global name space.
		globals.bus01 = Bus.new();
	},
	
	# Connect the switches using buses.
	makeConnections : func{
		switch1.connect(bus01, 0);
		switch2.connect(bus01, 0);
	}
};