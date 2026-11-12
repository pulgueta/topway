/// What to do after one answer about the workflow that deploys a template.
enum WorkflowStep: Equatable {
    case done
    case wait
    case failed(String)
}
