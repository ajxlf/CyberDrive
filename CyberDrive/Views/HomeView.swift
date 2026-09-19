import SwiftUI
import MapKit

struct HomeView: View {
    @EnvironmentObject private var navigation: NavigationCoordinator
    @State private var query = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false

    var body: some View {
        ZStack(alignment: .bottom) {
            CyberMap()
                .ignoresSafeArea()

            VStack(spacing: 10) {
                searchBar
                if !searchResults.isEmpty {
                    resultsPanel
                }
                Spacer(minLength: 0)
                bottomHUD
            }
            .padding(.top, 14)
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .background(Color.black)
        .task { navigation.locationManager.requestAndStart() }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "location.north.line.fill")
                .foregroundStyle(Color(uiColor: NeonPalette.cyan))
            TextField("ENTER DESTINATION", text: $query)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .foregroundStyle(Color(uiColor: NeonPalette.text))
                .font(.system(.body, design: .monospaced).weight(.semibold))
                .submitLabel(.search)
                .onSubmit { performSearch() }
            if isSearching {
                ProgressView()
                    .tint(Color(uiColor: NeonPalette.cyan))
            } else {
                Button(action: performSearch) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(Color(uiColor: NeonPalette.magenta))
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: NeonPalette.panel))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(uiColor: NeonPalette.cyan).opacity(0.75), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var resultsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("LOCATIONS")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(uiColor: NeonPalette.dimText))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

            ForEach(searchResults) { result in
                Button {
                    Task { await navigation.setDestination(result.mapItem) }
                    searchResults = []
                    query = result.title
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(Color(uiColor: NeonPalette.magenta))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.title)
                                .font(.system(.body, design: .monospaced).weight(.semibold))
                                .foregroundStyle(Color(uiColor: NeonPalette.text))
                                .lineLimit(1)
                            Text(result.subtitle)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Color(uiColor: NeonPalette.dimText)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                }
                .buttonStyle(.plain)
                if result.id != searchResults.last?.id {
                    Divider().overlay(Color.white.opacity(0.08))
                }
            }
        }
        .background(Color(uiColor: NeonPalette.panel))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(uiColor: NeonPalette.violet).opacity(0.8), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var bottomHUD: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("CYBERDRIVE")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(Color(uiColor: NeonPalette.cyan))
                if let route = navigation.route {
                    Text("\(Self.distance(route.distance))  •  \(Self.duration(route.expectedTravelTime))")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(uiColor: NeonPalette.text))
                } else {
                    Text("STANDBY // AWAITING ROUTE")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(uiColor: NeonPalette.dimText))
                }
            }
            Spacer()
            Button {
                Task { await navigation.calculateRoute() }
            } label: {
                Image(systemName: "scope")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color(uiColor: NeonPalette.cyan))
                    .frame(width: 44, height: 44)
                    .background(Color(uiColor: NeonPalette.panel))
                    .overlay(Circle().stroke(Color(uiColor: NeonPalette.cyan).opacity(0.7), lineWidth: 1))
            }
        }
        .padding(12)
        .background(Color(uiColor: NeonPalette.panel))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(uiColor: NeonPalette.cyan).opacity(0.4), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func performSearch() {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isSearching = true
        Task {
            let results = (try? await RoutingService.shared.search(text, near: navigation.currentLocation)) ?? []
            await MainActor.run {
                searchResults = results
                isSearching = false
            }
        }
    }

    private static func distance(_ meters: CLLocationDistance) -> String {
        if meters >= 1000 { return String(format: "%.1f KM", meters / 1000) }
        return String(format: "%.0f M", meters)
    }

    private static func duration(_ seconds: TimeInterval) -> String {
        let minutes = max(1, Int(seconds / 60))
        if minutes >= 60 {
            return "\(minutes / 60)H \(minutes % 60)M"
        }
        return "\(minutes) MIN"
    }
}
