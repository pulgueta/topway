/// A target of a variable value, with its status.
public struct ReferenceLink: Hashable, Identifiable, Sendable {
    public let target: ReferenceTarget
    public let status: ReferenceTargetStatus

    public var id: ReferenceTarget { target }

    public init(target: ReferenceTarget, status: ReferenceTargetStatus) {
        self.target = target
        self.status = status
    }

    /// Gives each target of a value one time, in the order of the value.
    /// - Parameter variables: `nil` when they did not load. Each status is then
    ///   `notChecked`.
    public static func links(
        in value: String, serviceId: String, services: [Service], variables: ProjectVariables?
    ) -> [ReferenceLink] {
        var seen: Set<ReferenceTarget> = []
        return VariableReference.all(in: value).compactMap { reference in
            guard seen.insert(reference.target).inserted else { return nil }
            return ReferenceLink(
                target: reference.target,
                status: variables?.status(
                    of: reference.target, from: serviceId, services: services) ?? .notChecked)
        }
    }
}
