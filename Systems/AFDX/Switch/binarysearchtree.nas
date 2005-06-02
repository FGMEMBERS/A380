# ********** ********** ********** ********** ********** ********** ********** ********** ********** ********** 
# binarysearchtree.nas
# This is an implementation of a binary search tree using Nasal.  This class inherits the BinaryTree object.
# 
# Class:
#  BinarySearchTree
#  	Methods:
#  	 new(c) 		- creates and returns a new instance of the binary search tree object.
#  	 find(k)		- returns the entry with the given key.
#  	 insert(k, e)		- inserts the element and associate it with the given key.
#  	 remove(entry)		- removes the specified entry from the binary search tree.
#  	 standardRemove(v)	- removes the specified node from the binary tree.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
Comparator = {
	# An empty comparator
	compare : func(key1, key2){
	}
};

BinarySearchTree = {
# Sub-class:
	Entry : {
		# Creates a new entry.
		new : func(key, value, position){
			obj = {};
			obj.parents = [BinarySearchTree.Entry];
			
			# Instance variables:
			obj._key = key;
			obj._position = position;
			obj._value = value;
			
			return obj;
		},
		
		# Accessors:
		key : func{
			return me._key;
		},
		
		position : func{
			return me._position;
		},
		
		value : func{
			return me._value;
		}
	},

# Methods:
	new : func(c){
		obj = {};
		obj.parents = [BinaryTree, BinarySearchTree];
		
		# Instance variables:
		obj._c = c;	# Comparator.
		
		return obj;
	},
	
	# Auxiliary methods:
	
	# From the given node, performs a search down the tree and returns the node containing the given key.
	search : func(k, v){
		if (k == nil or v == nil){
			# Invalid argument(s).
			return nil;
		}
		if (me.isExternal(v)){
			# No node with the given key is found, so return the external node.
			return v;
		}
		else {
			key = v.element().key();
			tmp = me._c.compare(k, key);
			
			if (tmp < 0){
				return me.search(k, me.getLeft(v));
			}
			elsif (tmp > 0){
				return me.search(k, me.getRight(v));
			}
			else {
				return v;
			}
		}
	},
	
	# Accessors:
	
	# Finds and returns the entry with the given key.
	find : func(k){
		v = me.search(k, me._root);
		
		if (v == nil){
			# Error was encountered during search.
			return nil;
		}
		
		if (me.isExternal(v)){
			# Nothing found.
			return nil;
		}
		else {
			# Return the entry.
			return v.element();
		}
	},
	
	# Returns the element contained in the given entry.
	getElement : func(entry){
		return entry.value();
	},
	
	# Modifiers:
	
	# Using the key, inserts an element in the correct position on the tree.
	insert : func(k, e){
		# Search for the correct external node.
		v = me.search(k, me._root);
		
		if (me.isInternal(v)){
			# Entry already exists.
			return nil;
		}
		
		# Create a new position.
		pos = me.Position.new(nil, v, nil, nil);
		
		# Create an entry.
		entry = Entry.new(k, e, pos);
		pos.setElement(entry);
		
		# Initialize external nodes for node pos.
		c = me.Position.new(nil, pos, nil, nil);
		
		# Search for the correct location to place pos.
		tmp = me._c.compare(k, v.element().key());
		if (tmp < 0){
			tmp = me.insertLeft(v, e);
			a = me.insertLeft(tmp, c);
			b = me.insertRight(tmp, c);
			return tmp;
		}
		elsif (tmp > 0){
			tmp = me.insertRight(v, e);
			a = me.insertLeft(tmp, c);
			b = me.insertRight(tmp, c);
			return tmp;
		}
		else {
			# Entry Externalready exists.
			return nil;
		}
	},
	
	# Removes the node with the given entry.
	remove : func(entry){
		v = entry.position();
		
		if (me.isExternal(v)){
			# No node with key entry.key().
			return nil;
		}
		
		if (me.isExternal(me.getLeft(v)) == 1){
			# The left child of v is external.
			# Remove v's external child, then use the standard remove function to remove v.
			tmp = me.standardRemove(me.getLeft(v));
			return me.standardRemove(v);
		}
		elsif (me.isExternal(me.getRight(v)) == 1){
			# The right child of v is external.
			# Remove v's external child, then use the standard remove function to remove v.
			me.standardRemove(me.getRight(v));
			return me.standardRemove(v);
		}
		else {	# Both children of v are internal nodes.
			# Get the right child of v, then iterate through all the left child until we hit a 
			#  node with an external children.
			r = me.getRight(v);
			l = me.getLeft(r);
			while (me.isInternal(l)){
				l = me.getLeft(r);
			}
			# Replace v with l's parent.
			tmp = l.getParent();
			me.replace(v, tmp.element());
			
			# Remove l using standard remove.
			me.standardRemove(l);
			
			# Remove l's parent.
			me.standardRemove(tmp);
		}
		
		return v;
	},
	
	# Removes the specified node from the tree if it only has one child.
	standardRemove : func(v){
		if (me.hasLeft(v) and me.hasRight(v)){
			# Remove operation can't be performed if both children exist.
			return nil;
		}
		
		# Get child of v.
		c = nil;
		if (me.hasLeft(v)){
			c = me.getLeft(v);
		}
		elsif (me.hasRight(v)){
			c = me.getRight(v);
		}
		else {
			c = nil;
		}
		
		# Get parent of v.
		p = nil;
		if (v == me.root()){
			# Special case, where the root is being removed.
			if (c == nil){
				# Last node being removed.
				me._root = nil;
			}
			else {
				# Set c as root.
				c.setParent(nil);
				me.setRoot(c);
			}
		}
		else {
			p = me.getParent(v);
			if (v == me.getLeft(p)){
				p.setLeft(c);
			}
			elsif (v == me.getRight(p)) {
				p.setRight(c);
			}
		}
		
		# Set parent for c if c exists.
		if (c == nil){}
		else {
			c.setParent(p);
		}
		
		# Deduct tally.
		me._size = me._size - 1;
		
		return v.element();
	}
};