import AppIntents
import UIKit

// MARK: - Open Inbox Intent
@available(iOS 16.0, *)
struct OpenInboxIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Inbox"
    static var description = IntentDescription("Opens Poke directly to your Inbox.")
    
    // Forces the app to open when this shortcut runs
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        if let url = URL(string: "poke://inbox") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        return .result()
    }
}

// MARK: - Registers Poke in the iOS Shortcuts App & Siri
@available(iOS 16.0, *)
struct PokeAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenInboxIntent(),
            phrases: [
                "Open Inbox in \(.applicationName)",
                "Check my \(.applicationName) Inbox",
                "Open \(.applicationName) Inbox"
            ],
            shortTitle: "Open Inbox",
            systemImageName: "tray.fill"
        )
    }
}
