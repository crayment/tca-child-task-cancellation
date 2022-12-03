import SwiftUI

@main
struct TCA_Child_Task_CancellationApp: App {
    var body: some Scene {
        WindowGroup {
            ParentView(
                store: .init(
                    initialState: .init(),
                    reducer: Parent()
                        ._printChanges()
                )
            )
        }
    }
}
