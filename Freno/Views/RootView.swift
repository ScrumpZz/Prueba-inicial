import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Group {
            if model.hasOnboarded && model.isAuthorized {
                HomeView()
            } else {
                OnboardingView()
            }
        }
        .sheet(isPresented: $model.showUnlock, onDismiss: { model.cancelUnlock() }) {
            UnlockView()
                .environmentObject(model)
                .interactiveDismissDisabled()
        }
    }
}
