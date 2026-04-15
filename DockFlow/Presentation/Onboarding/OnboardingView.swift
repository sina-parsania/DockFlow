import SwiftUI

public struct OnboardingView: View {
    @Bindable var state: AppState
    @State private var page: Int = 0

    public init(state: AppState) {
        self.state = state
    }

    public var body: some View {
        VStack(spacing: 20) {
            content
                .frame(maxHeight: .infinity)
            controls
        }
        .padding(28)
        .frame(width: 560, height: 420)
    }

    @ViewBuilder
    private var content: some View {
        switch page {
        case 0: welcomePage
        case 1: backupPage
        case 2: importPage
        default: EmptyView()
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 14) {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 104, height: 104)
                .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
            Text("Welcome to DockFlow").font(.title).fontWeight(.bold)
            Text("Create multiple Dock presets organized by your own categories. Switch them with a single click or a global hotkey.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 440)
        }
    }

    private var backupPage: some View {
        VStack(spacing: 14) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 54))
                .foregroundStyle(Color.accentColor)
            Text("Every change is reversible").font(.title2).fontWeight(.semibold)
            Text("DockFlow automatically backs up your current Dock before applying a preset, and keeps the last \(state.settings.maxBackupCount) backups so you can roll back at any time.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 440)
        }
    }

    private var importPage: some View {
        VStack(spacing: 14) {
            Image(systemName: "square.and.arrow.down.on.square")
                .font(.system(size: 54))
                .foregroundStyle(Color.accentColor)
            Text("Start from your current Dock").font(.title2).fontWeight(.semibold)
            Text("We can import your existing Dock into a preset so you have something to build on.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 440)
            HStack {
                Button("Skip") {
                    finish()
                }
                Button {
                    state.importCurrentDock(strategy: .byType)
                    finish()
                } label: {
                    Text("Import Dock")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 6)
        }
    }

    private var controls: some View {
        HStack {
            pageIndicator
            Spacer()
            if page > 0 {
                Button("Back") { page -= 1 }
            }
            if page < 2 {
                Button("Next") { page += 1 }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index == page ? Color.accentColor : .secondary.opacity(0.4))
                    .frame(width: 7, height: 7)
            }
        }
    }

    private func finish() {
        state.completeOnboarding()
    }
}
