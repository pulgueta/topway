import TopwayCore

/// The screens that `MainView` shows. `ServiceView` has its own steps below `service`.
enum NavigationDestination: Equatable {
    case main
    case usage
    case addService(projectId: String, projectName: String)
    case environments(projectId: String, projectName: String)
    case service(service: Service, project: Project)

    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case (.main, .main), (.usage, .usage):
            return true
        case (.addService(let lhsId, let lhsName), .addService(let rhsId, let rhsName)):
            return lhsId == rhsId && lhsName == rhsName
        case (.environments(let lhsId, _), .environments(let rhsId, _)):
            return lhsId == rhsId
        case (.service(let lhsService, let lhsProject), .service(let rhsService, let rhsProject)):
            return lhsService.id == rhsService.id && lhsProject.id == rhsProject.id
        default:
            return false
        }
    }
}
