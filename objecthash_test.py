# -*- coding: utf-8 -*-

import unittest
import objecthash
from binascii import unhexlify

class TestUnicode(unittest.TestCase):
    def test_normalisation(self):
        u1n = u"\u03d3"
        u1d = u"\u03d2\u0301"
        self.assertNotEqual(u1n, u1d)
        n1n = objecthash.unicode_normalizify(u1n)
        n1d = objecthash.unicode_normalizify(u1d)
        self.assertEqual(n1n, n1d)
        s1n = set((u1n,))
        s1d = set((u1n, u1d))
        self.assertNotEqual(s1n, s1d)
        ns1n  = objecthash.unicode_normalizify(s1n)
        ns1d  = objecthash.unicode_normalizify(s1d)
        self.assertEqual(ns1n, ns1d)
        l1n1 = [u1n]
        l1n2 = [u1n, u1n]
        l1d = [u1n, u1d]
        self.assertNotEqual(l1n1, l1n2)
        self.assertNotEqual(l1n1, l1d)
        self.assertNotEqual(l1n2, l1d)
        nl1n1 = objecthash.unicode_normalizify(l1n1)
        nl1n2 = objecthash.unicode_normalizify(l1n2)
        nl1d = objecthash.unicode_normalizify(l1d)
        self.assertNotEqual(nl1n1, nl1n2)
        self.assertNotEqual(nl1n1, nl1d)
        self.assertEqual(nl1n2, nl1d)


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

    def test_key_order_independence(self):
        h1 = objecthash.common_json_hash('{"k1":"v1","k2":"v2","k3":"v3"}')
        h2 = objecthash.common_json_hash('{"k2":"v2","k1":"v1","k3":"v3"}')
        self.assertEqual(hexify(h1),hexify(h2))

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

    def test_zero(self):
        self.verify(0.0, '60101d8c9cb988411468e38909571f357daa67bff5a7b0a3f9ae295cd4aba33d')
        self.verify(-0.0, '60101d8c9cb988411468e38909571f357daa67bff5a7b0a3f9ae295cd4aba33d')


class TestRedaction(unittest.TestCase):
    def verify(self, o, e):
        h = objecthash.obj_hash(o)
        self.assertEqual(hexify(h), e)

    def verify_json(self, o, e):
        h = objecthash.common_redacted_json_hash(o)
        self.assertEqual(hexify(h), e)

    def test_common(self):
        self.verify(['foo', 'bar'],
                    '32ae896c413cfdc79eec68be9139c86ded8b279238467c216cf2bec4d5f1e4a2')
        self.verify('bar',
                    'e303ce0bd0f4c1fdfe4cc1e837d7391241e2e047df10fa6101733dc120675dfe')
        self.verify(['foo', objecthash.Redacted('e303ce0bd0f4c1fdfe4cc1e837d7391241e2e047df10fa6101733dc120675dfe')],
                    '32ae896c413cfdc79eec68be9139c86ded8b279238467c216cf2bec4d5f1e4a2')

    def test_common_json(self):
        self.verify_json('["foo", "**REDACTED**e303ce0bd0f4c1fdfe4cc1e837d7391241e2e047df10fa6101733dc120675dfe"]',
                         '32ae896c413cfdc79eec68be9139c86ded8b279238467c216cf2bec4d5f1e4a2')

    def test_float_and_int(self):
        self.verify_json('{"bar":["baz", null, 1.0, 1.5, 0.0001, 1000.0, 2.0, -23.1234, 2.0]}',
                         '96e2aab962831956c80b542f056454be411f870055d37805feb3007c855bd823')
        self.verify_json('["foo", "**REDACTED**96e2aab962831956c80b542f056454be411f870055d37805feb3007c855bd823"]',
                         '783a423b094307bcb28d005bc2f026ff44204442ef3513585e7e73b66e3c2213')

        self.verify_json('["foo", {"bar":["baz", null, 1.0, 1.5, 0.0001, 1000.0, 2.0, -23.1234, 2.0]}]',
                         '783a423b094307bcb28d005bc2f026ff44204442ef3513585e7e73b66e3c2213')

        self.verify_json('"baz"', '82f70430fa7b78951b3c4634d228756a165634df977aa1fada051d6828e78f30')
        self.verify_json('0.0001', '1195afc7f0b70bb9d7960c3615668e072a1cbfbbb001f84871fd2e222a87be1d')
        self.verify_json('["foo", {"bar": ["**REDACTED**82f70430fa7b78951b3c4634d228756a165634df977aa1fada051d6828e78f30", null, 1.0, 1.5, "**REDACTED**1195afc7f0b70bb9d7960c3615668e072a1cbfbbb001f84871fd2e222a87be1d", 1000.0, 2.0, -23.1234, 2.0]}]',
                         '783a423b094307bcb28d005bc2f026ff44204442ef3513585e7e73b66e3c2213')

        self.verify_json('"bar"', 'e303ce0bd0f4c1fdfe4cc1e837d7391241e2e047df10fa6101733dc120675dfe')
        self.verify_json('["foo", {"**REDACTED**e303ce0bd0f4c1fdfe4cc1e837d7391241e2e047df10fa6101733dc120675dfe": ["baz", null, 1.0, 1.5, 0.0001, 1000.0, 2.0, -23.1234, 2.0]}]',
                         '783a423b094307bcb28d005bc2f026ff44204442ef3513585e7e73b66e3c2213')


class TestRedactable(unittest.TestCase):
    def verify(self, j, e):
        h = objecthash.obj_hash(j)
        self.assertEqual(hexify(h), e)

    def unverify(self, j, e):
        h = objecthash.obj_hash(j)
        self.assertNotEqual(hexify(h), e)

    def test_fidelity(self):
        t = objecthash.redactable(['foo', 'bar'])
        self.unverify(t,
                      '32ae896c413cfdc79eec68be9139c86ded8b279238467c216cf2bec4d5f1e4a2')
        self.verify(objecthash.unredactable(t),
                    '32ae896c413cfdc79eec68be9139c86ded8b279238467c216cf2bec4d5f1e4a2')
        t = objecthash.redactable(set(('foo', 23, 1.5, None)))
        self.unverify(t,
                      '32ae896c413cfdc79eec68be9139c86ded8b279238467c216cf2bec4d5f1e4a2')
        self.verify(objecthash.unredactable(t),
                    '5e9dd60afdd356f015d54b27647c2e3439a45547d1efb526260c306e89de2dba')


    def test_redactability(self):
        t = objecthash.redactable(['foo', 'bar'])
        h = hexify(objecthash.obj_hash(t))
        t[1] = objecthash.RedactedObject(t[1])
        self.verify(t, h)


if __name__ == '__main__':
        unittest.main(verbosity=2)
