struct WorkflowResult: Decodable {
    /// `Complete`, `Error`, `NotFound` or `Running`.
    let status: String
    let error: String?

    /// `Running` waits. `NotFound` and an unknown status also wait, because Railway can
    /// answer a new workflow with `NotFound` for a short time, as the Railway CLI expects.
    var step: WorkflowStep {
        switch status {
        case "Complete": .done
        case "Error": .failed(error ?? "Railway did not add the database.")
        default: .wait
        }
    }
}
