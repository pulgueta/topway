import SwiftUI
import TopwayCore

/// Shows what the lists below belong to: the project and the environment.
/// It also holds the tabs of the service screen.
struct ServiceContextBar: View {
    let projectName: String
    let environments: [RailwayEnvironment]
    @Binding var selectedEnvironmentId: String?
    @Binding var tab: ServiceTab

    var body: some View {
        VStack(spacing: Layout.controlSpacing) {
            HStack(spacing: Layout.controlSpacing) {
                Label(projectName, systemImage: "folder")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .accessibilityLabel("Project: \(projectName)")

                Spacer(minLength: Layout.controlSpacing)

                if environments.count > 1 {
                    Picker("Environment", selection: $selectedEnvironmentId) {
                        ForEach(environments) { environment in
                            Text(environment.name).tag(Optional(environment.id))
                        }
                    }
                    .fixedSize()
                    .help(
                        "The variables, deployments and metrics below belong to this environment.")
                } else if let environment = environments.first {
                    Text("Environment: \(environment.name)")
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .font(.callout)

            Picker("List", selection: $tab) {
                Text("Variables").tag(ServiceTab.variables)
                Text("Deployments").tag(ServiceTab.deployments)
                Text("Metrics").tag(ServiceTab.metrics)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(.horizontal, Layout.barPadding)
        .padding(.bottom, Layout.controlSpacing)
    }
}
