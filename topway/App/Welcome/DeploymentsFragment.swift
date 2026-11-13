import SwiftUI
import TopwayCore

/// The copy for the actions page: the Deployments tab of a sample service, with the real
/// header, context bar and deployment rows of the service screen.
struct DeploymentsFragment: View {
    let sample: WelcomeSample

    var body: some View {
        FragmentWindow {
            if let project = sample.project, let environment = sample.environment,
                let service = sample.service
            {
                VStack(spacing: 0) {
                    ScreenHeader(title: service.name, backTitle: "Projects", onBack: {}) {
                        ServiceMenu(
                            serviceName: service.name,
                            isRedeploying: false,
                            hasEnvironment: true,
                            onShowSettings: {},
                            onShowDomains: {},
                            onRedeploy: {},
                            onRequestDelete: {}
                        )
                    }

                    ServiceContextBar(
                        projectName: project.name,
                        environments: project.environmentList,
                        selectedEnvironmentId: .constant(environment.id),
                        tab: .constant(.deployments)
                    )

                    ForEach(sample.deployments) { deployment in
                        DeploymentRow(
                            deployment: deployment,
                            isRestarting: false,
                            onRestart: {},
                            onOpenURL: {},
                            onViewLogs: {}
                        )
                    }
                }
            }
        }
    }
}
