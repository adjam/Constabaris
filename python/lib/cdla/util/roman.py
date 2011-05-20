#!/usr/bin/env python

# -*- coding: utf-8 -*-

# $Id$ : $LastChangedDate$

# roman.py -- utilities for converting between roman and arabic number
# systems.  Original author Adam Constabaris <adamc@unc.edu>

# Copyright 2009 University of North Carolina at Chapel Hill
# Licensed under the
# Educational Community License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may
# obtain a copy of the License at
#	
# http://www.osedu.org/licenses/ECL-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an "AS IS"
# BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing
# permissions and limitations under the License.

__doc__ = """Utilities for converting back and forth between integers and roman numerals"""

_roman_characters = ( ('M', 1000), 
	  ('D', 500),
	  ('C', 100),
	  ('L', 50),
	  ('X', 10),
	  ('V', 5),
	  ('I', 1) ) 

_roman_map = dict(_roman_characters)

def _make_inverse():
	compound = list(_roman_characters + (('CM', 900), ('CD', 400), ('XL', 40), ('IX', 9), ('IV', 4)))
	by_val = lambda t1,t2: -cmp(t1[1], t2[1])
	compound.sort(by_val)
	return [ (x[1], x[0]) for x in compound ]

_inverse = _make_inverse()

def to_decimal(roman):
	"""Converts a string (case-insensitive) representing roman numerals into an int."""
	# implementation; reverse the string, then for each digit,
	# check its numeric value and if it's greater than or equal to
	# the biggest digit already seen, add it to the total; if less,
	# subtract it; e.g. "mcmix" => "ximcm" => 10-1+1000-500+1000 => 1509
	total = 0
	biggest = 0
	for digit in roman[::-1]:
		val = _roman_map[digit.upper()]
		if val >= biggest:
			total += val
			biggest = val
		else:
			total -= val
	return total

def to_roman(decimal,lower=True):
	"""Converts an int to a roman numeral string.  If lower is True, the string will be lower cased, otherwise result is all caps."""
	build = ""
	total = int(decimal)
	for k,v in _inverse:
		div = total / k
		if div:
			add = v * div
			total -= div * k
			build += add
	assert(total == 0)
	if lower:
		return build.lower()
	return build
		
def _main(numbers):
	for num in numbers:
		if isinstance(num, int) or num.isdigit():
			rom = to_roman(int(num),True)
			print "%d => %s" % ( num, rom )
			assert( to_decimal(rom) == num )
		else:
			print "%s => %d" % ( num, to_decimal(num) )

if __name__ == '__main__':
	import sys
	numerals = sys.argv[1:]
	if not len(numerals):
		numerals = ['mcmlxvii', 'iv', 'ix', 'v', 1984, 2069, 3982]
		numerals += range(1,19)
	_main(numerals)
