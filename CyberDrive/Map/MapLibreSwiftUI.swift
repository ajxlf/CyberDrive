import SwiftUI
import MapKit

struct CyberMap: UIViewControllerRepresentable {
    @EnvironmentObject private var navigation: NavigationCoordinator

    func makeUIViewController(context: Context) -> CyberMapViewController {
        CyberMapViewController(locationManager: navigation.locationManager)
    }

    func updateUIViewController(_ controller: CyberMapViewController, context: Context) {
        controller.setRoute(navigation.route)
    }
}
