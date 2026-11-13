import Foundation

struct CapturedRequest: Sendable {
    let url: URL?
    let method: String?
    let authorization: String?
    let timeout: TimeInterval
    /// `nil` when the body is missing or is not valid JSON with this field.
    let query: String?
    /// `nil` when the body is missing or is not valid JSON with this field.
    let variables: [String: String]?
    /// The variables as JSON text with sorted keys, for variables that are not all text.
    let variablesJSON: String?
    let contentType: String?
    /// The fields of an `application/x-www-form-urlencoded` body. `nil` for another body.
    let form: [String: String]?

    init(_ request: URLRequest) {
        url = request.url
        method = request.httpMethod
        authorization = request.value(forHTTPHeaderField: "Authorization")
        timeout = request.timeoutInterval
        contentType = request.value(forHTTPHeaderField: "Content-Type")

        let body = Self.readBody(of: request)
        form = contentType == "application/x-www-form-urlencoded" ? body.flatMap(Self.form) : nil
        let json = body.flatMap {
            try? JSONSerialization.jsonObject(with: $0) as? [String: Any]
        }
        query = json?["query"] as? String
        variables = json?["variables"] as? [String: String]
        variablesJSON = (json?["variables"]).flatMap {
            try? JSONSerialization.data(
                withJSONObject: $0, options: [.sortedKeys, .withoutEscapingSlashes])
        }.map { String(decoding: $0, as: UTF8.self) }
    }

    private static func form(from body: Data) -> [String: String]? {
        var components = URLComponents()
        components.percentEncodedQuery = String(decoding: body, as: UTF8.self)
        guard let items = components.queryItems else { return nil }
        return Dictionary(items.map { ($0.name, $0.value ?? "") }) { first, _ in first }
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
