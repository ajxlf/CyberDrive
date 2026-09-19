import SwiftUI

@main
struct CyberDriveApp: App {
    @UIApplicationDelegateAdaptor(CyberDriveAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(NavigationCoordinator.shared)
                .preferredColorScheme(.dark)
        }
    }
}
