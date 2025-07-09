# AeroSync iOS SDK

A native iOS SDK that provides secure bank account linking capabilities for iOS applications. Built with SwiftUI and WKWebView, this SDK allows users to securely connect their bank accounts through their bank's website with fast, secure, and tokenized connections.

## 🚀 Features

- **AerosyncSDK**: Full bank linking experience with complete UI
- **AerosyncEmbeddedView**: Lightweight bank search and selection interface
- **Native iOS**: Built with SwiftUI and WKWebView for optimal performance
- **State Management**: Maintains session state across different views
- **Secure**: All communications are encrypted and tokenized
- **MFA Support**: Multi-factor authentication handling
- **Deep Linking**: OAuth authentication support
- **Customizable**: Theming and styling options

## Requirements

- iOS 14.0+
- Xcode 12.0+
- Swift 5.3+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/aerosync-ios-sdk.git", from: "2.0.0")
]
```

Or add it through Xcode:

1. Open your project in Xcode
2. Go to **File** → **Add Package Dependencies**
3. Enter the repository URL: `https://github.com/your-org/aerosync-ios-sdk.git`
4. Click **Add Package**

### Import the SDK

```swift
import aerosync_ios_sdk
```

## Usage Examples

### 1. AerosyncSDK (Full Bank Linking Experience)

The main SDK provides a complete bank linking experience:

```swift
import SwiftUI
import aerosync_ios_sdk

struct BankLinkingView: View {
    let token = "your-token-here"
    let environment = "sandbox" // dev, staging, sandbox, production
    let deeplink = "yourapp://"

    var body: some View {
        NavigationView {
            AerosyncSDK(
                token: token,
                env: environment,
                deeplink: deeplink,
                configurationId: "your-config-id", // Optional
                aeroPassUserUuid: "user-uuid-123", // Optional
                theme: "light", // "light" or "dark"
                handleMFA: false,
                manualLinkOnly: false,
                onSuccess: { data in
                    print("Bank linking successful: \(data)")
                    // Handle successful bank connection
                },
                onClose: { data in
                    print("Widget closed: \(data)")
                    // Handle widget closure
                },
                onEvent: { data in
                    print("Event received: \(data)")
                    // Handle various events
                },
                onError: { error in
                    print("Error occurred: \(error)")
                    // Handle errors
                },
                onLoad: { data in
                    print("Widget loaded: \(data)")
                    // Handle load completion
                }
            )
            .navigationTitle("Link Your Bank Account")
        }
    }
}
```

### 2. AerosyncEmbeddedView (Bank Search Interface)

The embedded view provides a lightweight bank search and selection interface:

```swift
import SwiftUI
import aerosync_ios_sdk

struct BankSearchView: View {
    let token = "your-token-here"
    let environment = "sandbox"
    let deeplink = "yourapp://"

    @State private var showingBankLinking = false
    @State private var stateCode: String?

    var body: some View {
        NavigationView {
            AerosyncEmbeddedView(
                token: token,
                env: environment,
                deeplink: deeplink,
                configurationId: "your-config-id", // Optional
                theme: "light", // "light" or "dark"
                onLoad: { data in
                    print("Embedded view loaded: \(data)")
                },
                onBankClick: { data in
                    print("Bank selected: \(data)")

                    // Extract stateCode from the bank selection
                    if let stateCode = data["stateCode"] as? String {
                        self.stateCode = stateCode
                        self.showingBankLinking = true
                    }
                },
                onError: { error in
                    print("Embedded view error: \(error)")
                }
            )
            .navigationTitle("Search Banks")
            .sheet(isPresented: $showingBankLinking) {
                if let stateCode = stateCode {
                    BankLinkingWithStateView(
                        token: token,
                        environment: environment,
                        deeplink: deeplink,
                        stateCode: stateCode
                    )
                }
            }
        }
    }
}

struct BankLinkingWithStateView: View {
    let token: String
    let environment: String
    let deeplink: String
    let stateCode: String

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            AerosyncSDK(
                token: token,
                env: environment,
                deeplink: deeplink,
                aeroPassUserUuid: "user-uuid-123", // Optional
                stateCode: stateCode, // Continue from embedded view
                theme: "light", // "light" or "dark"
                onSuccess: { data in
                    print("Bank linking successful: \(data)")
                    presentationMode.wrappedValue.dismiss()
                },
                onClose: { data in
                    print("Widget closed: \(data)")
                    presentationMode.wrappedValue.dismiss()
                },
                onEvent: { data in
                    print("Event received: \(data)")
                },
                onError: { error in
                    print("Error occurred: \(error)")
                },
                onLoad: { data in
                    print("Widget loaded: \(data)")
                }
            )
            .navigationTitle("Complete Bank Linking")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
```

### 3. MFA (Multi-Factor Authentication) Handling

For advanced use cases requiring MFA handling:

```swift
AerosyncSDK(
    token: token,
    env: environment,
    deeplink: deeplink,
    aeroPassUserUuid: "user-uuid-123", // Optional
    theme: "light", // "light" or "dark"
    handleMFA: true,
    jobId: "your-job-id",
    connectionId: "your-connection-id",
    onSuccess: { data in
        // Handle MFA success
    },
    onClose: { data in
        // Handle closure
    },
    onEvent: { data in
        // Handle MFA events
    },
    onError: { error in
        // Handle MFA errors
    },
    onLoad: { data in
        // Handle load
    }
)
```

## API Reference

To generate a token, check out our integration guide [here](https://api-aeropay.readme.io/docs/aerosync-implementation-guides).

### AerosyncSDK Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `token` | String | Yes | Authentication token for the session |
| `env` | String | Yes | Environment: "dev", "staging", "sandbox", "production" |
| `deeplink` | String | Yes | Deep link URL for your app |
| `configurationId` | String? | No | Configuration ID for customization |
| `aeroPassUserUuid` | String? | No | AeroPass user UUID for user identification |
| `stateCode` | String? | No | State code for continuing from embedded view |
| `theme` | String | No | UI theme: "light" or "dark" (default: "light") |
| `handleMFA` | Bool | No | Whether to handle MFA flows (default: false) |
| `manualLinkOnly` | Bool | No | Whether to show only manual linking options (default: false) |
| `jobId` | String? | No | Job ID for MFA handling |
| `connectionId` | String? | No | Connection ID for MFA handling |

### AerosyncEmbeddedView Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `token` | String | Yes | Authentication token for the session |
| `env` | String | Yes | Environment: "dev", "staging", "sandbox", "production" |
| `deeplink` | String | Yes | Deep link URL for your app |
| `configurationId` | String? | No | Configuration ID for customization |
| `theme` | String | No | UI theme: "light" or "dark" (default: "light") |

### Callback Events

#### AerosyncSDK Events

- **onEvent**: General widget events and page navigation
- **onSuccess**: Successful bank connection with account details
- **onClose**: Widget closed by user
- **onLoad**: Widget finished loading
- **onError**: Error occurred during the process

#### AerosyncEmbeddedView Events

- **onLoad**: Embedded view finished loading
- **onBankClick**: User selected a bank (contains stateCode for widget launch)
- **onError**: Error occurred in embedded view

## Deep Linking Setup

The deeplink parameter is required for optimal OAuth authentication experience with major financial institutions.

### 1. Configure URL Scheme

Add your custom URL scheme to your app's `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourapp.deeplink</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourapp</string>
        </array>
    </dict>
</array>
```

### 2. Handle Deep Links

In your `SceneDelegate.swift` or `AppDelegate.swift`:

```swift
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }
    // Handle the deep link URL
    print("Received deep link: \(url)")
}
```

## Success Response Format

Store `onSuccess()` data attributes to authenticate with the Aerosync API:

```json
{
  "type": "pageSuccess",
  "payload": {
    "user_id": "a08905dae1d74c9ea021d325d8de654f",
    "user_password": "7f9946f5e2e34f61a59f2f3c00535118",
    "ClientName": "Aeropay",
    "FILoginAcctId": 113786059
  }
}
```

## Troubleshooting

### Common Issues

1. **Widget not loading**: Verify your token is valid and not expired
2. **Embedded view not responding**: Check that the environment is correctly set
3. **Build errors**: Ensure iOS deployment target is 14.0+
4. **Deep linking not working**: Verify URL scheme configuration in Info.plist

### Debug Mode

Enable debug logging by checking the Xcode console for detailed information about:
- Widget initialization
- State transitions
- Error details
- Callback events

## Support

For technical support and questions, please contact our development team.

## License

This SDK is proprietary software. Please refer to your license agreement for usage terms.