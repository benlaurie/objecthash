import json
import hashlib
import unicodedata
from binascii import hexlify as hexify, unhexlify as unhexify

def hash_fn():
    return hashlib.sha256()

def hash(t, b):
    #print hexify(t), hexify(b)
    m = hash_fn()
    m.update(t)
    m.update(b)
    t = m.digest()
    #print '=', hexify(t)
    return t

def obj_hash_list(l):
    h = ''
    for o in l:
        h += obj_hash(o)
    return hash('l', h)

def unicode_normalize(u):
    return unicodedata.normalize('NFC', u).encode('utf-8')

def obj_hash_dict(d):
    h = ''
    kh = [obj_hash(k) + obj_hash(v) for (k, v) in d.items()]
    for v in sorted(kh):
        h += v
    return hash('d', h)

def obj_hash_unicode(u):
    return hash('u', unicode_normalize(u))

def float_normalize(f):
    # sign
    s = '+'
    if f < 0:
        s = '-'
        f = -f
    # exponent
    e = 0
    while f > 1:
        f /= 2
        e += 1
    while f <= .5:
        f *= 2
        e -= 1
    s += str(e) + ':'
    # mantissa
    assert f <= 1
    assert f > .5
    while f:
        if f >= 1:
            s += '1'
            f -= 1
        else:
            s += '0'
        assert f < 1
        assert len(s) < 1000
        f *= 2

    return s

def obj_hash_float(f):
    # FIXME: probably a bad idea to include floats...
    return hash('f', float_normalize(f))

def obj_hash_int(i):
    return hash('i', str(i))

def obj_hash_set(s):
    h = []
    for e in s:
        h.append(obj_hash(e))
    r = ''
    for t in sorted(h):
        r += t
    return hash('s', r)

class Redacted(object):
    def __init__(self, hash):
        self.hash = unhexify(hash)

def obj_hash(o):
    if type(o) is list:
        return obj_hash_list(o)
    elif type(o) is dict:
        return obj_hash_dict(o)
    elif type(o) is unicode:
        return obj_hash_unicode(o)
    elif type(o) is float:
        return obj_hash_float(o)
    elif type(o) is int:
        return obj_hash_int(o)
    elif type(o) is str:
        return obj_hash_unicode(unicode(o))
    elif type(o) is set or type(o) is frozenset:
        return obj_hash_set(o)
    elif type(o) is Redacted:
        return o.hash
    elif o is None:
        return hash('n', '')
    
    print type(o)
    assert False

def python_json_hash(j):
    t = json.loads(j)
    return obj_hash(t)

def commonize_list(l):
    r = []
    for e in l:
        r.append(commonize(e))
    return r

def commonize_dict(d):
    r = {}
    for (k, v) in d.items():
        r[commonize(k)] = commonize(v)
    return r

def commonize(o):
    if type(o) is list:
        return commonize_list(o)
    elif type(o) is dict:
        return commonize_dict(o)
    elif type(o) is unicode:
        return o
    elif type(o) is float:
        return o
    elif type(o) is int:
        return float(o)
    elif type(o) is str:
        return o
    elif o is None:
        return o

    print type(o)
    assert False

def common_json_hash(j):
    t = json.loads(j)
    t = commonize(t)
    return obj_hash(t)

def redactize_list(l):
    r = []
    for e in l:
        r.append(redactize(e))
    return r

def redactize_dict(d):
    r = {}
    for (k, v) in d.items():
        r[redactize(k)] = redactize(v)
    return r

def redactize_unicode(u):
    if u.startswith('**REDACTED**'):
        return Redacted(u[12:])
    else:
        return u

def redactize(o):
    if type(o) is list:
        return redactize_list(o)
    elif type(o) is dict:
        return redactize_dict(o)
    elif type(o) is unicode:
        return redactize_unicode(o)
    elif type(o) is float:
        return o
    elif type(o) is int:
        return o
    elif type(o) is str:
        return redactize_unicode(o)
    elif o is None:
        return o

def common_redacted_json_hash(j):
    t = json.loads(j)
    t = commonize(t)
    t = redactize(t)
    return obj_hash(t)

# t = [ 'foo', { 'bar': ['baz', None, 1.0, 1.5, 0.0001, 1000.0, 2.0, -23.1234, 2]} ]
# print hexify(obj_hash(t))

# t = [ 'foo', { 'bar': ['baz', None, 1.0, 1.5, 0.0001, 1000.0, 2, -23.1234, 2.0]} ]
# print hexify(obj_hash(t))

# t = [ 'foo', { 'b4r': ['baz', None, 1.0, 1.5, 0.0001, 1000.0, 2, -23.1234, 2.0]} ]
# print hexify(obj_hash(t))

# t = { 'thing1': { 'thing2': set((2, 1, 's')) }, 'thing3': 1234.567 }
# print hexify(obj_hash(t))

# t = { 'thing3': 1234.567, 'thing1': { 'thing2': set((2, 1, 's')) } }
# print hexify(obj_hash(t))

# t = { 'thing1': { 'thing2': set((1, 2, 't')) }, 'thing3': 1234.567 }
# print hexify(obj_hash(t))

# print hexify(obj_hash(.5))
