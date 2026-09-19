import Combine
import CoreLocation
import MapKit

@MainActor
final class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()

    let locationManager = LocationManager()
    private let routing = RoutingService.shared

    @Published private(set) var destination: MKMapItem?
    @Published private(set) var route: MKRoute?
    @Published private(set) var isRouting = false
    @Published private(set) var errorMessage: String?

    private init() {
        locationManager.requestAndStart()
    }

    var currentLocation: CLLocation? { locationManager.location }

    func clearError() {
        errorMessage = nil
    }

    func setDestination(_ item: MKMapItem) async {
        destination = item
        await calculateRoute()
    }

    func calculateRoute() async {
        guard let currentLocation, let destination else { return }
        isRouting = true
        errorMessage = nil
        defer { isRouting = false }

        do {
            route = try await routing.route(from: currentLocation.coordinate, to: destination.placemark.coordinate)
        } catch {
            route = nil
            errorMessage = error.localizedDescription
        }
    }

    func makeTrip() -> CPTrip? {
        guard let currentLocation, let destination, let route else { return nil }
        let origin = MKMapItem(placemark: MKPlacemark(coordinate: currentLocation.coordinate))
        let eta = route.expectedTravelTime
        let distance = route.distance
        let estimates = CPTravelEstimates(
            distanceRemaining: Measurement(value: distance, unit: .meters),
            timeRemaining: eta
        )
        let choice = CPRouteChoice(
            summaryVariants: [route.steps.first?.instructions ?? "Recommended route"],
            additionalInformationVariants: ["CYBER ROUTE"],
            selectionSummaryVariants: ["START NEON ROUTE"]
        )
        _ = estimates
        return CPTrip(origin: origin, destination: destination, routeChoices: [choice])
    }
}
