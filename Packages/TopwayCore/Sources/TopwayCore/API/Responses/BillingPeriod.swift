import Foundation

struct BillingPeriod: Decodable, Sendable {
    let start: Date
    let end: Date

    private enum CodingKeys: String, CodingKey {
        case start
        case end
    }

    /// Railway gives a date with or without fractions of a second.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        func date(_ key: CodingKeys) throws -> Date {
            let text = try container.decode(String.self, forKey: key)
            let withFractions = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
            if let date = (try? Date(text, strategy: .iso8601))
                ?? (try? Date(text, strategy: withFractions))
            {
                return date
            }
            throw DecodingError.dataCorruptedError(
                forKey: key, in: container, debugDescription: "Not an ISO 8601 date: \(text)")
        }
        start = try date(.start)
        end = try date(.end)
    }
}
