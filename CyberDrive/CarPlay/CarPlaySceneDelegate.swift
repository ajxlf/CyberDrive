import CarPlay
import CoreLocation
import MapKit
import UIKit

@MainActor
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate, CPMapTemplateDelegate {
    private let navigation = NavigationCoordinator.shared
    private let guidance = NavigationGuidance()
    private var interfaceController: CPInterfaceController?
    private var mapTemplate: CPMapTemplate?
    private var mapViewController: CyberMapViewController?
    private var navigationSession: CPNavigationSession?
    private var currentTrip: CPTrip?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController,
        to window: CPWindow
    ) {
        self.interfaceController = interfaceController

        let mapController = CyberMapViewController(locationManager: navigation.locationManager)
        self.mapViewController = mapController
        window.rootViewController = mapController

        let mapTemplate = CPMapTemplate()
        self.mapTemplate = mapTemplate
        mapTemplate.mapDelegate = self
        mapTemplate.automaticallyHidesNavigationBar = false
        mapTemplate.guidanceBackgroundColor = NeonPalette.background

        let searchButton = CPMapButton { [weak self] _ in
            self?.presentSearch()
        }
        searchButton.image = UIImage(systemName: "magnifyingglass")
        mapTemplate.mapButtons = [searchButton]

        interfaceController.setRootTemplate(mapTemplate, animated: false)

        if let route = navigation.route {
            presentTrip(for: route)
        }
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController,
        from window: CPWindow
    ) {
        self.interfaceController = nil
        self.mapTemplate = nil
        self.mapViewController = nil
        self.navigationSession = nil
        self.currentTrip = nil
    }

    private func presentTrip(for route: MKRoute) {
        guard let trip = navigation.makeTrip(), let mapTemplate else { return }
        currentTrip = trip
        mapViewController?.setRoute(route)
        mapTemplate.showRouteChoicesPreview(for: trip, textConfiguration: nil)
    }

    private func presentSearch() {
        guard let interfaceController else { return }
        let search = CPSearchTemplate()
        let delegate = CarPlaySearchDelegate(navigation: navigation) { [weak self] item in
            Task { @MainActor in
                await self?.setDestination(item)
            }
        }
        search.delegate = delegate
        SearchDelegateHolder.shared.delegate = delegate
        interfaceController.pushTemplate(search, animated: true)
    }

    private func setDestination(_ item: MKMapItem) async {
        await navigation.setDestination(item)
        guard let route = navigation.route else { return }
        mapViewController?.setRoute(route)
        presentTrip(for: route)
    }

    func mapTemplate(_ mapTemplate: CPMapTemplate, selectedPreviewFor trip: CPTrip, using routeChoice: CPRouteChoice) {
        if let route = navigation.route {
            mapViewController?.setRoute(route)
        }
    }

    func mapTemplate(_ mapTemplate: CPMapTemplate, startedTrip trip: CPTrip, using routeChoice: CPRouteChoice) {
        guard let route = navigation.route else { return }
        let session = mapTemplate.startNavigationSession(for: trip)
        navigationSession = session
        let maneuvers = guidance.maneuvers(for: route)
        session.upcomingManeuvers = maneuvers
        let travel = CPTravelEstimates(
            distanceRemaining: Measurement(value: route.distance, unit: .meters),
            timeRemaining: route.expectedTravelTime
        )
        mapTemplate.updateEstimates(travel, for: trip)
        if let first = maneuvers.first {
            session.updateEstimates(travel, for: first)
            guidance.speak(first.instructionVariants.first ?? "Begin navigation.")
        }
    }

    func mapTemplateDidCancelNavigation(_ mapTemplate: CPMapTemplate) {
        navigationSession?.cancelTrip()
        navigationSession = nil
    }

    func mapTemplate(_ mapTemplate: CPMapTemplate, displayStyleFor maneuver: CPManeuver) -> CPManeuverDisplayStyle {
        .leadingSymbol
    }
}

@MainActor
private final class SearchDelegateHolder {
    static let shared = SearchDelegateHolder()
    var delegate: CarPlaySearchDelegate?
}

@MainActor
private final class CarPlaySearchDelegate: NSObject, CPSearchTemplateDelegate {
    private let navigation: NavigationCoordinator
    private let onSelect: (MKMapItem) -> Void

    init(navigation: NavigationCoordinator, onSelect: @escaping (MKMapItem) -> Void) {
        self.navigation = navigation
        self.onSelect = onSelect
    }

    func searchTemplate(
        _ searchTemplate: CPSearchTemplate,
        updatedSearchText searchText: String,
        completionHandler: @escaping ([CPListItem]) -> Void
    ) {
        Task {
            let found = (try? await RoutingService.shared.search(searchText, near: navigation.currentLocation)) ?? []
            let items: [CPListItem] = found.map { result in
                let item = CPListItem(text: result.title, detailText: result.subtitle)
                item.userInfo = result.mapItem
                return item
            }
            completionHandler(items)
        }
    }

    func searchTemplate(
        _ searchTemplate: CPSearchTemplate,
        selectedResult item: CPListItem,
        completionHandler: @escaping () -> Void
    ) {
        if let mapItem = item.userInfo as? MKMapItem {
            onSelect(mapItem)
        }
        completionHandler()
    }

    func searchTemplateSearchButtonPressed(_ searchTemplate: CPSearchTemplate) {}
}
