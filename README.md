
# aerosync-flutter-sdk

This Flutter SDK provides an interface to load Aerosync-UI in Flutter applications through flutter_inappwebview. Securely link your bank account through your bank's website. Log in with a fast, secure, and tokenized connection. Your information is never shared or sold.

## Features

- **Normal Widget**: Full bank linking experience with complete UI
- **Embedded View**: Lightweight bank search and selection interface
- **Seamless Integration**: Automatic transition from embedded view to normal widget
- **State Management**: Maintains session state across different views
- **Cross-Platform**: Works on iOS, Android, and Web
- **Secure**: All communications are encrypted and tokenized

## Requirements

- Flutter 3.0.0+
- Dart 2.17.0+
- iOS 11.0+ / Android API level 21+

## Installation

### 1. Add Dependency

Add `aerosync_flutter_sdk` to your `pubspec.yaml` file. We are currently on constant development for fine-tuning and improvement currently using the `^1.1.0` as our release with the most up to date features and fixes.

```yaml
dependencies:
  aerosync_flutter_sdk: ^1.1.0
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Import the Library

```dart
import 'package:aerosync_flutter_sdk/aerosync_flutter_sdk.dart';
```

## Usage/Examples

### 1. Normal Widget Implementation (AerosyncSDKPage)

The Aerosync plugin is brought in as a separate window that launches the [Flutter InAppWebView Plugin](https://pub.dev/packages/flutter_inappwebview) with the Aerosync starting url. In this example the widget is navigated to when `ElevatedButton` is pressed.

```dart
import 'package:flutter/material.dart';
import 'package:aerosync_flutter_sdk/aerosync_flutter_sdk.dart';

void main() => runApp(UrlLauncherPage());

class UrlLauncherPage extends StatefulWidget {
  UrlLauncherPage({Key? key}) : super(key: key);
  @override
  UrlLauncherExample createState() => UrlLauncherExample();
}

class UrlLauncherExample extends State<UrlLauncherPage> {
  static const String _title = 'URL Launcher Example';
  late String _token = "";
  late String _env = "sandbox";
  late String _deeplink = "";
  late String _configurationId = "";
  late bool _handleMFA = false;
  late String _jobId = "";
  late String _userId = "";
  Map _style = {};
  late bool isLoading;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: isLoading
            ? LaunchButton(
                env: _env,
                token: _token,
                style: _style,
                deeplink: _deeplink,
                consumeerId: _configurationId,
                handleMFA: _handleMFA,
                jobId: _jobId,
                userId: _userId,
              )
            : SizedBox(), // this includes all the button and functionality
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    isLoading = false;
  }
}

class LaunchButton extends StatelessWidget {
  var env;
  var token;
  var style;
  var deeplink;
  var configurationId;
  var handleMFA;
  var jobId;
  var userId;
  LaunchButton(
      {Key? key,
      required this.env,
      required this.token,
      required this.style,
      required this.deeplink,
      this.configurationId,
      this.handleMFA,
      this.jobId,
      this.userId})
      : super(key: key);

  // handle the OnEvent callback from aerosync
  handleOnEventAerosync(eventType, data) {
  }

  // handle the OnSuccess callback from aerosync
  handleOnSuccessAerosync(eventType, data) {
    Map<String, dynamic> successData = jsonDecode(data);
  }

  // handle the OnClose callback from aerosync
  handleOnCloseAerosync(eventType, data) {
  }

  // handle the OnLoad callback from aerosync
  handleOnLoadAerosync(eventType, data) {
  }

  // handle the OnError callback from aerosync
  handleOnErrorAerosync(eventType, data) {
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () => {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AerosyncSDKPage(
                      env: env,
                      token: token,
                      style: style,
                      onEvent: handleOnEventAerosync,
                      onSuccess: handleOnSuccessAerosync,
                      onClose: handleOnCloseAerosync,
                      onLoad: handleOnLoadAerosync,
                      onError: handleOnErrorAerosync,
                      deeplink: deeplink,
                      configurationId: configurationId,
                      handleMFA: handleMFA,
                      jobId: jobId,
                      userId: userId,
                    )))
          },
          child: Text(
            'Connect',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ],
    ));
  }
}
```

### 2. Embedded View Implementation (AeroSyncEmbeddedView)

The embedded view provides a lightweight bank search interface:

```dart
import 'package:flutter/material.dart';
import 'package:aerosync_flutter_sdk/aerosync_flutter_sdk.dart';

class BankSearchPage extends StatefulWidget {
  @override
  _BankSearchPageState createState() => _BankSearchPageState();
}

class _BankSearchPageState extends State<BankSearchPage> {
  void _handleLoad(data) {
    print('Embedded view loaded: $data');
  }

  void _handleBankClick(Map<String, dynamic> data) {
    print('Bank selected: $data');
    // Navigate to normal widget with stateCode
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AerosyncSDKPage(
          env: 'dev',
          token: 'your-token-here', // Use same token
          stateCode: data['stateCode'], // Pass stateCode from embedded view
          style: {'width': '350', 'height': '688', 'bgColor': '#FFFFFF'},
          deeplink: 'yourapp://',
          onEvent: (eventType, data) => print('Event: $data'),
          onSuccess: (eventType, data) => print('Success: $data'),
          onClose: (eventType, data) => Navigator.pop(context),
          onLoad: (eventType, data) => print('Loaded: $data'),
          onError: (eventType, data) => print('Error: $data'),
        ),
      ),
    );
  }

  void _handleError(String error) {
    print('Embedded view error: $error');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search Banks')),
      body: AeroSyncEmbeddedView(
        token: 'your-token-here',
        environment: 'dev',
        deeplink: 'yourapp://',
        configurationId: 'your-config-id', // Optional
        theme: 'light', // 'light' or 'dark'
        onLoad: _handleLoad,
        onBankClick: _handleBankClick,
        onError: _handleError,
      ),
    );
  }
}
```

## Parameters

The `AerosyncSDKPage` widget takes in a `env` parameter, a `token` parameter a `style` parameter `deeplink`, and callback event notifications needed for your implementation. To generate a token, check out our integration guide [here](https://api-aeropay.readme.io/docs/aerosync-implementation-guides).

Each callback returns an `eventType` value and data that is returned from aerosync-ui.

### AerosyncSDKPage Parameters

| Parameter   | Type                 | Description                                                                                                                                           |
| :---------- | :------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `env`       | `string`             | **Required**. Available values: dev, staging, sandbox, production.                                                                                   |
| `token`     | `string`             | **Required**. The token generated from the [integration guide](https://api-aeropay.readme.io/docs/aerosync-implementation-guides).                    |
| `style`\*   | `Map`                | **Required**. `{"width": "<double>", "height": "<double>", "bgColor": "<Hex color value in format "ARGB">" }`                                         |
| `stateCode` | `string`             | **Optional**. State code for continuing from embedded view.                                                                                           |
| `onEvent`   | `function(response)` | **Required**. This method will be triggered as the user completes the bank link workflow.                                                             |
| `onLoad`    | `function(response)` | **Required**. Call function after the contents of webpage have been loaded as the user completes the bank link workflow.                              |
| `onSuccess` | `function(response)` | **Required**. This method will be triggered when a bank is added successfully and the user clicks on "continue" button in the final AeroSync-UI page. |
| `onClose`   | `function(response)` | **Required**. This method will be triggered when the Aerosync widget is closed.                                                                       |
| `onError`   | `function(response)` | **Required**. The method is called if AeroSync-UI dispatches any error events.                                                                        |
| `deeplink`  | `string`             | **Required** Deeplink from your app.                                                                                                                  |
| `configurationId`| `string`             | Unique ID that represents the client to apply the customization. Contact the team for more information."                                         |
| `handleMFA` | `bool`               | Boolean value that determines MFA widget invocation. Contact the team for more information."                                                          |
| `jobId`     | `string`             | Unique ID that represents the current MFA jobId. Contact the team for more information."                                                              |
| `userId`    | `string`             | Unique ID that represents the current MFA userId. Contact the team for more information."                                                             |

### AeroSyncEmbeddedView Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `token` | String | Yes | Authentication token for the session |
| `environment` | String | Yes | Environment: "dev", "staging", "sandbox", "production" |
| `deeplink` | String | Yes | Deep link URL for your app |
| `configurationId` | String? | No | Configuration ID for customization |
| `theme` | String | No | UI theme: "light" or "dark" (default: "light") |

- The Style parameter takes in a Map\<String, String> object with `width`, `height`, and `bgColor` parameters that will customize the Aerosync widget to your liking. the Map is Required to be sent even if you dont want to change one of the values leave the `key` out of the map or just all together send an empty map.

## Parameters

### AeroSyncWidget Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `token` | String | Yes | Authentication token for the session |
| `environment` | String | Yes | Environment: "dev", "staging", "sandbox", "production" |
| `deeplink` | String | Yes | Deep link URL for your app |
| `configurationId` | String? | No | Configuration ID for customization |
| `stateCode` | String? | No | State code for continuing from embedded view |
| `aeroPassUserUuid` | String? | No | AeroPass user UUID |
| `handleMFA` | bool | No | Whether to handle MFA flows (default: false) |
| `manualLinkOnly` | bool | No | Whether to show only manual linking options (default: false) |
| `jobId` | String? | No | Job ID for MFA handling |
| `connectionId` | String? | No | Connection ID for MFA handling |
| `theme` | String | No | UI theme: "light" or "dark" (default: "light") |
| `style` | Map<String, String>? | No | Custom styling options |

### AeroSyncEmbeddedView Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `token` | String | Yes | Authentication token for the session |
| `environment` | String | Yes | Environment: "dev", "staging", "sandbox", "production" |
| `deeplink` | String | Yes | Deep link URL for your app |
| `configurationId` | String? | No | Configuration ID for customization |
| `theme` | String | No | UI theme: "light" or "dark" (default: "light") |

## Callback Events

### Normal Widget Events

- **onEvent**: General widget events and page navigation
- **onSuccess**: Successful bank connection with account details
- **onClose**: Widget closed by user
- **onLoad**: Widget finished loading
- **onError**: Error occurred during the process

### Embedded View Events

- **onLoad**: Embedded view finished loading
- **onBankClick**: User selected a bank (contains stateCode for widget launch)
- **onError**: Error occurred in embedded view

## Automatic Widget Launch Flow

1. User interacts with the **Embedded View** to search and select a bank
2. When a bank is clicked, the `onBankClick` callback is triggered with a `stateCode`
3. Your app receives the callback and navigates to the **Normal Widget** (AerosyncSDKPage)
4. The widget launches with the `stateCode` and continues the bank linking process
5. User completes the bank connection in the normal widget

## Deep Linking Setup

> 📘 The deeplink parameter is a required field that links back to your Flutter application for the best oAuth authentication experience.
>
> The largest FIs in the US use oAuth experiences to authenticate their end user's banks for the optimal user experience in a secure manner.
>
> To implement deeplinking using Flutter please refer to the official Flutter Deeplink guide [here](https://docs.flutter.dev/ui/navigation/deep-linking).

## Store Connected Account

Store `onSuccess()` data attributes to authenticate with the Aerosync API to retrieve account information. The data value returned on the success call is a JSON encoded value so you can decode it as `jsonDecode(data)` to use it as a Map. Check the given example.

**New Success Response Format:**

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

## Setup and Development

### Prerequisites

First install Flutter (recommended with Flutter VS Code extension):
https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter

### Useful Commands

```bash
# Check Flutter installation
flutter doctor

# Clean project
flutter clean

# Get dependencies
flutter pub get

# Build for iOS
flutter build ios

# Build for Android
flutter build android

# Run the app
flutter run

# Run on specific device
flutter run -d <device-id>
```

### Platform-Specific Setup

#### iOS Setup
1. Ensure iOS deployment target is **11.0 or higher**
2. Run `cd ios && pod install` if using CocoaPods

#### Android Setup
1. Minimum SDK version: **21**
2. Add internet permission to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   ```

## Demo App

The included demo app demonstrates both embedded view and normal widget functionality.

To run the demo:

1. Clone this repository
2. Run `flutter pub get`
3. Run `flutter run`
4. Enter your token and configuration
5. Test both embedded view and normal widget functionality

## Troubleshooting

### Common Issues

1. **Widget not loading**: Verify your token is valid and not expired
2. **Embedded view not responding**: Check that the environment is correctly set
3. **Build errors**: Run `flutter clean` and `flutter pub get`
4. **iOS build issues**: Check iOS deployment target and run `pod install`

### Debug Mode

Enable debug logging by checking the Flutter console for detailed information about:
- Widget initialization
- State transitions
- Error details
- Callback events

## Support

For technical support and questions, please contact our development team.

## License

This SDK is proprietary software. Please refer to your license agreement for usage terms.
