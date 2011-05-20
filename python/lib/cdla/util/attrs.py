import random

__doc__ ="""Provides various attribute-related classes, such as "lazy loading" descriptors, etc.
"""

def cachedproperty(f):
	"""Decorator that creates a cached property, for getters that are
	'expensive' to run.
	"""
	name = "_cached_" + f.__name__
	def fget(self):
		if not hasattr(self, name):
			self.__dict__[name] = f(self)
		return getattr(self,name)
			
	def fset(self,value):
		self.__dict__[name] = value
		
	def fdel(self):
		try:
			del self.__dict__[name]
		except AttributeError:
			pass
	return property(fget,fset=fset,fdel=fdel)

def main():
    import time
    class Foo(object):
		def yawn(self):
			return time.sleep(3) or "yawn"
		yawn = cachedproperty(yawn)

    import unittest
    class FooTest(unittest.TestCase):
        def setUp(self):
            self.instance = Foo()
        
        def testget(self):
            start = time.time()
            x = self.instance.yawn
            end = time.time()
            self.assertEquals("yawn", x)
            secondstart = time.time()
            y = self.instance.yawn
            secondend = time.time()
            self.assertEquals(x,y)
            self.assertTrue( (end-start) > (secondend - secondstart))

	def testmultiple(self):
            self.assertEquals("yawn", self.instance.yawn)
            y = Foo()
            y.yawn = "youbetcha"
            self.assertTrue( y.yawn != self.instance.yawn)
	

    suite = unittest.TestLoader().loadTestsFromTestCase(FooTest)
    unittest.TextTestRunner(verbosity=3).run(suite)


if __name__ == '__main__':
    main()
    
