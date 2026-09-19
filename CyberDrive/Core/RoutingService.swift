import MapKit

struct SearchResult: Identifiable {
    let id = UUID()
    let mapItem: MKMapItem

    var title: String { mapItem.name ?? "Unknown location" }
    var subtitle: String {
        let placemark = mapItem.placemark
        return [placemark.locality, placemark.administrativeArea]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}

final class RoutingService {
    static let shared = RoutingService()

    func search(_ query: String, near location: CLLocation?) async throws -> [SearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        if let location {
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 30_000,
                longitudinalMeters: 30_000
            )
        }
        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems.prefix(8).map(SearchResult.init)
    }

    func route(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> MKRoute {
        let source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        let target = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        return try await route(from: source, to: target)
    }

    func route(from origin: MKMapItem, to destination: MKMapItem) async throws -> MKRoute {
        let request = MKDirections.Request()
        request.source = origin
        request.destination = destination
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        let response = try await MKDirections(request: request).calculate()
        guard let route = response.routes.first else {
            throw RoutingError.noRoute
        }
        return route
    }

    enum RoutingError: LocalizedError {
        case noRoute
        var errorDescription: String? { "No driving route could be found." }
    }
}
