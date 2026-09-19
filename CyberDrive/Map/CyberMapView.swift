import Combine
import MapLibre
import UIKit

@MainActor
final class CyberMapViewController: UIViewController, MLNMapViewDelegate {
    let mapView: MLNMapView

    private let locationManager: LocationManager
    private var playerAnnotation: MLNPointAnnotation?
    private var routeSource: MLNShapeSource?
    private var routeGlowLayer: MLNLineStyleLayer?
    private var routeCoreLayer: MLNLineStyleLayer?
    private var didLoadStyle = false
    private var followsHeading = true
    private var cancellables = Set<AnyCancellable>()

    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        guard let styleURL = Bundle.main.url(forResource: "cyberpunk", withExtension: "json") else {
            fatalError("Missing cyberpunk.json")
        }
        self.mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = NeonPalette.background
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.frame = view.bounds
        mapView.delegate = self
        mapView.attributionButton.isHidden = false
        mapView.allowsRotating = false
        mapView.pitchEnabled = true
        mapView.prefetchesTiles = true
        mapView.minimumZoomLevel = 3
        mapView.maximumZoomLevel = 20
        view.addSubview(mapView)
        startObserving()
    }

    private func startObserving() {
        locationManager.$location
            .compactMap { $0 }
            .sink { [weak self] location in self?.update(location: location) }
            .store(in: &cancellables)

        locationManager.$heading
            .sink { [weak self] heading in self?.update(heading: heading) }
            .store(in: &cancellables)
    }

    func setRoute(_ route: MKRoute?) {
        guard didLoadStyle else { return }
        updateRoute(route)
    }

    func recenter() {
        guard let location = locationManager.location else { return }
        followsHeading = true
        mapView.setCenterCoordinate(location.coordinate, zoomLevel: 17, direction: locationManager.heading, animated: true)
    }

    func followHeading(_ enabled: Bool) {
        followsHeading = enabled
    }

    private func update(location: CLLocation) {
        updatePlayerAnnotation(location.coordinate)
        guard followsHeading else { return }
        mapView.setCenterCoordinate(location.coordinate, zoomLevel: max(mapView.zoomLevel, 16.5), direction: locationManager.heading, animated: true)
    }

    private func update(heading: CLLocationDirection) {
        guard let location = locationManager.location, followsHeading else { return }
        mapView.setCenterCoordinate(location.coordinate, zoomLevel: max(mapView.zoomLevel, 16.5), direction: heading, animated: true)
    }

    private func updatePlayerAnnotation(_ coordinate: CLLocationCoordinate2D) {
        if let annotation = playerAnnotation {
            annotation.coordinate = coordinate
        } else {
            let annotation = MLNPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "YOU"
            playerAnnotation = annotation
            mapView.addAnnotation(annotation)
        }
    }

    private func updateRoute(_ route: MKRoute?) {
        guard let style = mapView.style else { return }
        if let routeSource { style.removeSource(routeSource) }
        if let routeGlowLayer { style.removeLayer(routeGlowLayer) }
        if let routeCoreLayer { style.removeLayer(routeCoreLayer) }
        self.routeSource = nil
        self.routeGlowLayer = nil
        self.routeCoreLayer = nil

        guard let route else { return }
        let coordinates = route.polyline.coordinatesArray
        let polyline = MLNPolyline(coordinates: coordinates, count: UInt(coordinates.count))
        let source = MLNShapeSource(identifier: "neon-route-source", shape: polyline, options: nil)

        let glow = MLNLineStyleLayer(identifier: "neon-route-glow", source: source)
        glow.lineColor = NSExpression(forConstantValue: NeonPalette.magenta)
        glow.lineOpacity = NSExpression(forConstantValue: 0.55)
        glow.lineWidth = NSExpression(forConstantValue: 14)
        glow.lineBlur = NSExpression(forConstantValue: 8)
        glow.lineCap = NSExpression(forConstantValue: "round")
        glow.lineJoin = NSExpression(forConstantValue: "round")

        let core = MLNLineStyleLayer(identifier: "neon-route-core", source: source)
        core.lineColor = NSExpression(forConstantValue: NeonPalette.cyan)
        core.lineOpacity = NSExpression(forConstantValue: 1)
        core.lineWidth = NSExpression(forConstantValue: 5)
        core.lineCap = NSExpression(forConstantValue: "round")
        core.lineJoin = NSExpression(forConstantValue: "round")

        style.addSource(source)
        style.addLayer(glow)
        style.addLayer(core)
        routeSource = source
        routeGlowLayer = glow
        routeCoreLayer = core
    }

    func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
        didLoadStyle = true
        let coordinate = locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
        mapView.setCenterCoordinate(coordinate, zoomLevel: 15, direction: 0, animated: false)
        updateRoute(NavigationCoordinator.shared.route)
        if let location = locationManager.location {
            updatePlayerAnnotation(location.coordinate)
        }
    }

    func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
        guard annotation is MLNPointAnnotation else { return nil }
        let reuseIdentifier = "cyber-player"
        return (mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? CyberPlayerAnnotationView)
            ?? CyberPlayerAnnotationView(reuseIdentifier: reuseIdentifier)
    }

    func mapView(_ mapView: MLNMapView, imageFor annotation: MLNAnnotation) -> MLNAnnotationImage? {
        nil
    }
}

import MapKit

private extension MKPolyline {
    var coordinatesArray: [CLLocationCoordinate2D] {
        var coordinates = Array(repeating: CLLocationCoordinate2D(), count: pointCount)
        getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
        return coordinates
    }
}

final class CyberPlayerAnnotationView: MLNAnnotationView {
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        bounds = CGRect(x: 0, y: 0, width: 36, height: 36)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = UIBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2))
        context.setStrokeColor(NeonPalette.cyan.cgColor)
        context.setLineWidth(2)
        context.addPath(outer.cgPath)
        context.strokePath()
        let inner = UIBezierPath(ovalIn: rect.insetBy(dx: 11, dy: 11))
        context.setFillColor(NeonPalette.cyan.cgColor)
        context.addPath(inner.cgPath)
        context.fillPath()
        let beam = UIBezierPath()
        beam.move(to: CGPoint(x: center.x, y: 1))
        beam.addLine(to: CGPoint(x: center.x - 5, y: 11))
        beam.addLine(to: CGPoint(x: center.x + 5, y: 11))
        beam.close()
        context.setFillColor(NeonPalette.magenta.cgColor)
        context.addPath(beam.cgPath)
        context.fillPath()
    }
}
