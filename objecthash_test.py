# -*- coding: utf-8 -*-

import unittest
import objecthash
from binascii import unhexlify


class TestCommonJSONHash(unittest.TestCase):
    def verify(self, j, e):
        h = objecthash.common_json_hash(j)
        self.assertEqual(h, unhexlify(e))
        
    def test_common(self):
        self.verify('["foo", "bar"]',
                    '32ae896c413cfdc79eec68be9139c86ded8b279238467c216cf2bec4d5f1e4a2')

    def test_float_and_int(self):
        self.verify('["foo", {"bar":["baz", null, 1.0, 1.5, 0.0001, 1000.0, 2.0, -23.1234, 2.0]}]',
                    '783a423b094307bcb28d005bc2f026ff44204442ef3513585e7e73b66e3c2213')
        # Integers and floats are the same in common JSON
        self.verify('["foo", {"bar":["baz", null, 1, 1.5, 0.0001, 1000, 2, -23.1234, 2]}]',
                    '783a423b094307bcb28d005bc2f026ff44204442ef3513585e7e73b66e3c2213')

    def test_key_change(self):
        self.verify('["foo", {"b4r":["baz", null, 1, 1.5, 0.0001, 1000, 2, -23.1234, 2]}]',
                    '7e01f8b45da35386e4f9531ff1678147a215b8d2b1d047e690fd9ade6151e431')

    def test_unicode(self):
        self.verify(u'"ԱԲաբ"',
                    '2a2a4485a4e338d8df683971956b1090d2f5d33955a81ecaad1a75125f7a316c')

    def test_unicode_normalisation(self):
        self.verify(u'"\u03d3"',
                    'f72826713a01881404f34975447bd6edcb8de40b191dc57097ebf4f5417a554d')
        self.verify(u'"\u03d2\u0301"',
                    'f72826713a01881404f34975447bd6edcb8de40b191dc57097ebf4f5417a554d')
        
        
class TestPythonJSONHash(unittest.TestCase):
    def verify(self, j, e):
        h = objecthash.python_json_hash(j)
        self.assertEqual(h, unhexlify(e))

    def test_common(self):
        # The same as common JSON
        self.verify('["foo", "bar"]',
                    '32ae896c413cfdc79eec68be9139c86ded8b279238467c216cf2bec4d5f1e4a2')

    def test_float_and_int(self):
        self.verify('["foo", {"bar":["baz", null, 1.0, 1.5, 0.0001, 1000.0, 2.0, -23.1234, 2.0]}]',
                    '783a423b094307bcb28d005bc2f026ff44204442ef3513585e7e73b66e3c2213')
        # Integers and floats are NOT the same in Python JSON
        self.verify('["foo", {"bar":["baz", null, 1, 1.5, 0.0001, 1000, 2, -23.1234, 2]}]',
                    '726e7ae9e3fadf8a2228bf33e505a63df8db1638fa4f21429673d387dbd1c52a')


class TestObjectHash(unittest.TestCase):
    def verify(self, o, e):
        h = objecthash.obj_hash(o)
        self.assertEqual(h, unhexlify(e))

    def test_json(self):
        self.verify(['foo', {'bar': ['baz', None, 1, 1.5, 0.0001, 1000, 2, -23.1234, 2]}],
                    # The same as the equivalent Python JSON object
                    '726e7ae9e3fadf8a2228bf33e505a63df8db1638fa4f21429673d387dbd1c52a')              
    
    def test_set(self):
        self.verify({ 'thing1': { 'thing2': set((1, 2, 's')) }, 'thing3': 1234.567 },
                    '618cf0582d2e716a70e99c2f3079d74892fec335e3982eb926835967cb0c246c')

    def test_complex_set(self):
        # FIXME: OMG!
        self.verify(set(('foo', 23.6, frozenset((frozenset(),)), frozenset((frozenset((1,)),)))),
                    '3773b0a5283f91243a304d2bb0adb653564573bc5301aa8bb63156266ea5d398')

        
if __name__ == '__main__':
        unittest.main(verbosity=2)
