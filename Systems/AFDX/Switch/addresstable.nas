# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# addresstable.nas
# This Nasal script implements the address table of the afdx switch.
# 
# Class:
#  AddressTable
#  	Methods:
#  	 new()				# Creates and returns a new address table.
#  	 add(address, portNum, expTime) # Creates a new entry in the address table.
#  	 find(address)			# Returns the port number that is associated with the given address.
#  	 update()			# Checks the current time and removes old entries if necessary.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
AddressTable = {
# Sub-classes:
	Comparator : {
		compare : func(key1, key2){
			if (streq(key1, key2)){
				return 0;
			}
			elsif (key1 < key2){
				return -1;
			}
			else{
				return 1;
			}
		}
	},
	
	TimeStamp : {
		# Returns a new time stamp.
		new : func(e, t){
			obj = {};
			obj.parents = [AddressTable.TimeStamp];
			
			# Instance varaibles:
			obj._element = e;
			obj._time = t;
			
			return obj;
		},
		
		# Returns the element being time stamped.
		element : func{
			return me._element;
		},
		
		# Returns the expiary time.
		time : func{
			return me._time;
		}
	},
	
# Methods:
	# Creates a new instance of an address table.
	new : func{
		obj = {};
		obj.parents = [AddressTable];
		
		# Instance variables:
		obj._database = BinarySearchTree.new(me.Comparator);	# Use a Binary Search Tree to store
									#  entries.
		obj._timeStamps = Queue.new();				# Use a queue to store time stamps.
		
		return obj;
	},
	
	# Adds an entry to the address table.
	add : func(address, portNum, expTime){
		# Insert the entry into the binary search tree.
		v = me._database.insert(address, portNum);
		
		if (v == nil){
			# Insertion failed.  Aborting.
		}
		else {
			# Give the address a time stamp.
			ts = TimeStamp.new(address, expTime);
			me._timeStamps.enqueue(ts);
		}
	},
	
	# Returns the port number that is associated with the given address.
	find : func(address){
		ent = me._database.find(address);
		
		if (ent == nil){
			# Nothing found.
			return nil;
		}
		else {
			# Return the port number.
			return me._database.getElement(ent);
		}
	},
	
	# Performs a check on the current time and removes entries if necessary.
	update : func{
		# Get time from /sim/time/elapsed-sec[0].
		curTime = props.globals.getNode("/sim/time/elapsed-sec[0]").getValue();
		
		# Take a peek at the queue.  If the time stamp indicates that the object has expired, perform
		#  dequeue operation and remove the associated node from the binary search tree.
		while (curTime > me._timeStamps.front().time()){
			# Entry expired.  Perform removals.
			address = me._timeStamps.dequeue().element();
			ent = me._database.find(address);
			me._database.remove(ent);
		}
	}
};
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********