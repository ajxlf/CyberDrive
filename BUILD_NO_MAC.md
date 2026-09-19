# Building without a Mac

This project is designed so the source can be built on GitHub's macOS runners. You do not need a physical Mac to generate the Xcode project or run the compile workflow.

## Stage 1 — verify the code

Push the repository to GitHub, then run:

`Actions` → `Build iOS` → `Run workflow`

This produces a simulator build and catches normal Swift/Xcode compilation errors.

## Stage 2 — get CarPlay access

Apple requires CarPlay navigation apps to have the appropriate managed CarPlay capability. The navigation category uses the CarPlay Maps entitlement (`com.apple.developer.carplay-maps`). The Default Navigation entitlement is separate and is intentionally not included in this MVP; it is not required simply to run a third-party navigation app on CarPlay.

Request the CarPlay entitlement in Apple Developer, then assign it to the App ID and provisioning profile.

## Stage 3 — signed installation

For installation on your iPhone and use with CarPlay, you still need Apple code signing. GitHub Actions can perform the final build, but your Apple Developer signing credentials must be supplied to the workflow as secrets. Do not commit certificates, private keys, or provisioning profiles to the repository.

A typical setup uses:

- Apple Distribution certificate (`.p12`) encoded as a GitHub secret.
- Matching provisioning profile (`.mobileprovision`) encoded as a GitHub secret.
- Password for the `.p12` as a GitHub secret.
- App Store Connect / Apple signing credentials as required by the chosen distribution workflow.

Once those are available, the workflow can archive the app and export an `.ipa` for TestFlight or another permitted distribution method.
