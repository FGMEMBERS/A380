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
#  	 size()				# Returns the number of entries stored in the address table.
#  	 update()			# Checks the current time and removes old entries if necessary.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
AddressTable = {
# Sub-classes:
	Comparator : {
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
		obj._entries = 0;					# Number of entries in the table.
		obj._timeStamps = Queue.new();				# Use a queue to store time stamps.
		
		return obj;
	},
	
	# Auxiliary functions:
	
	# Extract element from time stamp.
	element : func(ts){
		return ts.element();
	},
	
	# Extract time from time stamp.
	time : func{
		return ts.time();
	},
	
	# Other functions:
	
	# Adds an entry to the address table.
	add : func(address, portNum, expTime){
		# Initialize binary search tree if this is the first run.
		if (me._database.isEmpty()){
			me._database.setRoot(nil);
		}
		
		# Insert new entry into binary search tree.
		tsForTree = me.TimeStamp.new(portNum, expTime);
		c = me._database.size();
		e = me._database.insert(address, tsForTree);
		
		if (e == nil){
			# Insertion failed.  Aborting.
			return nil;
		}
		else {
			# Create a new time stamp and put it in our queue.
			ts = me.TimeStamp.new(address, expTime);
			me._timeStamps.enqueue(ts);
			
			if ((me._database.size() == c) == 0){
				# Increae entries tally if there was change to the database.
				me._entries = me._entries + 1;
			}
		}
		
		return e;
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
			return me._database.getElement(ent).element();
		}
	},
	
	# Returns the number of entries stored in the address table.
	size : func{
		return me._entries;
	},
	
	# Performs a check on the current time and removes entries if necessary.
	update : func{
		# Get time from /sim/time/elapsed-sec[0].
		curTime = props.globals.getNode("/sim/time/elapsed-sec[0]").getValue();
		
		if (me._timeStamps.isEmpty()){
			# Exist early when the queue is empty.
			return nil;
		}
		
		# Take a peek at the queue.  If the time stamp indicates that the object has expired, perform
		#  dequeue operation and remove the associated node from the binary search tree.
		front = me._timeStamps.front();
		while ((front == nil) == 0 and curTime >= front.time()){
			# Entry expired..
			address = me._timeStamps.dequeue().element();
			
			# Look for the dequeued element on the tree, and remove the said element from the tree
			#  if its time stamp has expired.
			ent = me._database.find(address);
			time = ent.value().time();
			
			if (curTime >= time){
				me._database.removeEntry(ent);
				me._entries = me._entries - 1;
			}
			front = me._timeStamps.front();
		}
	}
};
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********