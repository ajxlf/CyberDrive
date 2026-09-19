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

## Build without a Mac

1. Put this project in a GitHub repository.
2. Request the CarPlay Maps capability from Apple Developer.
3. Add the CarPlay capability to the App ID.
4. Configure code signing secrets for the GitHub workflow.
5. Run the Build iOS workflow.

The first workflow is deliberately an unsigned simulator build. This validates compilation without requiring your signing credentials.

For a device / TestFlight build, the workflow must be extended with your Apple signing certificate and provisioning profile. Those credentials cannot be safely generated or embedded by this project because they belong to your Apple Developer account.

## Data sources

Map tiles use the public OpenFreeMap service, which provides OpenStreetMap-derived vector data without an API key. Review OpenFreeMap and OpenStreetMap attribution and usage requirements before putting the app into wider distribution.

## Current scope

This is the first complete personal-use implementation. It deliberately avoids the complexity of a full commercial navigation stack such as traffic prediction, sophisticated automatic rerouting, lane-level guidance, offline worldwide maps, or vehicle instrumentation. Those can be added later without replacing the basic architecture.
