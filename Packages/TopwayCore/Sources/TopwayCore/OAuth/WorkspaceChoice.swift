/// Selects the workspace after a sign-in, from the workspaces that the user shared with
/// Topway on the consent page.
public enum WorkspaceChoice {
    /// The saved workspace when the account still has it, else the only workspace. `nil` when
    /// the user must choose from several, or when the account shared no workspace.
    public static func selection(saved: String, in workspaces: [WorkspaceSummary]) -> String? {
        if workspaces.contains(where: { $0.id == saved }) {
            return saved
        }
        return workspaces.count == 1 ? workspaces.first?.id : nil
    }
}
