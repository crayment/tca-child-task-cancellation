import SwiftUI
import ComposableArchitecture

struct Parent: ReducerProtocol {
    struct State: Equatable {
        var count = 0
        var child: Child.State?
    }
    enum Action: Equatable {
        case child(Child.Action)
        case showSheetTapped
        case childShowingChanged(Bool)
        case delayedWork
    }
    
    @Dependency(\.continuousClock) var clock
    
    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .child(.hook):
                state.child = nil // Cancels child task by tearing down child view in real app
                return .task {
                    // A small delay on the child's hook before we take further action in the parent.
                    // This task ends up cancelled and delayedWork action never runs
                    try await clock.sleep(for: .seconds(1))
                    return .delayedWork
                }
            case .child:
                return .none
            case .showSheetTapped:
                state.child = .init()
                return .none
            case .childShowingChanged:
                return .none
            case .delayedWork:
                state.count += 1
                return .none
            }
        }
        .ifLet(\.child, action: /Action.child) {
            Child()
        }
    }
}

struct ParentView: View {
    let store: StoreOf<Parent>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                Text(String(viewStore.count))
                Button {
                    viewStore.send(.showSheetTapped)
                } label: {
                    Text("Show Sheet!")
                }
            }
            .padding()
            .sheet(isPresented: .init(get: {
                viewStore.child != nil
            }, set: { showing in
                viewStore.send(.childShowingChanged(showing))
            })) {
                IfLetStore(store.scope(state: \.child, action: Parent.Action.child), then: ChildView.init(store:))
            }
        }
    }
}

struct Child: ReducerProtocol {
    struct State: Equatable {}
    enum Action: Equatable {
        case task
        case hook
    }
    
    @Dependency(\.continuousClock) var clock
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .task:
            return .task {
                try await clock.sleep(for: .seconds(1))
                return .hook
            }
        case .hook:
            return .none
        }
    }
}

struct ChildView: View {
    let store: StoreOf<Child>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            Text("Child")
                .task { await viewStore.send(.task).finish() }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ParentView(store: .init(initialState: .init(), reducer: Parent()))
    }
}
