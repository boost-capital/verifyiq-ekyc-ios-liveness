# VerifyIQ eKYC SDK for iOS: liveness

The liveness check of the VerifyIQ eKYC SDK (iOS 15 and later), as a Swift package on
`boost-capital/verifyiq-ekyc-ios` and AWS Amplify UI Liveness 1.4.8. This repository is written
by the release process; changes made here are overwritten.

```swift
.package(url: "https://github.com/boost-capital/verifyiq-ekyc-ios-liveness", exact: "0.9.2"),
```

Product `VerifyIQeKYCLiveness`. Add it only when the app's deployment target is iOS 15 or later,
always at the same version as `boost-capital/verifyiq-ekyc-ios`.

The SDK works only with sessions created by a VerifyIQ partner backend. The integration guide
and sandbox credentials come with a partner agreement; see `LICENSE` for the terms of use.
