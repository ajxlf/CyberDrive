# CyberDrive

CyberDrive is a personal Cyberpunk-style navigation app for iPhone + Apple CarPlay.

The app intentionally does not modify Apple Maps, Google Maps, or Waze. It is its own navigation app that uses CarPlay's navigation scene and draws a custom map underneath Apple's CarPlay navigation UI.

## What is included

- SwiftUI iPhone interface.
- Live GPS position and heading.
- Destination search using MapKit.
- Driving routes using MapKit / Apple routing.
- MapLibre Native for iOS.
- Custom Cyberpunk map style using OpenFreeMap / OpenStreetMap vector data.
- Neon route line and player marker.
- CarPlay navigation scene using CPMapTemplate.
- CarPlay destination search using CPSearchTemplate.
- CarPlay route preview and navigation session.
- Basic turn instructions and voice prompts.
- GitHub Actions workflow that can generate the Xcode project on a macOS runner.

## Important Apple requirement

The source includes the CarPlay Maps entitlement. Apple-managed CarPlay capabilities must be granted to your Apple Developer account before a real CarPlay build can be signed.

Request the navigation / maps CarPlay entitlement from Apple, enable the capability for the App ID, then create a provisioning profile that contains it.

The project is configured around XcodeGen because you do not have a Mac. The GitHub Actions workflow generates the .xcodeproj on Apple's macOS build infrastructure.

## Data sources

Map tiles use the public OpenFreeMap service, which provides OpenStreetMap-derived vector data without an API key. Review OpenFreeMap and OpenStreetMap attribution and usage requirements before putting the app into wider distribution.

## Simulator testing

The repository includes a `Simulator Smoke Test` GitHub Actions workflow. It builds CyberDrive on a hosted macOS runner, selects an available iPhone Simulator, grants location access, sets the simulated position to central London, launches the app, captures a screenshot, and uploads the screenshot and recent app logs as workflow artifacts.

Open **Actions → Simulator Smoke Test → the latest run → Artifacts → cyberdrive-simulator-test**.

The workflow uses Apple's `xcodebuild` and `simctl` command-line tools. Apple documents `simctl` as the command-line interface for managing Simulator and documents screenshot capture with `xcrun simctl io booted screenshot`.

## Current scope

This is the first complete personal-use implementation. It deliberately avoids the complexity of a full commercial navigation stack such as traffic prediction, sophisticated automatic rerouting, lane-level guidance, offline worldwide maps, or vehicle instrumentation. Those can be added later without replacing the basic architecture.
