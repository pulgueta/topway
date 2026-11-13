import Foundation

/// Encodes fields for a URL query or an `application/x-www-form-urlencoded` body.
/// Only the unreserved characters of RFC 3986 stay as they are, so a `+`, a `&` or a space
/// in a value cannot change its meaning. `URLComponents.queryItems` does not encode `+`.
enum FormEncoding {
    private static let unreserved = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")

    static func encode(_ fields: KeyValuePairs<String, String>) -> String {
        fields.map { "\(escape($0.key))=\(escape($0.value))" }.joined(separator: "&")
    }

    private static func escape(_ text: String) -> String {
        text.addingPercentEncoding(withAllowedCharacters: unreserved) ?? ""
    }
}
