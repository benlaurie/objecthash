//
//  ObjectHashTests.swift
//  ObjectHashTests
//
//  Created by Denis Zenin on 08/08/2018.
//  Copyright © 2018 VChain Technology Limited. All rights reserved.
//

@testable import ObjectHash

import XCTest

class ObjectHashTests: XCTestCase {
    func testToHex() {
        let testString = "\"SUP MELLO?\""
        let expectedHashString = "a45b200d2032a5f9960f99bbb01cc81ca311a3c4abc9d51ddc87ea39f9588e54"

        do {
            let hash = try ObjectHash.pythonJsonHash(json: testString)
            XCTAssertEqual(expectedHashString, hash.toString())
        } catch {
            print("ERROR: ", error)
            XCTFail()
        }
    }

    func testNumberNormalization() {
        let expectedNormalizations = [
            1.0: "+0:1",
            1.5: "+1:011",
            2.0: "+1:1",
            1000.0: "+10:01111101",
            0.0001: "+-13:011010001101101110001011101011000111000100001100101101",
            -23.1234: "-5:010111000111111001011100100100011101000101001110001111"
        ]

        for expectation in expectedNormalizations {
            let normalized = try! ObjectHash.normalizeFloat(expectation.key)
            XCTAssertEqual(expectation.value, normalized)
        }
    }

    func runTest(json: String, expectedHash: String) throws {
        let expected = try ObjectHash.fromHex(hex: expectedHash).toString()
        let hash = try ObjectHash.pythonJsonHash(json: json).toString()

        XCTAssertEqual(expected, hash)
    }

    func test32BitIntegers() throws {
        try runTest(
            json: "[123]",
            expectedHash: "2e72db006266ed9cdaa353aa22b9213e8a3c69c838349437c06896b1b34cee36"
        );
        try runTest(json: "[1, 2, 3]",
            expectedHash: "925d474ac71f6e8cb35dd951d123944f7cabc5cda9a043cf38cd638cc0158db0"
        );
    }

    func test64BitIntegers() throws {
        try runTest(
            json: "[123456789012345]",
            expectedHash: "f446de5475e2f24c0a2b0cd87350927f0a2870d1bb9cbaa794e789806e4c0836"
        );
        try runTest(
            json: "[123456789012345, 678901234567890]",
            expectedHash: "d4cca471f1c68f62fbc815b88effa7e52e79d110419a7c64c1ebb107b07f7f56"
        );
    }

    func testWithCommonObjectHashTests() {
        let bundle = Bundle(for: type(of: self))
        if let path = bundle.path(forResource: "common_json", ofType: "test") {
            do {
                let data = try String(contentsOfFile: path, encoding: .utf8)
                let fileLines = data.components(separatedBy: .newlines)
                var linesIterator = fileLines.makeIterator()

                while let line = linesIterator.next() {
                    if line.isEmpty || line.starts(with: "#") || line.starts(with: "~#") {
                        continue
                    }

                    if let nextLine = linesIterator.next() {
                        try runTest(json: line, expectedHash: nextLine)
                    }
                }
            } catch {
                print("COMMON TEST FAILED. ERROR: \(error)")
                XCTFail()
            }
        }
    }

    func testHashRedaction() throws {
        let jsonPart = "{\"field1\": \"value\", \"field2\": \"value2\"}"
        let partHash = try ObjectHash.pythonJsonHash(json: jsonPart)
        let redactedPartHash = try Redacted.pythonJsonHash(json: jsonPart)

        let jsonFull = "{\"field3\": \"value3\", \"part\": \(jsonPart)}";
        let jsonFullWithRedacted = "{\"field3\": \"value3\", \"part\": \"\(redactedPartHash.toString())\"}";

        XCTAssertTrue(jsonFullWithRedacted.contains(partHash.toString()))

        let fullHash = try ObjectHash.pythonJsonHash(json: jsonFull)
        let fullWithRedactedHash = try ObjectHash.pythonJsonHash(json: jsonFullWithRedacted)

        XCTAssertEqual(fullHash, fullWithRedactedHash)
    }

    func testRedactedHashWorksSimilarToObjectHash() throws {
        let jsonPart = "{\"field1\": \"value\", \"field2\": \"value2\"}"
        let objectHashString = try ObjectHash.pythonJsonHash(json: jsonPart).toString()

        let redactedHashString = try Redacted.pythonJsonHash(json: jsonPart).toString()
        let redactedHashStringCleaned = redactedHashString.replacingOccurrences(of: Redacted.PREFIX, with: "")

        XCTAssertNotEqual(objectHashString, redactedHashString)
        XCTAssertEqual(objectHashString, redactedHashStringCleaned)
    }
}
