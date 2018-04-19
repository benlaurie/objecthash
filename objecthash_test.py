# -*- coding: utf-8 -*-

import unittest
import objecthash
from binascii import hexlify as hexify

class TestUnicode(unittest.TestCase):
    def test_normalisation(self):
        u1n = u"\u03d3"
        u1d = u"\u03d2\u0301"
        self.assertNotEqual(u1n, u1d)
        n1n = objecthash.unicode_normalize(u1n)
        n1d = objecthash.unicode_normalize(u1d)
        self.assertEqual(n1n, n1d)
        s1n = set((u1n,))
        s1d = set((u1n, u1d))
        self.assertNotEqual(s1n, s1d)
        ns1n  = objecthash.unicode_normalize(s1n)
        ns1d  = objecthash.unicode_normalize(s1d)
        self.assertEqual(ns1n, ns1d)
        l1n1 = [u1n]
        l1n2 = [u1n, u1n]
        l1d = [u1n, u1d]
        self.assertNotEqual(l1n1, l1n2)
        self.assertNotEqual(l1n1, l1d)
        self.assertNotEqual(l1n2, l1d)
        nl1n1 = objecthash.unicode_normalize(l1n1)
        nl1n2 = objecthash.unicode_normalize(l1n2)
        nl1d = objecthash.unicode_normalize(l1d)
        self.assertNotEqual(nl1n1, nl1n2)
        self.assertNotEqual(nl1n1, nl1d)
        self.assertEqual(nl1n2, nl1d)


class TestCommonJSONHash(unittest.TestCase):
    def verify(self, j, e, fns=()):
        h = objecthash.json_hash(j, (objecthash.commonize,) + fns)
        self.assertEqual(hexify(h), e)

    def test_golden(self):
        with open('common_json.test') as f:
            while True:
                while True:
                    j = f.readline()
                    if not j or (not j.startswith('#') and not j.startswith('~') and j[0] != '\n'):
                        break
                if not j:
                    break
                h = f.readline()
                if h.endswith('\n'):
                    h = h[:-1]
                self.verify(j, h)
        
    def test_unicode_normalisation(self):
        self.verify(u'"\u03d3"',
                    'f72826713a01881404f34975447bd6edcb8de40b191dc57097ebf4f5417a554d')
        self.verify(u'"\u03d2\u0301"',
                    'f72826713a01881404f34975447bd6edcb8de40b191dc57097ebf4f5417a554d',
                    (objecthash.unicode_normalize,))
        # Different hash if not normalised
        self.verify(u'"\u03d2\u0301"',
                    '42d5b13fb064849a988a86eb7650a22881c0a9ecf77057a1b07ab0dad385889c')
        
        
class TestPythonJSONHash(unittest.TestCase):
    def verify(self, j, e):
        # json_hash with no modifiers is Python JSON Hash
        h = objecthash.json_hash(j)
        self.assertEqual(hexify(h), e)

    def test_common(self):
        # The same as common JSON
        self.verify('["foo", "bar"]',
                    '32ae896c413cfdc79eec68be9139c86ded8b279238467c216cf2bec4d5f1e4a2')

    def test_int(self):
        self.verify('[123]',
                    '1b93f704451e1a7a1b8c03626ffcd6dec0bc7ace947ff60d52e1b69b4658ccaa')
        self.verify('[1, 2, 3]',
                    '157bf16c70bd4c9673ffb5030552df0ee2c40282042ccdf6167850edc9044ab7')
        self.verify('[123456789012345]',
                    '3488b9bc37cce8223a032760a9d4ef488cdfebddd9e1af0b31fcd1d7006369a4')
        self.verify('[123456789012345, 678901234567890]',
                    '031ef1aaeccea3bced3a1c6237a4fc00ed4d629c9511922c5a3f4e5c128b0ae4')

    def test_float_and_int(self):
        self.verify('["foo", {"bar":["baz", null, 1.0, 1.5, 0.0001, 1000.0, 2.0, -23.1234, 2.0]}]',
                    '783a423b094307bcb28d005bc2f026ff44204442ef3513585e7e73b66e3c2213')
        # Integers and floats are NOT the same in Python JSON
        self.verify('["foo", {"bar":["baz", null, 1, 1.5, 0.0001, 1000, 2, -23.1234, 2]}]',
                    '726e7ae9e3fadf8a2228bf33e505a63df8db1638fa4f21429673d387dbd1c52a')


class TestObjectHash(unittest.TestCase):
    def verify(self, o, e):
        h = objecthash.obj_hash(o)
        self.assertEqual(hexify(h), e)

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

    def test_float_special_values(self):
        self.verify(float("nan"), '5d6c301a98d835732d459d7018a8d546872f7ba3c39a45ba481746d2c6d566d9')
        self.verify(float("inf"), 'e0309b2362dc6aaf595338cd9e116761640f74927bcdc4f76e8e6433738f25c7')
        self.verify(float("-inf"), '1167518d5554ba86d9b176af0a57f29d425bedaa9847c245cc397b37533228f7')


class TestRedaction(unittest.TestCase):
    def verify(self, o, e):
        h = objecthash.obj_hash(o)
        self.assertEqual(hexify(h), e)

    def verify_json(self, o, e):
        h = objecthash.json_hash(o,
                                 (objecthash.commonize, objecthash.redactize))
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
