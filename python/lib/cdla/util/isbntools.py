#!/usr/bin/env python

import re

def validate(input):
	"""Tests input string to see whether it's a valid 10- or 
	13-digit ISBN"""
	cleaned = input.replace("-", "")
	cleaned = cleaned.replace(" ", "")
	if len(cleaned) == 10:
		return _validate_tendigit(cleaned)
	elif len(cleaned) == 13:
		return _validate_thirteendigit(cleaned)
	raise ValueError("ISBN must be a 10 or 13-digit number (irrespective of spaces or dashes)")

def _validate_tendigit(input):
	"""Internal routine for validating 10-digit ISBNs"""
	checksum = 0
	for idx, char in enumerate(input):
		if char == 'X':
			char = 10
		else:
			char = int(char)
		checksum += (10-idx) * char
	return checksum % 11 == 0

def tento13(input):
	"""Converts a ten digit ISBN to its thirteen digit counterpart"""
	temp = "978" + input + "0"
	return temp[:-1] + checkdigit13(temp)
	

def checkdigit13(input):
	"""Gets the check digit for a 13 digit ISBN
	`input` - a thirteen digit ISBN.

	The caller is expected to verify the length (13 characters, no spaces)
	and "digitality" of the input string; unexpected results may result
	from passing in shorter/longer strings."""
	checksum = 0
	for idx,char in enumerate(input[:-1]):
		mult = ( idx % 2 == 0 ) and 1 or 3
		checksum += mult * int(char)
	return ( 10 - checksum ) % 10 
	
def _validate_thirteendigit(input):
	return int(input[-1]) == checkdigit13(input)

def format(isbn,validate=False):
	"""Formats ISBNs according to some rules I picked up somewhere ..."""
	# 10-digit 1-4-4-1
	# 13-digit 3-1-4-4-1
	if len(isbn) == 10:
		return u"%s-%s-%s-%s" % (isbn[0],isbn[1:5],isbn[5:9],unicode(isbn[9]))
	elif len(isbn) == 13:
		return u"%s-%s-%s-%s-%s" % (isbn[0:3],isbn[3],isbn[4:8],isbn[8:12],isbn[12])


if __name__ == '__main__':
	import sys
	import unittest
	# num, well-formed, valid
	_DEFAULTS = (
			("ISBN: 11324567890",False, False),
			("1413304540",True,True),
			("1413304542", True,False),
			("978-0-123456-47-2",True,True),
			("978-0-123456-47-3", True,False),
			("98754389875",False,False),
		)

	class TestValidate(unittest.TestCase):
		def setUp(self,numbers=_DEFAULTS):
			self.numbers = numbers
		
		def testValidate(self):
			for num,wf,valid in self.numbers:
				if not wf:
					try:
						validate(num)
						self.fail("%s is not well-formed" % num)
					except ValueError:
						self.assertTrue(True)
				else:
					self.assertEqual(valid, validate(num))	

	unittest.main()
		
	
