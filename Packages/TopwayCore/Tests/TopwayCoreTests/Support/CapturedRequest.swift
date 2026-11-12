import Foundation

struct CapturedRequest: Sendable {
    let url: URL?
    let method: String?
    let authorization: String?
    /// `nil` when the body is missing or is not valid JSON with this field.
    let query: String?
    /// `nil` when the body is missing or is not valid JSON with this field.
    let variables: [String: String]?
    /// The variables as JSON text with sorted keys, for variables that are not all text.
    let variablesJSON: String?

    init(_ request: URLRequest) {
        url = request.url
        method = request.httpMethod
        authorization = request.value(forHTTPHeaderField: "Authorization")

        let json = Self.readBody(of: request).flatMap {
            try? JSONSerialization.jsonObject(with: $0) as? [String: Any]
        }
        query = json?["query"] as? String
        variables = json?["variables"] as? [String: String]
        variablesJSON = (json?["variables"]).flatMap {
            try? JSONSerialization.data(
                withJSONObject: $0, options: [.sortedKeys, .withoutEscapingSlashes])
        }.map { String(decoding: $0, as: UTF8.self) }
    }

    // URLSession moves the body of a request into a stream before URLProtocol reads it.
    private static func readBody(of request: URLRequest) -> Data? {
        guard let stream = request.httpBodyStream else { return request.httpBody }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        stream.open()
        defer { stream.close() }
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(contentsOf: buffer[0..<count])
        }
        return data
    }
}
