import SwiftUI
import TopwayCore

/// The copy of the projects list for the first page: the real rows of the projects screen
/// with the sample projects.
struct ProjectsFragment: View {
    let projects: [Project]

    var body: some View {
        FragmentWindow {
            ScreenLayout {
                // The same spaces as the list of `ProjectsScreen`.
                VStack(alignment: .leading, spacing: 4) {
                    SpendRow {}

                    ForEach(projects) { project in
                        ProjectRow(
                            project: project,
                            onAddService: {},
                            onOpenEnvironments: {},
                            onOpenServiceLinks: {},
                            onRequestDelete: {},
                            onServiceTap: { _ in }
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(maxHeight: .infinity, alignment: .top)
            } top: {
                FragmentProjectsHeader(showsRefresh: true)
            } bottom: {
                // The stage cuts the bottom of the window, so the copy has no bottom bar.
                EmptyView()
            }
        }
    }
}
