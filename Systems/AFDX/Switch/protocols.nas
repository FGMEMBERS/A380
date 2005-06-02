BPDU = {
	# Parse a string to create an instance of the BPDU format.
	new : func(data){
		obj = {};
		obj.parents = [BPDU];
		
		tmp = [];
		
		if (size(data) == 35){
			# Protocol Identifer (2 bytes)
			id = strc(data, 0) + strc(data, 1);
			
			if (id == 0){
				# Protocol Identifier (2 bytes)
				append(tmp, substr(data, 0, 2));
				# Version (1 byte)
				append(tmp, substr(data, 2, 1));
				# Message type (1 byte)
				append(tmp, substr(data, 3, 1));
				# Flags (1 byte)
				append(tmp, substr(data, 4, 1));
				# RootID (8 bytes)
				append(tmp, substr(data, 5, 8));
				# Root path cost (4 bytes)
				append(tmp, substr(data, 13, 4));
				# BridgeID (8 bytes)
				append(tmp, substr(data, 17, 8));
				# PortID (2 bytes)
				append(tmp, substr(data, 25, 2));
				# Message age (2 bytes)
				append(tmp, substr(data, 27, 2));
				# Maximium age (2 bytes)
				append(tmp, substr(data, 29, 2));
				# Hello time (2 bytes)
				append(tmp, substr(data, 31, 2));
				# Forward delay (2 bytes)
				append(tmp, substr(data, 33, 2));
			}
		}
		
		if (size(tmp) == 0){
			# Protocol Identifier (2 bytes)
			append(tmp, chr(0) ~ chr(0));
			# Version (1 byte)
			append(tmp, chr(0));
			# Message type (1 byte)
			append(tmp, chr(0));
			# Flags (1 byte)
			append(tmp, chr(0));
			# RootID (8 bytes)
			append(tmp, chr(127) ~ chr(255) ~ chr(0) ~ chr(0) ~ chr(0) ~ chr(0) ~ chr(0) ~ chr(0));
			# Root path cost (4 bytes)
			append(tmp, chr(0) ~ chr(0) ~ chr(0) ~ chr(0));
			# BridgeID (8 bytes)
			append(tmp, chr(127) ~ chr(255) ~ chr(0) ~ chr(0) ~ chr(0) ~ chr(0) ~ chr(0) ~ chr(0));
			# PortID (2 bytes)
			append(tmp, chr(0) ~ chr(0));
			# Message age (2 bytes)
			append(tmp, chr(0) ~ chr(0));
			# Maximium age (2 bytes)
			append(tmp, chr(0) ~ chr(0));
			# Hello time (2 bytes)
			append(tmp, chr(0) ~ chr(0));
			# Forward delay (2 bytes)
			append(tmp, chr(0) ~ chr(0));
		}
		obj = {};
		obj.parents = [BPDU];
		

		
		# Instance variables:
		obj.block = tmp;
		
		return obj;
	},
	
	# Accessors:
	getBridgeID : func{
		return me.block[6];
	},
	
	getForwardDelay : func{
		return strc(me.block[11], 1);
	},
	
	getHelloTime : func{
		return strc(me.block[10], 1);
	},
	
	getMaxAge : func{
		return strc(me.block[9], 1);
	},
	
	getMessageAge : func{
		return strc(me.block[8], 1);
	},
	
	getPortID : func{
		return strc(me.block[7], 1);
	},
	
	getRootID : func{
		return me.block[4];
	},
	
	getRootPathCost : func{
		return strc(me.block[5], 3);
	},
	
	# Modifiers:
	setBridgeID : func(bid){
		if (size(bid) == 8){
			me.block[6] = bid;
			return 1;
		}
		else {
			# Invalid BID.
			return 0;
		}
	},
	
	setForwardDelay : func(delay){
		if (delay == nil){
			# Invalid time specification.
			return 0;
		}
		else {
#			if (size(delay) == nil){
				tmp = chr(0) ~ chr(delay);
				me.block[11] = tmp;
#			}
#			else {
#				# Argument cannot be a string.
#				return -1;
#			}
		}
	},
	
	setHelloTime : func(elapse){
		if (elapse == nil){
			# Invalid time specification.
			return 0;
		}
		else {
#			if (size(elapse) == nil){
				tmp = chr(0) ~ chr(elapse);
				me.block[10] = tmp;
#			}
#			else {
#				# Argument cannot be a string.
#				return -1;
#			}
		}
	},
	
	setMaxAge : func(age){
		if (age == nil){
			# Invalid time specification.
			return 0;
		}
		else {
#			if (size(age) == nil){
				tmp = chr(0) ~ chr(age);
				me.block[9] = tmp;
#			}
#			else {
#				# Argument cannot be a string.
#				return -1;
#			}
		}
	},
	
	setMessageAge : func(age){
		if (age == nil){
			# Invalid time specification.
			return 0;
		}
		else {
#			if (size(age) == nil){
				tmp = chr(0) ~ chr(age);
				me.block[8] = tmp;
#			}
#			else {
#				# Argument cannot be a string.
#				return -1;
#			}
		}
	},
	
	setPortID : func(id){
		if (id == nil){
			# Invalid id specification.
			return 0;
		}
		else {
#			if (size(id) == nil){
				tmp = chr(0) ~ chr(id);
				me.block[7] = tmp;
#			}
#			else {
#				# Argument cannot be a string.
#				return -1;
#			}
		}
	},
	
	setRootID : func(rid){
		if (size(rid) == 8){
			me.block[4] = rid;
			return 1;
		}
		else {
			# Invalid RID.
			return 0;
		}
	},
	
	setRootPathCost : func(cost){
		if (cost == nil){
			# Invalid cost specification.
			return 0;
		}
		else {
#			if (size(cost) == nil){
				tmp = chr(0) ~ chr(cost);
				me.block[5] = tmp;
#			}
#			else {
#				# Argument cannot be a string.
#				return -1;
#			}
		}
	},
	
	# Turn the frame into a string.
	toString : func{
		out = "";
		foreach (block ; me.block){
			out = out ~ block;
		}
		return (out);
	}
};

Frame = {
	# Parse a string to create an instance of the frame format.
	new : func(packet){
		obj = {};
		obj.parents = [Frame];
		
		tmp = [];
		
		if (size(packet) > 0){
			# Delimiter (1 byte) ignored.
			# Sync (4 bytes) ignored.
			# Destination (6 bytes)
			append(tmp, substr(packet, 1, 6));
			# Source (6 bytes)
			append(tmp, substr(packet, 7, 6));
			# Length of data field (4 bytes)
			append(tmp, substr(packet, 13, 4));
			# Data field (1500 bytes MAX)
			append(tmp, substr(packet, 17, size(packet) - 17 - 5));
			# Check sum (4 bytes)
			append(tmp, substr(packet, size(packet) - 5));
		}
		else {
			# Delimiter (1 byte) ignored.
			# Sync (4 bytes) ignored.
			# Destination (6 bytes)
			append(tmp, chr(0) ~ chr(0) ~ chr(0) ~ chr(0) ~ chr(0) ~ chr(0));
			# Source (6 bytes)
			append(tmp, chr(0) ~ chr(0) ~ chr(0) ~ chr(0) ~ chr(0) ~ chr(0));
			# Length of data field (4 bytes)
			append(tmp, chr(0) ~ chr(0) ~ chr(0) ~ chr(0));
			# Data field (1500 bytes MAX)
			append(tmp, chr(0));
			# Check sum (4 bytes)
			append(tmp, chr(0) ~ chr(0) ~ chr(0) ~ chr(0));
		}
		
		# Instance variables:
		obj.block = tmp;
		
		return obj;
	},
	
	# Retrieve the data field in string.
	getData : func{
		return me.block[3];
	},
	
	# Retrieve the destination address.
	getDestination : func{
		return me.block[0];
	},
	
	# Retrieve the source address.
	getSource : func{
		return me.block[1];
	},
	
	# Modify the data field.
	setData : func(data){
		me.block[3] = data;
	},
	
	# Modify the destination address.
	setDestination : func(address){
		if (size(address) == 6){
			me.block[0] = address;
			return 1;
		}
		else {
			# Invalid address.
			return 0;
		}
	},
	
	# Modify the source address.
	setSource : func(address){
		if (size(address) == 6){
			me.block[1] = address;
			return 1;
		}
		else {
			# Invalid address.
			return 0;
		}
	},
	
	# Turn the frame into a string.
	toString : func{
		return (me.block[0] ~ me.block[1] ~ me.block[2] ~ me.block[3] ~ me.block[4]);
	}
};

LLC = {
	# Parse a string to create an instance of the Logical Link Control (LLC) layer.
	new : func(data){
		obj = {};
		obj.parents = [LLC];
		
		tmp = [];
		
		if (size(data) > 0){
			# DSAP (1 byte)
			append(tmp, substr(data, 0, 1));
			# SSAP (1 byte)
			append(tmp, substr(data, 1, 1));
			# Control (1 byte)
			append(tmp, substr(data, 2, 1));
			# Data (1497 bytes MAX)
			append(tmp, substr(data, 3));
		}
		else {
			# DSAP (1 byte)
			append(tmp, chr(0));
			# SSAP (1 byte)
			append(tmp, chr(0));
			# Control (1 byte)
			append(tmp, chr(0));
			# Data (1497 bytes MAX)
			append(tmp, chr(0));
		}
		
		# Instance variables:
		obj.block = tmp;
		
		return obj;
	},
	
	# Accessors:
	getControl : func{
		return strc(me.block[2], 0);
	},
	
	getData : func{
		return me.block[3];
	},
	
	getDSAP : func{
		return strc(me.block[0], 0);
	},
	
	getSSAP : func{
		return strc(me.block[1], 0);
	},
	
	# Modifiers:
	setControl : func(val){
		if (val == nil){
			# Invalid cost specification.
			return 0;
		}
		else {
#			if (size(val) == nil){
				tmp = chr(val);
				me.block[2] = tmp;
#			}
#			else {
#				# Argument cannot be a string.
#				return -1;
#			}
		}
	},
	
	setData : func(data){
		me.block[3] = data;
	},
	
	setDSAP : func(val){
		if (val == nil){
			# Invalid cost specification.
			return 0;
		}
		else {
#			if (size(val) == nil){
				tmp = chr(val);
				me.block[0] = tmp;
#			}
#			else {
#				# Argument cannot be a string.
#				return -1;
#			}
		}
	},
	
	setSSAP : func(val){
		if (val == nil){
			# Invalid cost specification.
			return 0;
		}
		else {
#			if (size(val) == nil){
				tmp = chr(val);
				me.block[1] = tmp;
#			}
#			else {
#				# Argument cannot be a string.
#				return -1;
#			}
		}
	},
		
	# Turn the frame into a string.
	toString : func{
		return (me.block[0] ~ me.block[1] ~ me.block[2] ~ me.block[3]);
	}
};