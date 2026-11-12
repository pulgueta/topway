import TopwayCore

/// A database add has two steps, so the confirmation dialog can close when Railway
/// accepts the deploy. The wait that follows belongs to the form, which can stop it.
extension AppState {
    /// Asks Railway to add a database to a project. When `isAccepted` is `true`, Railway
    /// makes the database, and a second add would make a second database.
    func startDatabase(_ template: DatabaseTemplate, projectId: String, environmentId: String)
        async -> (isAccepted: Bool, workflowId: String?)
    {
        let workflowId = await run {
            try await $0.deployDatabase(
                template, projectId: projectId, environmentId: environmentId, token: $1)
        }
        // The outer `nil` is a failed request. The inner `nil` is a deploy with no workflow.
        guard let workflowId else { return (false, nil) }
        return (true, workflowId)
    }

    /// Waits for an accepted deploy, then loads the projects again. It never reports the
    /// add as failed because a status request failed: the message then says that the
    /// database can show later. Only a workflow that Railway reports as failed shows an
    /// error.
    func finishDatabase(_ template: DatabaseTemplate, workflowId: String?) async {
        var result: DatabaseDeployResult? = .complete
        if let workflowId {
            result = await run { try await $0.waitForDatabase(workflowId: workflowId, token: $1) }
        }
        // After Close, the form loads the projects. A load from this cancelled task would
        // fail and could replace that load.
        guard !Task.isCancelled else { return }
        // The project load removes the message, so keep the error of the workflow.
        let workflowError = errorMessage
        await loadProjects()
        switch result {
        case .complete:
            break
        case .pending:
            errorMessage =
                "Railway accepted \(template.title), but Topway did not see the result in 60 seconds. "
                + "Select Refresh later to see the database. Do not add it again."
        case nil:
            if let workflowError {
                errorMessage = workflowError
            }
        }
    }
}
