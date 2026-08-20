# AeroSync iOS SDK

[![Swift](https://img.shields.io/badge/Swift-5.3+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2014%2B-blue.svg)](https://developer.apple.com/ios/)
[![SPM](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Version](https://img.shields.io/badge/version-2.1.0-blue.svg)](https://github.com/Aeropay-inc/aerosync-ios-sdk/releases)

A native iOS SDK for secure bank account linking. Built with SwiftUI and WKWebView, it lets users connect their bank accounts through fast, tokenized connections — with full OAuth and MFA support.

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Setup](#setup)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [API Reference](#api-reference)
- [Success Response](#success-response)
- [Troubleshooting](#troubleshooting)
- [Migration from 1.x](#migration-from-1x-to-2x)
- [License](#license)

---

## Features

- **Full bank linking experience** — complete OAuth and credential-based flows via `AerosyncSDK`
- **OAuth support** — external browser opens automatically; returns cleanly to your app via deep link
- **MFA support** — multi-factor authentication flows with job and connection ID handling
- **Swipe navigation** — swipe right/left to go back and forward within the widget
- **Theming** — light and dark mode support
- **Swift Package Manager** — no CocoaPods required

---

## Requirements

| Requirement | Minimum |
|-------------|---------|
| iOS | 14.0+ |
| Xcode | 12.0+ |
| Swift | 5.3+ |

---

## Installation

### Swift Package Manager

**In Xcode:** File → Add Package Dependencies, then enter:

```
https://github.com/Aeropay-inc/aerosync-ios-sdk
```

Select version **2.1.0** or later, then click **Add Package**.

**Or via `Package.swift`:**

```swift
dependencies: [
    .package(url: "https://github.com/Aeropay-inc/aerosync-ios-sdk", from: "2.1.0")
]
```

### Import

```swift
import aerosync_ios_sdk
```

---

## Setup

### 1. Register a URL Scheme

OAuth bank flows redirect back to your app using a custom URL scheme. Add it to your app's `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourapp</string>
        </array>
    </dict>
</array>
```

> Choose a unique scheme such as `yourapp` or `com.yourcompany.yourapp`. The full deeplink passed to the SDK would then be `yourapp://connect`.

### 2. Handle the Deep Link Callback

In your SwiftUI `App`, add an `onOpenURL` modifier so returning from OAuth completes correctly:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // The SDK resolves the OAuth return automatically.
                    // Add any additional routing logic here if needed.
                }
        }
    }
}
```

**Using SceneDelegate instead?**

```swift
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }
    // Handle url
}
```

---

## Quick Start

The minimum setup to get the bank linking widget running:

```swift
import SwiftUI
import aerosync_ios_sdk

struct BankLinkView: View {
    var body: some View {
        NavigationView {
            AerosyncSDK(
                token: "your-token-here",
                env: "sandbox",
                deeplink: "yourapp://connect",
                aeroPassUserUuid: "user-uuid-123",
                onEvent: { _ in },
                onSuccess: { data in print(data) },
                onClose: { _ in },
                onLoad: { _ in },
                onError: { _ in }
            )
        }
    }
}
```

> To generate a token, see the [AeroSync integration guide](https://api-aeropay.readme.io/docs/aerosync-implementation-guides).

---

## Usage

### Standard Bank Linking

```swift
import SwiftUI
import aerosync_ios_sdk

struct BankLinkView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            AerosyncSDK(
                token: "your-token-here",
                env: "sandbox",                    // "sandbox" or "production"
                deeplink: "yourapp://connect",
                aeroPassUserUuid: "user-uuid-123", // Required
                configurationId: "your-config-id", // Optional
                theme: "light",                    // "light" or "dark"
                manualLinkOnly: false,
                handleMFA: false,
                onEvent: { data in
                    // Widget events and page navigation signals
                },
                onSuccess: { data in
                    // Bank connection completed — parse data for credentials
                    print("Success: \(data)")
                },
                onClose: { _ in
                    presentationMode.wrappedValue.dismiss()
                },
                onLoad: { _ in
                    // Widget finished loading
                },
                onError: { error in
                    print("Error: \(error)")
                }
            )
            .navigationTitle("Link Your Bank")
        }
    }
}
```

### MFA Flow

Use this when re-authenticating an existing bank connection that requires multi-factor verification:

```swift
AerosyncSDK(
    token: "your-token-here",
    env: "sandbox",
    deeplink: "yourapp://connect",
    aeroPassUserUuid: "user-uuid-123",
    handleMFA: true,
    jobId: "your-job-id",           // Required when handleMFA is true
    connectionId: "your-conn-id",   // Required when handleMFA is true
    onEvent: { _ in },
    onSuccess: { data in
        // MFA completed successfully
    },
    onClose: { _ in },
    onLoad: { _ in },
    onError: { error in
        print("MFA error: \(error)")
    }
)
```

### Presenting as a Sheet

```swift
struct ContentView: View {
    @State private var showWidget = false

    var body: some View {
        Button("Link Bank Account") {
            showWidget = true
        }
        .sheet(isPresented: $showWidget) {
            NavigationView {
                AerosyncSDK(
                    token: "your-token-here",
                    env: "sandbox",
                    deeplink: "yourapp://connect",
                    aeroPassUserUuid: "user-uuid-123",
                    onEvent: { _ in },
                    onSuccess: { data in
                        showWidget = false
                    },
                    onClose: { _ in
                        showWidget = false
                    },
                    onLoad: { _ in },
                    onError: { _ in }
                )
                .navigationTitle("Link Your Bank")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
```

---

## API Reference

### AerosyncSDK Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `token` | `String` | Yes | — | Authentication token for the session |
| `env` | `String` | Yes | — | `"sandbox"` or `"production"` |
| `deeplink` | `String` | Yes | — | Full URL scheme for OAuth callback (e.g. `"yourapp://connect"`) |
| `aeroPassUserUuid` | `String` | Yes | — | AeroPass user UUID |
| `configurationId` | `String?` | No | `nil` | Configuration ID for widget customization |
| `stateCode` | `String?` | No | `nil` | Bank state code for pre-selecting a specific institution |
| `theme` | `String` | No | `"light"` | `"light"` or `"dark"` |
| `manualLinkOnly` | `Bool` | No | `false` | Restrict to manual (non-OAuth) credential linking only |
| `handleMFA` | `Bool` | No | `false` | Enable MFA re-authentication flow |
| `jobId` | `String?` | No | `nil` | Required when `handleMFA` is `true` |
| `connectionId` | `String?` | No | `nil` | Required when `handleMFA` is `true` |

### Callbacks

| Callback | Signature | Description |
|----------|-----------|-------------|
| `onSuccess` | `(String) -> Void` | Bank connection completed — receives a JSON string (single account, or multiple accounts when the merchant's configuration has multi-account linking enabled; see [Success Response](#success-response)) |
| `onClose` | `(Any) -> Void` | User dismissed the widget |
| `onEvent` | `(Any) -> Void` | Widget page events and navigation signals |
| `onError` | `(Any) -> Void` | An error occurred during the flow |
| `onLoad` | `(Any) -> Void` | Widget finished loading |

---

## Success Response

The `onSuccess` callback receives a JSON string:

```json
{
  "type": "pageSuccess",
  "payload": {
    "connectionId": "33e1121dde934c5cb5b964b325e28728",
    "aeroPassUserUuid": "b120bcb5-2f39-48d3-a654-1c437c1ec175",
    "clientName": "Aeropay"
  }
}
```

If your AeroSync configuration has **multi-account linking** enabled, the same event instead carries a list of linked accounts:

```json
{
  "type": "pageSuccess",
  "payload": {
    "accounts": [
      { "connectionId": "33e1121dde934c5cb5b964b325e28728", "accountType": "checking", "accountNumberDisplay": "••••1234" },
      { "connectionId": "84f2232eef045d6dc6a075436f39839", "accountType": "savings", "accountNumberDisplay": "••••5678" }
    ],
    "clientName": "Aeropay",
    "aeroPassUserUuid": "b120bcb5-2f39-48d3-a654-1c437c1ec175"
  }
}
```

**Parsing with the typed models:**

```swift
onSuccess: { message in
    guard let result = AerosyncSuccessPayload.parse(from: message) else { return }
    switch result {
    case .multiAccount(let payload):
        for account in payload.accounts {
            print("\(account.accountType): \(account.accountNumberDisplay)")
        }
    case .singleAccount(let payload):
        print("Connected: \(payload.connectionId)")
    }
}
```

**Manual parsing example** (if you'd rather not use the typed models):

```swift
onSuccess: { data in
    guard let jsonData = data.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
          let payload = json["payload"] as? [String: Any] else { return }

    if let accounts = payload["accounts"] as? [[String: Any]] {
        // Multi-account: each entry has connectionId, accountType, accountNumberDisplay
    } else {
        let connectionId = payload["connectionId"] as? String
        // Use this to authenticate with the AeroSync API
    }
}
```

---

## Troubleshooting

### Widget not loading
- Verify your token is valid and has not expired
- Confirm the `env` value is either `"sandbox"` or `"production"` (other values will crash with a force-unwrap)

### OAuth browser never opens
- Confirm `javaScriptCanOpenWindowsAutomatically` is not blocked by any custom `WKWebViewConfiguration` layer in your app
- The SDK sets this to `true` internally — ensure no parent configuration overrides it

### App does not return after OAuth
- Verify the URL scheme in `Info.plist` matches the scheme in your `deeplink` parameter exactly (e.g. if deeplink is `yourapp://connect`, the scheme must be `yourapp`)
- Confirm your `App` or `SceneDelegate` has the `onOpenURL` / `openURLContexts` handler wired up

### `onSuccess` never fires
- Check that your bank linking flow fully completes — partial flows (user closes early) trigger `onClose`, not `onSuccess`
- Inspect raw events in `onEvent` to trace the widget state

### Build errors after upgrading
- Run **File → Packages → Update to Latest Package Versions** in Xcode
- Ensure deployment target is iOS 14.0+
- Clean build folder: **Product → Clean Build Folder** (⇧⌘K)

---

## Migration from 1.x to 2.x

### Breaking changes

| Change | 1.x | 2.x |
|--------|-----|-----|
| `aeroPassUserUuid` | Optional | **Required** |
| `dev` environment | Supported | **Removed** — use `"sandbox"` |
| `staging` environment | Supported | **Removed** — use `"sandbox"` |
| `AerosyncEmbeddedView` | Available | **Removed** in 2.1.0 |

### Parameter renames

| 1.x | 2.x |
|-----|-----|
| Previous connection param name | `connectionId` |
| Previous configuration param name | `configurationId` |

---

## License

This SDK is proprietary software. Please refer to your license agreement for usage terms.
