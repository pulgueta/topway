import Foundation
import Testing

@testable import TopwayCore

struct JSONValueTests {
    private let value: JSONValue = .object([
        "text": "a \"b\"", "none": .null, "flag": .bool(true), "count": .number(3),
        "list": .array(["x", .number(1.5)]), "inner": .object(["key": "value"]),
    ])
    private let json =
        #"{"count":3,"flag":true,"inner":{"key":"value"},"list":["x",1.5],"none":null,"text":"a \"b\""}"#

    @Test("Each kind of value encodes as JSON, and null stays in the object")
    func encode() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        #expect(String(decoding: try encoder.encode(value), as: UTF8.self) == json)
    }

    @Test("JSON decodes to the same value")
    func decode() throws {
        #expect(try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8)) == value)
    }
}
