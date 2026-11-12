/// Keeps the selected environment of a screen valid when the environments of the project
/// change, for example after a delete.
public enum EnvironmentSelection {
    /// Gives the selection when it is still available, or else the first available
    /// environment, or `nil` when the project has no environments.
    public static func reconciled(_ selectedId: String?, available ids: [String]) -> String? {
        if let selectedId, ids.contains(selectedId) {
            return selectedId
        }
        return ids.first
    }
}
