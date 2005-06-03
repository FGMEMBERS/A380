# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# switch.nas
# This Nasal script simulates an ethernet switch.
# 
# Class:
#  Switch
#  	Methods:
#  	 new(name)		- creates and returns an instance of the switch object, with the specified name
#  	 			   as the identifier.
#  	 connect(bus, portID)	- connects the specified bus to the port with the given port ID.  Returns the 
#  	 			   modified bus if successful and returns null otherwise.
#  	 disconnect(bus, portID)- disconnects the specified bus from the given port.  Returns the modified bus
#  	 			   if the operation is successful and returns null otherwise.
#  	 getBpduMaxAge()	- returns the maximium age that this switch will keep a BPDU message.
#  	 getForwardDelay()	- returns the amount of time that the switch will stay at the listening or
#  	 			   learning state.
#  	 getHelloTime() 	- returns the time interval between each sending of a BPDU message.
#  	 getMacAddress()	- returns the MAC Address of this switch.
#  	 getPriority()		- returns the priority this switch is having.
#  	 setBpduMaxAge(age)	- specifies the maximium time that the switch will keep a BPDU message.
#  	 setForwardDelay(delay) - specifies the time that the switch will stay at the listening or learning
#  	 			   state.
#  	 setHelloTime(interval) - specifies the time interval between each BPDU broadcast.  (Applicable only if
#  	 			   this switch is also the root.)
#  	 setPriority(priority)	- sets the priority of this switch.
#  	 setVerbose(state)	- specifies the verbosness of the switch, with:
#  	 			  * 0 being silent.
#  	 			  * 1 generates warning messages only.
#  	 			  * 2 generates warning messages and generic debug messages.
#  	 			  * 3 generates warning messages, generic debug messages, and specific debug
#  	 			       messages.
#  	 update()		- this is the function to call for the switch to run through a cycle.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
Switch = {
# Sub-class:
	comparator : {
		# Compare two strings as if they are base256 values.
		compare : func(val1, val2){
			if (size(val1) > size(val2)){
				return 1;
			}
			elsif (size(val1) < size(val2)){
				return -1;
			}
			
			i = 0;
			while (i < size(val1) and strc(val1, i) == strc(val2, i)){
				i = i + 1;
			}
			
			if (i >= size(val1) - 1){
				return 0;
			}
			elsif (strc(val1, i) < strc(val2, i)){
				return -1;
			}
			elsif (strc(val1, i) > strc(val2, i)){
				return 1;
			}
			else {
				return 0;
			}
		}
	},

# Methods:
	# Creates a new instance of the switch object.
	new : func(name){
		warning = 0;
		
		obj = {};
		obj.parents = [Switch];
		
		# Return null if name is null.
		if (size(name) == 0 or name == nil){
			print ("Warning in switch.nas: unable to create switch");
			print ("\t Reason: no name was given to the switch.");
			warning = warning + 1;
			return nil;
		}
		
		# Remove all slashes in name.
		parsed = "";
		for (i = size(name) - 1; i >= 0; i = i - 1){
			tmp = substr(name, i, 1);
			if (tmp == "/"){
				if (warning == 0){
					print ("Warning in switch.nas: Switch.new(name) expects a name, not a property.");
					print ("\t Slashes in 'name' were removed.");
				}
				warning = warning + 1;
			}
			else
			{
				tmp = substr(name, i, 1);
				
				if (tmp == nil){
					print ("Error while creating Switch " ~ name ~ ": substr(name, " ~ i ~ 
					", 1) returns null in string '" ~ name ~ "'.");
				}
				parsed = tmp ~ parsed;
			}
		}
		name = parsed;
		
		# Instance variables:
		obj._address = chr(0) ~ chr(6) ~ chr(207);	# 00 06 CF RAND RAND RAND
		obj._address = obj._address ~ chr(rand() * 255) ~ chr(rand() * 255) ~ chr(rand() * 255);
		
		obj._addressTable = AddressTable.new();
		obj._cost = 19;
		obj._multicast = chr(01) ~ chr(80) ~ chr(194) ~ chr(0) ~ chr(0) ~ chr(0);	# 01 80 C2 00 00 00
		obj._name = name;
		obj._nextBPDU = 0;	# The next BPDU sending time.
		obj._occupiedPorts = [];
		obj._ports = [];
		
		obj._priority = decToAscii(32768);	# 32768
		obj._rootPort = -1;
		obj._verboseState = 1;
		
		# BPDU related:
		obj._dynamicBpdu = nil;
		obj._dynamicBpduExpiry = 0;
		
		obj._staticBpdu = BPDU.new("");
		obj._staticBpdu.setBridgeID(obj._priority ~ obj._address);	# Bridge ID.
		obj._staticBpdu.setForwardDelay(15);				# Forward delay timer.
		obj._staticBpdu.setHelloTime(2);				# Hello interval.
		obj._staticBpdu.setMaxAge(20);					# Maximium age of bpdu messages.
		obj._staticBpdu.setRootID(obj._priority ~ obj._address);	# Root ID.
		obj._staticBpdu.setMessageAge(0);				# Message age.
		obj._staticBpdu.setRootPathCost(0);				# Root path cost.
		
		# Flags for Topology Change:
		obj._broadcastTC  = 0;
		obj._broadcastTCA = 0;
		obj._broadcastTCN = 0;
		obj._stopTCbroadcast = 0;	# When to stop TC broadcasting.
		
		return obj;
	},
	
	# Connects the specified bus to the port with the given port ID.
	connect : func(bus, portID){
		# Validate arguments.
		if (bus == nil or portID == nil){
			me.echo ("Warning in Switch " ~ me._name ~ ": invalid argument given to " ~
				"connect(bus, portID).  Aborting.", 1);
			return nil;
		}
		
		# Check the port's existance.
		if (portID >= size(me._ports)){
			me.echo ("Warning in Switch " ~ me._name ~ ": cannot connect bus to " ~ 
				"port[" ~ portID ~ "].  Aborting.", 1);
			me.echo ("\t Reason: port[" ~ portID ~ "]" ~ "does not exist.", 2);
			return nil;
		}
		
		# Check whether the port is available.
		if (me._occupiedPorts[portID] == 1){
			me.echo ("Switch " ~ me._name ~ ": cannot connect bus to port[" ~ portID ~ 
				"] because the port is already occupied.", 2);
			return nil;
		}
		
		p = bus.connect(me._ports[portID]);
		
		if (p == nil){
			me.echo ("Switch " ~ me._name ~ ": failed to connected bus to port[" ~ portID ~ "].", 2);
			return nil;
		}
		else {
			me.echo ("Switch " ~ me._name ~ ": successfully connected bus to port[" ~ portID ~ "].", 2);
			me._occupiedPorts[portID] = 1;
		}
		
		return bus;
	},
	
	disconnect : func(bus, portID){
		# Validate arguments.
		if (bus == nil or portID == nil){
			me.echo ("Warning in Switch " ~ me._name ~ ": invalid argument given to " ~
				"disconnect(bus, portID).  Aborting.", 1);
			return nil;
		}
		
		# Check the port's existance.
		if (portID >= size(me._ports)){
			me.echo ("Warning in Switch " ~ me._name ~ ": cannot disconnect bus from " ~ 
				"port[" ~ portID ~ "].  Aborting.", 1);
			me.echo ("\t Reason: port[" ~ portID ~ "]" ~ "does not exist.", 2);
			return nil;
		}
		
		# Check whether the port is occupied.
		if (me._occupiedPorts[portID] == 0){
			me.echo ("Switch " ~ me._name ~ ": cannot remove bus from port[" ~ portID ~ 
				"] because the port is not occupied.", 2);
			return nil;
		}
		
		p = bus.disconnect(me._ports[portID]);
		
		if (p == nil){
			me.echo ("Switch " ~ me._name ~ ": failed to disconnected bus from port[" ~ portID ~ "].", 2);
			return nil;
		}
		else {
			me.echo ("Switch " ~ me._name ~ ": successfully disconnected bus from port[" ~ portID ~ "].", 2);
			me._occupiedPorts[portID] = 0;
		}
		
		return bus;
	},
	
	init : func{
		MAX_PORTS = 04; 	# Maximium number of ports.
		
		# Initialize nodes on the property tree for this switch.
		me.initProp("/systems/afdx/switch/" ~ me._name ~ "/mac-address");
		me.initProp("/systems/afdx/switch/" ~ me._name ~ "/is-root");
		
		# Create ports and return them in a vector.
		ports = [];
		
		for (i=0; i<MAX_PORTS; i=i+1){
			append(ports, SwitchPort.new(i, "/systems/afdx/switch/" ~ me._name ~ "/ports/port[" ~ i ~ "]"));
			ports[i].setVerbose(me._verboseState);
		}
		
		return ports;
	},
	
	# Creates the specified node on the global property tree if it doesn't exist.
	initProp : func(prop){
#		# Initialize nodes on the property tree recursively.
#		tmp = props.globals.getNode(prop ~ "/" ~ node);
#		
#		if (tmp == nil){
#			pt = size(prop) - 1;
#			for (; pt > 1; pt = pt - 1){
#				if (substr(prop, pt, 1) == "/"){ break; }
#			}
#			if (pt > 0){
#				parent = substr(prop, 0, pt);
#				child = substr(prop, pt + 1);
#				tmp = me.initProp(parent, child);
#			}
#		}
#		setprop(prop, node, nil);
#		
#		return props.globals.getNode(prop ~ "/" ~ node);
		return props.globals.getNode(prop, 1);
	},
	
	# Accessors:
	
	# Returns the maximium age of bpdu messages.
	getBpduMaxAge : func{
#		return me._bpduMaxAge;
		return me._staticBpdu.getMaxAge();
	},
	
	# Returns the forward delay time.
	getForwardDelay : func{
#		return me._forwardDelay;
		return me._staticBpdu.getForwardDelay();
	},
	
	# Returns the hello interval.
	getHelloTime : func{
#		return me._helloTime;
		return me._staticBpdu.getHelloTime();
	},
	
	# Returns the switch's mac address in human readable format.
	getMacAddress : func{
		hexOut = "";
		
		# Go through each character in the address and convert it to a hexadecimal value.
		for (i=0; i<size(me._address); i=i+1){
			tmp = decToHex(strc(me._address, i));
			if (size(tmp) < 2){
				tmp = "0" ~ tmp;
			}
			hexOut = hexOut ~ tmp;
			
			if (i + 1 < size(me._address)){
				hexOut = hexOut ~ ":";
			}
		}
		
		return hexOut;
	},
	
	# Returns the switch's priority.
	getPriority : func{
		return asciiToDec(me._priority);
	},
	
	# Modifiers:
	
	# Sets the maximium age for bpdu messages.
	setBpduMaxAge : func(age){
#		me._bpduMaxAge = age;
		me._staticBpdu.setMaxAge(age);
	},
	
	# Sets the forward delay timer to the specified value.
	setForwardDelay : func(delay){
#		me._forwardDelay = delay;
		me._staticBpdu.setForwardDelay(delay);
	},
	
	# Sets the hello time interval.
	setHelloTime : func(interval){
#		me._helloTime = interval;
		me._staticBpdu.setHelloTime(interval);
	},
	
	# Sets the switch's priority.
	setPriority : func(priority){
		me._priority = decToAscii(priority);
		
		while(size(me._priority) < 2){
			me._priority = chr(0) ~ me._priority;
		}
	},
	
	# Modifies the verbose state.
	setVerbose : func(state){
		# State 0: Silent.
		# State 1: Warning messages only.
		# State 2: Warning + Generic Debug messages.
		# State 3: Warning + Generic Debug + Specific Debug messages.
		me._verboseState = state;
	},
	
	# Misc. functions:
	
	# Write a BPDU message to each port.
	broadcastBPDU : func{
		foreach (port ; me._ports){
			state = port.update();
			
			# Decide whether to send a BPDU message or block the port.
			newBPDU = nil;
			
			# Block this port if it is a redundent connection to the root.
			if ((port.getID() == me._rootPort) == 0 and (port.lastBPDU() == nil) == 0){
				newBPDU = me.compareBPDU(port.lastBPDU(), 0);
			}
			
			if (newBPDU == nil){
				if (state >= 3){
					# Functions for state 3 (learning) or higher.
					
					#  One function is not performed while writing.
					
					if (port.getID() == me._rootPort){
						# This is a root port, so don't send out any BPDU from this port
						#  unless the BPDU is a TCN.
						if (me._broadcastTCN){
print ("sending TCN");
							outgoingBPDU = BPDU.new("");
							outgoingBPDU.forceTCN();
							
							llc = LLC.new("");
							llc.setControl(0);
							llc.setDSAP(0);
							llc.setSSAP(0);
							llc.setData(outgoingBPDU.toString());
							
							outgoingFrame = Frame.new("");
							outgoingFrame.setDestination(me._multicast);
							outgoingFrame.setSource(me._address);
							outgoingFrame.setData(llc.toString());
							
							# Enqueue the BPDU message into the port's outgoing buffer.
							port.enqueue(outgoingFrame.toString());
							
							
							
							me.echo ("\t Port " ~ port.getID() ~ ": sent out TCN.", 2);
						}
						else{
						
						
							me.echo ("\t Port " ~ port.getID() ~ ": cannot send BPDU to root port.", 2);
						}
					}
					else {
						# The last BPDU received was inferior.  Send out BPDU from this port.
						
						# Encapsulate the bpdu into the llc, then encapsulate the llc into a
						#  standard ethernet frame.  Convert the ethernet frame to a string,
						#  then save the string in the port's output buffer:
						
						# Set up broadcast address.
						destination = me._multicast;
						
						# Copy BPDU.
						outgoingBPDU = BPDU.new(me._dynamicBpdu.toString());
						outgoingBPDU.setBridgeID(me._staticBpdu.getBridgeID());
						
						# If both broadcastTC and broadcastTCA are raised, send out TCA first.
						if (me._broadcastTCA){
print ("sending TCA");
							outgoingBPDU.forceTCA();
							# Lower flag.
							me._broadcastTCA = 0;
						}
						elsif (me._broadcastTC){
print ("sending TC");
							outgoingBPDU.forceTC();
						}
						
						# Let's assume everything in LLC are 0 for now, because I do not know
						#  how LLC works.
						llc = LLC.new("");
						llc.setControl(0);
						llc.setDSAP(0);
						llc.setSSAP(0);
						llc.setData(outgoingBPDU.toString());
						
						outgoingFrame = Frame.new("");
						outgoingFrame.setDestination(destination);
						outgoingFrame.setSource(me._address);
						outgoingFrame.setData(llc.toString());
						
						# Enqueue the BPDU message into the port's outgoing buffer.
						port.enqueue(outgoingFrame.toString());
						
						
						
						me.echo ("\t Wrote BPDU to port " ~ port.getID() ~ ".", 2);
					}
				}
				else {
					me.echo ("\t No BPDU was sent.", 2);
					me.echo ("\t\t Reason: Port's current state does not permit the transmission" ~
						" of BPDU's.", 3);
				}
			}
			else {
				# The last BPDU received was superior.  Block this port.
				port.changeState(1);
				
				# Notify others of topology change.
				me._broadcastTCN = 1;
				
				
				
#				me.echo ("\t Port " ~ port.getID() ~ ": Outgoing BPDU is inferior.  Port " ~ 
#					port.getID() ~ " is blocked.", 3);
				me.echo ("\t Port " ~ port.getID() ~ ": redundent connection to root detected.  " ~
					"Port " ~ port.getID() ~ " is blocked.", 3);
			}
		}
	},
	
	# me.echo a string message according to the current verbose state.
	echo : func(message, verbose){
		if (me._verboseState == 0){
			# Do nothing.
			return nil;
		}
		elsif (verbose <= me._verboseState){
			print (message);
		}
	},
	
	update : func{
		# Flag:
		forwardBPDU = 0;
		# Instance variables:
		outgoing = Queue.new();
		fromPort = Queue.new();
		
		# Get time from /sim/time/elapsed-sec[0].
		curTime = props.globals.getNode("/sim/time/elapsed-sec[0]").getValue();
		
		# Initialize props if they haven't been initialized already.
		if (size(me._ports) == 0){
			me._ports = me.init();
			
			
			
			
			me.echo ("Switch " ~ me._name ~ " is initializing... " ~ 
				size(me._ports) ~ " ports initialized.", 2);
				
			foreach (port ; me._ports){
				port.setForwardDelay(me.getForwardDelay());
				port.setMaxAge(me.getBpduMaxAge());
				
				append(me._occupiedPorts, 0);
			}
			
			# Write switch's MAC Address to the property tree.
			addressReadable = me.getMacAddress();
			props.globals.getNode("/systems/afdx/switch/" ~ me._name ~ "/mac-address").setValue(addressReadable);
			
			
			
			me.echo ("Switch " ~ me._name ~ " was given the address " ~ addressReadable ~ ".", 2);
		}
		
		# Reset BPDU and update other variables.
		if (curTime >= me._dynamicBpduExpiry){
			me._dynamicBpdu = BPDU.new(me._staticBpdu.toString());
			me._dynamicBpduExpiry = curTime + me.getBpduMaxAge();
		}
		# Reset TC broadcasting flag.
		if (me._broadcastTC = 1 and curTime >= me._stopTCbroadcast){
			me._broadcastTC = 0;
		}
		# Update address table.
		me._addressTable.update();
		
		
		
#		me.echo ("Switch " ~ me._name ~ ": reading input buffer.", 2);
		
		# Cycle through all ports and read their buffer.
		foreach (port ; me._ports){
			# Get port state.
			state = port.update();
			
			# Read buffer if port is not disabled.
			if (state == -1){
				# Disabled -- do nothing.
				
				
				
				me.echo ("\t Port " ~ port.getID() ~ " is disabled.", 3);
			}
			else {
				# Dequeue messages from the buffer, convert them into frame objects, then do 
				#  our things.
				while (port.noIncoming() == 0){
					# Flag.
					wasBPDU = 0;
					
					
					
					me.echo ("Switch " ~ me._name ~ ":", 3);
					me.echo ("\t Reading port " ~ port.getID() ~ "...", 3);
					
					# Retreive a frame from the port's input buffer.
					frame = Frame.new(port.dequeue());
					
					# Check for TC, TCA, or TCN frames.
					if ((port.lastBPDU() == nil) == 0){
						if (port.lastBPDU().isTC()){
print ("received TC");
							# Reduce aging time to ForwardDelay for a 
							#  period of MaxAge + ForwardDelay.
							me._dynamicBpdu.setMaxAge(me._dynamicBpdu.getForwardDelay());
						}
						elsif (port.lastBPDU().isTCN()){
print ("received TCN");
							# Raise flags.
							me._broadcastTC = 1;
							me._broadcastTCA = 1;
							# Suppose we are going to broadcast TC messages, 
							#  calculate stopping time.
							me._stopTCbroadcast = curTime + me._dynamicBpdu.getForwardDelay() + me._dynamicBpdu.getMaxAge();
						}
						elsif (port.lastBPDU().isTCA()){
print ("received TCA");
							# Lower flag.
							me._broadcastTCN = 0;
						}
					}
					
					if (state >= 1){
						# Functions for state 1 (blocking) and above.
						dest = frame.getDestination();
						
						# Extract BPDU message if the destination address matches our
						#  multicast address.
						if (me.comparator.compare(dest, me._multicast) == 0){
							wasBPDU = 1;
							
							# Filter out inferior BPDU's by calling compareBPDU().
							newBPDU = me.compareBPDU(port.lastBPDU(), 0);
							
							if ((newBPDU == nil) == 0){
								# Raise a flag to remind the switch to forward BPDU.
								forwardBPDU = 1;
								
								newBPDU = me.compareBPDU(newBPDU, 0);
								if ((newBPDU == nil) == 0){
									me.echo ("\t Received a superior BPDU message.", 2);
									
									me.echo ("Switch " ~ me._name ~ " lost root status.", 2);
									
									# Calculate a new BPDU.
									me._dynamicBpdu = BPDU.new(newBPDU.toString());
									me._dynamicBpdu.setBridgeID(me._staticBpdu.getBridgeID());
									me._dynamicBpdu.setMessageAge(newBPDU.getMessageAge() + 1);
									me._dynamicBpdu.setRootPathCost(newBPDU.getRootPathCost() + me._cost);
									me._dynamicBpduExpiry = curTime + me.getBpduMaxAge();
									
									# Remember this port as the root port.
									me._rootPort = port.getID();
									
									
									
									
									me.echo ("\t\t New BPDU is calculated.", 3);
								}
								else {
									me.echo ("\t Received the same BPDU message.", 2);
									
									# Maintain current status.
									me._dynamicBpduExpiry = curTime + me.getBpduMaxAge();
								}
							}
							else {
								me.echo ("\t Received an inferior BPDU message.", 2);
								me.echo ("Switch " ~ me._name ~ " retained root status.", 2);
								forwardBPDU = 0;
							}
						}
					}
					if (state >= 2){
						# Functions for state 2 (listening) and above.
						
						#  Nothing is performed while reading.
					}
					if (state >= 3){
						# Functions for state 3 (learning) and above.
						
						#  One function is not performed while reading.
						
						# Memorize the source address.
						tmp = me._addressTable.add(frame.getSource(), port.getID(), 
							curTime + me._dynamicBpdu.getForwardDelay());
						
						
						
						if (tmp == nil){
							me.echo ("\t Failed to add new address to the address table.", 2);
							me.echo ("\t\t Reason: may be the address table already contains the entry.", 3);
						}
						else {
							me.echo ("\t Updated the address table.", 2);
							me.echo ("\t\t Address Table now contains " ~ me._addressTable.size() ~ 
								" entries.", 3);
						}
					}
					if (state >= 4){
						# Functions for state 4 (forwaring).
						
						# Put frames into the outgoing buffer and remember from which
						#  port the message was received.
						if (wasBPDU == 0){
							outgoing.enqueue(frame);
							fromPort.enqueue(port.getID());
						
						
						
							me.echo ("\t Received a frame and placed it in the outgoing buffer.", 2);
						}
					}
					if (wasBPDU){
						wasBPDU = 0;
					}
				}
			}
		}
		
		
		
		
#		me.echo ("Switch " ~ me._name ~ ": writing output buffer.", 2);
		
		# Process outgoing messages.
		while (outgoing.isEmpty() == 0){
			# Using the destination address, compute a list of ports using the entries in our
			#  address table.  Write frames to these ports' output buffer if their port-state
			#  permitted.
			
			frame = outgoing.dequeue();
			destination = frame.getDestination();
			entry = me._addressTable.find(destination);
			portID = nil;
			if ((entry == nil) == 0){
				portID = entry.getElement();
			}
			preventPort = fromPort.dequeue();
			
			# Setup a list of ports to send message to.
			ports = [];
			if (portID == nil){
				# The specified destination was not found.  Perform flooding.
				ports = me._ports;
				
				
				
				me.echo("\t Address not found, flooding ports...", 3);
			}
			else {
				# The specified destination was found.
				append(ports, me._ports[portID]);
				
				
				
				me.echo("\t Writing to port " ~ portID ~ "...", 3);
			}
				
			foreach (port ; ports){
				# Check port's state.
				state = port.update();
				
				if (state >= 4){
					# Functions for state 4 (forwarding).
					
					# Enqueue message to the port's outgoing buffer only if the message
					#  was from another port.
					if ((port.getID() == preventPort) == 0){
						port.enqueue(frame.toString());
					}
				}
			}
		}
		
		# Broadcast BPDU message.
		if (me.comparator.compare(me._dynamicBpdu.getRootID(), me._staticBpdu.getRootID()) == 0){
			# This switch is the root switch.
			
			# Broadcast BPDU when it is time.
			if (curTime > me._nextBPDU){
				
				
				me.echo ("Switch " ~ me._name ~ ": attempting to broadcast BPDUs...", 2);
				
				me.broadcastBPDU();
				
				# Schedule next BPDU message.
				me._nextBPDU = curTime + me._staticBpdu.getHelloTime();
			}
			
			# Write switch's info to the property tree.
			props.globals.getNode("/systems/afdx/switch/" ~ me._name ~ "/is-root").setBoolValue(1);
		}
		else {
			# This switch is not the root switch, so just forward BPDUs.
			
			
			if (forwardBPDU){
				me.echo ("Switch " ~ me._name ~ ": attempting to forward BPDUs...", 2);
				
				me._broadcastTC = 0;
				me.broadcastBPDU();
				
				# Schedule next BPDU message.
				me._nextBPDU = curTime + me._dynamicBpdu.getHelloTime();
			}
			
			# Write switch's info to the property tree.
			props.globals.getNode("/systems/afdx/switch/" ~ me._name ~ "/is-root").setBoolValue(0);
		}
	},
	
	# Auxiliary methods:
	
	# Returns a newly calculated BPDU if the specified BPDU is better than the dynamic one.  Returns null
	#  otherwise.
	# The Mode argument indicates when the comparasion should stop.  The modes are as follow:
	# - 0 : don't stop until we have performed every comparsion.
	# - 1 : stop after we have compared the root ID's.
	# - 2 : stop after we have compared the root-path costs.
	# When early termination of this function is evoked before difference is found between the BPDU's,
	#  the specified BPDU and the dynmaic BPDU will be treated as the same, and the dynamic BPDU will be 
	#  returned.
	compareBPDU : func(bpdu, mode){
		
		# Skip if BPDU is null.
		if (bpdu == nil){
			me.echo ("Warning in Switch " ~ me._name ~ ": bpdu passed to compareBPDU(bpdu, mode)" ~
				" cannot be null.  Aborting.", 1);
			return nil;
		}
		
		# First, make sure we were not sending out and receiving our own BPDU's.  Do a check on 
		#  the sender's BridgeID.
		bridgeIDdiff = me.comparator.compare(bpdu.getBridgeID(), me._dynamicBpdu.getBridgeID());
		if (bridgeIDdiff == 0){
			return nil;
		}
		
		# Instace varaibles:
		curMode = 0;
		
		updated = 0;
		
		newBPDU = BPDU.new(bpdu.toString());
		
		# Determine which BPDU is better by comparaing the rootID's first.  If the rootIDs from both
		#  BPDU are equivilent, tie break by doing a comparasion on the root-path cost.  Do a final tie
		#  break using port id if the root-path cost from both bpdu's are the same.
		
		rootIDdiff = me.comparator.compare(bpdu.getRootID(), me._dynamicBpdu.getRootID());
		if (rootIDdiff < 0){
#			newBPDU.setRootID(bpdu.getRootID());
			
			return newBPDU;
		}
		elsif (rootIDdiff > 0){
			return nil;
		}
		
		curMode = curMode + 1;
		if (curMode > mode){ return me._staticBpdu;}
		
		rootpathDiff = me.comparator.compare(bpdu.getRootPathCost(), me._dynamicBpdu.getRootPathCost());
		if (rootpathDiff < 0){
#			newBPDU.setRootPathCost(bpdu.getRootPathCost());
			
			return newBPDU;
		}
		elsif (rootpathDiff > 0){
			return nil;
		}
		
		curMode = curMode + 1;
		if (curMode > mode){ return me._dynamicBpdu;}
		
		portIDdiff = me.comparator.compare(bpdu.getPortID(), me._dynamicBpdu.getPortID());
		if (portIDdiff < 0){
#			newBPDU.setRootID(bpdu.getRootID());
		
			return newBPDU;
		}
		elsif (portIDdiff > 0){
			return nil;
		}
		
		curMode = curMode + 1;
		
		# There are no differences between the BPDU's, so return this dynamic BPDU to indicate that
		#  the BPDU's being compared are the same.
		return me._dynamicBpdu;
	}
}
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********