# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# Copyright (C) 2005  Ampere K. [Hardraade]
#
# This file is protected by the GNU Public License.  For more details, please see the text file COPYING.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# DLinkedList.nas
# This is a doubly-linked-list implemented using Nasal.  A linked-list basically serves the same purpose as a
#  vector (an array) by storing a list of elements.  Unlike a vector however, a doubly-linked-list allows fast
#  insertion and removal of elements, but with severe performance lost in look up functions.
# There are two types of linked-list: singly-linked-list and doubly-linked-list.  In singly-linked-list, one
#  can only traverse the list in one direction.  A doubly-linked-list allows traversal in both directions:
#  traversal can be done in-order by starting from the first element in the list, or in reversed-order by
#  starting from the last element in the list.  This Nasal script implements the latter type of linked-list.
#
# Class:
#  DNode
#  	new(prev, next, element)
#  	getElement
#  	getNext
#  	getPrev
#  	setElement(element)
#  	setNext(next)
#  	setPrev(prev)
#  
#  DLinkedList
#  	new()			- creates and returns a new instance of the double linked list.
#  	first()			- returns the first node in the object.
#  	insertAfter(p, e)	- inserts the specified element after the given position.
#  	insertBefore(p, e)	- inserts the specified element before the given position.
#  	insertFirst(e)		- inserts the given element at the beginning of the list.
#  	insertLast(e)		- inserts the given element at the end of the list.
#  	isEmpty()		- returns whether the list is empty.
#  	last()			- returns the last node in the linked list.
#  	next(p)			- returns the next node following p.
#  	prev(p)			- returns the node preceding p.
#  	remove(p)		- removes the specified node.
#  	replace(p, e)		- replaces the element in the specified position with e.
#  	size()			- returns the number of objects being stored in the list.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
DNode = {
# Methods:
	# Creates and returns a new instance of the node object.
	new : func(prev, next, element){
		obj = {};
		obj.parents = [DNode];
		
		# Instance variables:
		obj._element = element;
		obj._next = next;
		obj._prev = prev;
		
		return obj;
	},
# Accessors:
	# Returns the element contained in the node.
	getElement : func{
		return me._element;
	},
	
	# Returns the next node.
	getNext : func{
		return me._next;
	},
	
	# Returns the previous node.
	getPrev : func{
		return me._prev;
	},

# Modifiers:
	# Specifies the element being stored.
	setElement : func(element){
		me._element = element;
	},
	
	# Sets the node that follows this one.
	setNext : func(next){
		me._next = next;
	},
	
	# Sets the given node as the 
	setPrev : func(prev){
		me._prev = prev;
	}
};

DLinkedList = {
# Methods:
	# Creates and returns a new instance of the double linked list.
	new : func{
		obj = {};
		obj.parents = [DLinkedList];
		
		# Instance variables:
		obj._first = DNode.new(nil, nil, nil);
		obj._last = DNode.new(obj._first, nil, nil);
		obj._first.setNext(obj._last);
		obj._size = 0;
		
		return obj;
	},
	
	# Returns whether the list is empty.
	isEmpty : func{
		return (me._size == 0);
	},
	
	# Returns the number of objects being stored in the list.
	size : func{
		return me._size;
	},
	
# Auxiliary methods:
	# Checks whether the given position is valid.
	checkPosition : func(p){
		if (p == nil){
			return nil;
		}
		# These are not going to work.
		#if (p == me._first){
		#	die ("The header sentinal is an invalid position.");
		#}
		#if (p == me._last){
		#	die ("The trailer sentinal is an invalid position.");
		#}
		if (p.getPrev() == nil and p.getNext() == nil){
			die ("Position does not belong to a double linked list.");
		}
		
		return p;
	},
	
# Accessors:
	# Returns the node at the beginning of the list.
	getFirst : func{
		#if (me.isEmpty){
		#	# Force an error.  DO NOT REMOVE!
		#	die ("The List is Empty.");
		#}
		# If we have nothing to return, then return a nil.
		if (me.isEmpty()){
			return nil;
		}
		return me._first.getNext();
	},
	
	# Returns the node at the end of the list.
	getLast : func{
		#if (me.isEmpty){
		#	# Force an error.  DO NOT REMOVE!
		#	die ("The List is Empty.");
		#}
		# If we have nothing to return, then return a nil.
		if (me.isEmpty()){
			return nil;
		}
		return me._last.getPrev();
	},
	
	# Returns the node that follows p, if it exists.
	getNext : func(p){
		v = me.checkPosition(p);
		
		next = nil;
		if (v != nil){
			next = v.getNext();
		}
		
		# This is not going to work.
		#if (next == me._last){
		#	die ("Cannot advance beyond the end of the list.");
		#}
		return next;
	},
	
	# Returns the node infront of p, if it exists.
	getPrev : func(p){
		v = me.checkPosition(p);
		
		prev = nil;
		if (v != nil){
			prev = v.getPrev();
		}
		
		# This is not going to work.
		#if (prev == me._first){
		#	die ("Cannot advance past the beginning of the list.");
		#}
		return prev;
	},
	
# Modifiers:
	# Inserts the specified element behind the given position.
	insertAfter : func(p, e){
		v = me.checkPosition(p);
		
		newNode = DNode.new(v, v.getNext(), e);
		if (v.getNext() != nil){
			v.getNext().setPrev(newNode);
		}
		else {
			# New node will be our last node.
			me._last.setPrev(newNode);
		}
		v.setNext(newNode);
		
		me._size = me._size + 1;
		
		return newNode;
	},
	
	# Inserts the specified element infront of the given position.
	insertBefore : func(p, e){
		v = me.checkPosition(p);
		
		newNode = DNode.new(v.getPrev(), v, e);
		if (v.getPrev() != nil){
			v.getPrev().setNext(newNode);
		}
		else {
			# New node will be our first node.
			me._first.setNext(newNode);
		}
		v.setPrev(newNode);
		
		me._size = me._size + 1;
		
		return newNode;
	},
	
	# Inserts the specified element at the beginning of the list.
	insertFirst : func(e){
		me._size = me._size + 1;
		
		# newNode = DNode.new(me._first, me._first.getNext(), e);
		# Don't create link to sentinal.
		newNode = DNode.new(nil, me._first.getNext(), e);
		
		me._first.getNext().setPrev(newNode);
		me._first.setNext(newNode);
		
		return newNode;
	},
	
	# Inserts the specified element into the end of the list.
	insertLast : func(e){
		me._size = me._size + 1;
		
		# newNode = DNode.new(me._last.getPrev(), me._last, e);
		# Don't create link to sentinal.
		newNode = DNode.new(me._last.getPrev(), nil, e);
		
		me._last.getPrev().setNext(newNode);
		me._last.setPrev(newNode);
		
		return newNode;
	},
	
	# Removes the given position from the list, and returns its content.
	remove : func(p){
		v = me.checkPosition(p);
		
		me._size = me._size - 1;
		
		tmp = v.getElement();
		
		next = v.getNext();
		prev = v.getPrev();
		if (next == nil){
			# This is the last node.
			me._last.setPrev(prev);
			prev.setNext(nil);
		}
		elsif (prev == nil){
			# This is the first node.
			me._first.setNext(next);
			next.setPrev(nil);
		}
		else {
			prev.setNext(next);
			next.setPrev(prev);
		}
		
		v.setPrev(nil);
		v.setNext(nil);
		
		return tmp;
	},
	
	# Replaces the element in the specified position with the given element.
	replace : func(p, e){
		tmp = p.getElement();
		
		p.setElement(e);
		
		return tmp;
	}
};