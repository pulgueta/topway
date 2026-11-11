import TopwayCore

@MainActor
enum NavigationDestination: Equatable {
    case main
    case addService(projectId: String, projectName: String)
    case variables(service: Service, project: Project)

    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case (.main, .main):
            return true
        case (.addService(let lhsId, let lhsName), .addService(let rhsId, let rhsName)):
            return lhsId == rhsId && lhsName == rhsName
        case (
            .variables(let lhsService, let lhsProject), .variables(let rhsService, let rhsProject)
        ):
            return lhsService.id == rhsService.id && lhsProject.id == rhsProject.id
        default:
            return false
        }
    }
}
