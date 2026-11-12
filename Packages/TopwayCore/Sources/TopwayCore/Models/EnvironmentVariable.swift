public struct EnvironmentVariable: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    /// `nil` for a sealed variable: Railway gives its name, but never its value.
    public let value: String?

    public init(name: String, value: String?) {
        self.id = name
        self.name = name
        self.value = value
    }

    public var isSealed: Bool {
        value == nil
    }

    /// Whether the editor can save `value` as the variable `name`. Railway gives no value
    /// for a sealed variable, so the editor starts empty, and an empty value would replace
    /// the sealed value with nothing. This is also true when Add variable has the name of a
    /// sealed variable.
    /// - Parameter sealedNames: The names of the sealed variables of the service in the
    ///   environment.
    public static func permitsSave(of value: String, as name: String, sealedNames: Set<String>)
        -> Bool
    {
        !value.isEmpty || !sealedNames.contains(name.trimmingCharacters(in: .whitespaces))
    }
}

extension EnvironmentVariable {
    /// One `NAME=value` line for a dotenv file. A value with a line break or a double
    /// quotation mark is put in double quotation marks with escapes, so it stays on one line.
    /// A sealed variable gives a comment with its name, because Railway does not give its value.
    public var dotenvLine: String {
        guard let value else {
            return "# \(name) is sealed. Railway does not show its value."
        }
        let scalars = value.unicodeScalars
        guard scalars.contains(where: { $0 == "\n" || $0 == "\r" || $0 == "\"" }) else {
            return "\(name)=\(value)"
        }

        var escaped = ""
        for scalar in scalars {
            switch scalar {
            case "\\": escaped += "\\\\"
            case "\"": escaped += "\\\""
            case "\n": escaped += "\\n"
            case "\r": escaped += "\\r"
            default: escaped.unicodeScalars.append(scalar)
            }
        }
        return "\(name)=\"\(escaped)\""
    }
}
