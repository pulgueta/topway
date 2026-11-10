enum VariablesViewDestination: Equatable {
    case list
    case edit(EnvironmentVariable?)
    case deployments

    static func == (lhs: VariablesViewDestination, rhs: VariablesViewDestination) -> Bool {
        switch (lhs, rhs) {
        case (.list, .list), (.deployments, .deployments):
            return true
        case (.edit(let lhsVar), .edit(let rhsVar)):
            return lhsVar?.id == rhsVar?.id
        default:
            return false
        }
    }
}
