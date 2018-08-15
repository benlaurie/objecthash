import CryptoSwift

public typealias Byte = UInt8
public typealias BytesArray = [Byte]
public typealias Object = [String: Any]

public class ObjectHash {
    public internal(set) var hash: BytesArray = []
    private var digester = SHA2(variant: .sha256)
    
    public class func fromHex(hex: String) throws -> ObjectHash {
        let h = ObjectHash()
        var hex = hex.lowercased()

        if hex.count % 2 == 1 {
            hex = "0" + hex
        }
        
        for idx in stride(from: hex.count, to: 0, by: -2) {
            let firstChar = hex[idx - 2]
            let secondChar = hex[idx - 1]
            let num = try 16 * parseHex(char: firstChar) + parseHex(char: secondChar)

            h.hash.insert(Byte(num), at: 0)
        }

        return h
    }

    private class func parseHex(char: Character) throws -> Int {
        guard let num = Int(String(char), radix: 16) else {
            throw ErrorObjectHash.invalidHexStringCharacter
        }

        return num
    }

    public func toString() -> String {
        return convertToHex(hash)
    }
    
    public class func fromBytes(hash: BytesArray) -> ObjectHash {
        let h = ObjectHash();
        h.hash = hash

        return h
    }

    private func getType(_ jsonObj: Any) -> JsonType {
        if jsonObj is NSNull {
            return .null
        }

        if isJsonBool(jsonObj) {
            return .boolean
        }

        if jsonObj is Int || jsonObj is Double {
            return .number
        }

        if isJsonArray(jsonObj) {
            return .array
        }

        if let _ = jsonObj as? Object {
            return .object
        }

        if let s = jsonObj as? String {
            if s.starts(with: Redacted.PREFIX) {
                return .redacted
            }

            return .string
        }

        return .unknown
    }

    private func isJsonBool(_ value: Any) -> Bool {
        return type(of: value) == type(of: NSNumber(value: true))
    }

    private func isJsonArray(_ x: Any) -> Bool {
        if let _ = x as? [Any] {
            return true
        }
        if let _ = x as? [AnyObject] {
            return true
        }
        if let _ = x as? NSArray {
            return true
        }

        return false
    }

    class func normalizeFloat(_ float: Double) throws -> String {
        var f = float
        // Early our for zero
        if f == 0.0 {
            return "+0:"
        }

        var normString = ""
        var sign = "+"
        if f < 0.0 {

            sign = "-"
            f = -f
        }

        normString += sign

        // Exponent
        var e = 0
        while f > 1 {
            f /= 2
            e += 1
        }
        while f < 0.5 {
            f *= 2
            e -= 1
        }

        normString += "\(e):"

        // Mantissa
        if f > 1 || f <= 0.5 {
            throw ErrorObjectHash.wrongRangeForMantissa
        }

        while f != 0 {
            if f >= 1 {
                normString += "1"
                f -= 1
            } else {
                normString += "0"
            }

            if f >= 1 {
                throw ErrorObjectHash.floatIsTooBig
            }

            if normString.count > 1000 {
                throw ErrorObjectHash.floatIsTooBig
            }

            f *= 2
        }

        return normString
    }
    
    private func hashTaggedBytes(tag: String, bytes: BytesArray) throws {
        _ = try digester.update(withBytes: tag.toBytes() + bytes)
        hash = try digester.finish()
    }

    private func hashString(_ str: String) throws {
        try hashTaggedBytes(tag: "u", bytes: str.toBytes())
    }

    private func hashNumber(_ double: Double) throws {
        let normalized = try ObjectHash.normalizeFloat(double)
        try hashTaggedBytes(tag: "f", bytes: normalized.toBytes())
    }

    private func hashNull() throws {
        try hashTaggedBytes(tag: "n", bytes: [])
    }

    private func hashBoolean(bool: Bool) throws {
        let boolString = bool ? "1" : "0"
        try hashTaggedBytes(tag: "b", bytes: boolString.toBytes())
    }
    
    private func hashAny(_ object: Any) throws {
        let outerType = getType(object)

        switch outerType {
        case .array: try hashList(object as! [Any])
        case .object: try hashObject(object as! [String: Any])
        case .string: try hashString(object as! String)
        case .boolean: try hashBoolean(bool: object as! Bool)
        case .number: try hashNumber(object as! Double)
        case .redacted: hash = try Redacted.fromString(object as! String).hash;
        case .null: try hashNull()
        default: throw ErrorObjectHash.illegalTypeInJSON(type: outerType.rawValue)
        }
    }

    private func hashList(_ list: [Any]) throws {
        resetDigester()
        _ = try digester.update(withBytes: "l".toBytes())

        for element in list {
            let innerObject = ObjectHash()
            try innerObject.hashAny(element)
            _ = try digester.update(withBytes: innerObject.hash)
        }

        hash = try digester.finish()
    }

    private func hashObject(_ object: Object) throws {
        let keys = Array(object.keys)
        var keysIterator = keys.makeIterator()

        var buffers: [BytesArray] = []

        while let key = keysIterator.next() {
            //todo: experiment with chaining
            var buff: BytesArray = []
            let hKey = ObjectHash()
            try hKey.hashString(key)
            
            guard let value = object[key] else {
                throw ErrorObjectHash.missingValueInDictionary
            }
            
            let hVal = ObjectHash()
            try hVal.hashAny(value)

            buff += hKey.hash
            buff += hVal.hash

            buffers.append(buff)
        }

        buffers.sort(by: <)
        resetDigester()
        _ = try digester.update(withBytes: "d".toBytes())

        for buff in buffers {
            _ = try digester.update(withBytes: buff)
        }

        hash = try digester.finish()
    }

    public class func pythonJsonHash(json: String) throws -> ObjectHash {
        let h = ObjectHash()
        let jsonObj = try getJsonObject(from: json)

        try h.hashAny(jsonObj)
        return h
    }

    private class func getJsonObject(from text: String) throws -> Any {
        guard let data = text.data(using: .utf8) else {
            throw ErrorObjectHash.invalidJsonString
        }

        // to prevent JSONSerialization treating floating point numbers as NSDecimal
        // because NSDecimal has radix 10 and differs from Double (radix 2)
        if let floatingPointNumber = Double(text) {
            return floatingPointNumber
        }

        guard let jsonObj = try? JSONSerialization.jsonObject(with: data, options: [.allowFragments]) else {
            throw ErrorObjectHash.invalidJson
        }

        return jsonObj
    }

    private func resetDigester() {
        digester = SHA2(variant: .sha256)
    }

    private enum JsonType: String {
        case boolean
        case array
        case object
        case number
        case string
        case null
        case unknown
        case redacted
    }
}

func convertToHex(_ buffer: BytesArray) -> String {
    var hexString = ""

    for byte in buffer {
        let hex = String(format: "%02X", byte)
        hexString.append(hex)
    }

    return hexString.lowercased()
}

extension ObjectHash: Equatable {
    static public func ==(lhs: ObjectHash, rhs: ObjectHash) -> Bool {
        if lhs.toString() != rhs.toString() {
            return false
        }

        return true
    }
}

extension ObjectHash: Comparable {
    static public func <(lhs: ObjectHash, rhs: ObjectHash) -> Bool {
        return lhs.toString() < rhs.toString()
    }
}

class Redacted: ObjectHash {
    public static let PREFIX = "**REDACTED**"
    
    public class func fromString(_ representation: String) throws -> Redacted {
        let hexString = representation.replacingOccurrences(of: Redacted.PREFIX, with: "")
        let underlyingHash = try self.fromHex(hex: hexString)
        return Redacted(hash: underlyingHash.hash)
    }
    
    init(hash: BytesArray) {
        super.init()
        self.hash = hash
    }

    override class func pythonJsonHash(json: String) throws -> Redacted {
        let hash = try ObjectHash.pythonJsonHash(json: json).hash
        
        return Redacted(hash: hash)
    }
    
    override public func toString() -> String {
        return "\(Redacted.PREFIX)\(super.toString())"
    }
}

extension Array where Element == Byte {
    static public func <(lhs: BytesArray, rhs: BytesArray) -> Bool {
        return convertToHex(lhs) < convertToHex(rhs)
    }
}

extension String {
    subscript(i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }

    func toBytes() -> BytesArray {
        return Array(self.utf8)
    }
}

enum ErrorObjectHash: Error {
    case invalidHexStringCharacter
    case wrongRangeForMantissa
    case floatIsTooBig
    case normalizedFloatLengthIsTooBig
    case illegalTypeInJSON(type: String)
    case invalidJson
    case invalidJsonString
    case missingValueInDictionary
}
