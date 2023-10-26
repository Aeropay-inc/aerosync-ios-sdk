
# iOS Aerosync SDK

This iOS SDK provides an intergace to load the Aerosync widget directly into your iOS app. To import it use the Swift Package Manager.

# 1. Installation

To install the library you need to go to your general project settings. Then to your Package Dependencies tab. Click on the "+". On the window that is opened top right search bar paste the following link to the library repo:
https://github.com/Aeropay-inc/aerosync-ios-sdk.git

Set the dependency rule as Branch and the branch as main. When done click Add Package.

Go back to your general project settings and go on the Target for your project go the the General Tab. Scroll to the Frameworks, Libraries and Embedded Content to make sure the library was added there as well. If not click the "+" and find it in the directories.

Xcode sometimes takes a while to find the package and fully include it to your project so you can restart Xcode.

# 2. Usage/Examples

The iOS Aerosync SDK is brought into the project as a separate View through a NavigationLink. You can attach the widget to any component that will allow Navigation.
In the following example a basic Text field is attached to the navigation link that will open the widget.

```Swift

import Foundation
import SwiftUI
import aerosync_ios_sdk

struct AerosyncWidgetView : View {
    @EnvironmentObject var appVM : AppViewModel
    var body: some View{
        NavigationStack{
            NavigationLink{
                AerosyncSDK(token: "...", env: "dev", deeplink: "aerosync://connect", onEvent: self.onEvent, onSuccess: self.onSuccess, onClose: self.onClose, onLoad: self.onLoad, onError: self.onError)
                
            } label: {
                VStack {
                    Image(systemName: "globe")
                        .imageScale(.large)
                        .foregroundStyle(.tint)

                    Text("Aerosync SDK Test")
                    Button("Connect") {
                        // action to connect to Aerosync
                        print("Connect")
                    }
                }
                .padding()
            }
        }
    }
    func onEvent(message: Any) {
        print("onEvent Callback \(message)")
    }
    func onSuccess(message: Any) {
        print("onSuccess Callback \(message)")
    }
    func onClose(message: Any) {
        print("onClose Callback \(message)")
    }
    func onLoad(message: Any) {
        print("onLoad Callback \(message)")
    }
    func onError(message: Any) {
        print("onError Callback \(message)")
    }
}
```

The AerosyncSDK widget takes in a env parameter, a token parameter, a deeplink, and callback event notifications needed for your implementation. To generate a token, check out our integration guide here.

Each callback returns a String message that comes back from the widget based on the messages received by it.

| Parameter   | Type                 | Description                                                                                                                                           |
| :---------- | :------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `env`       | `string`             | **Required**. Available values: dev, staging, production.                                                                                             |
| `token`     | `string`             | **Required**. The token generated from the [integration guide](https://api-aeropay.readme.io/docs/aerosync-implementation-guides).                    |
| `onEvent`   | `function(response)` | **Required**. This method will be triggered as the user completes the bank link workflow.                                                             |
| `onLoad`    | `function(response)` | **Required**. Call function after the contents of webpage have been loaded as the user completes the bank link workflow.                              |
| `onSuccess` | `function(response)` | **Required**. This method will be triggered when a bank is added successfully and the user clicks on "continue" button in the final AeroSync-UI page. |
| `onClose`   | `function(response)` | **Required**. This method will be triggered when the Aerosync widget is closed.                                                                       |
| `onError`   | `function(response)` | **Required**. The method is called if AeroSync-UI dispatches any error events.                                                                        |
| `deeplink`  | `string`             | **Required** Deeplink from your app.                                                                                                                  |
> 📘 The deeplink parameter is a required field that links back to your iOS application for the best oAuth authentication experience.
> 
> The largest FIs in the US use oAuth experiences to authenticate their end user's banks for the optimal user experience in a secure manner.
> 
> To implement deeplinking using iOS please refer to the official iOS Deeplink guide for Universal Links [here](https://developer.apple.com/ios/universal-links/). URL Scheme method can also be used.
# Store Connected Account
Store onSuccess() callback return to authenticate with the Aerosync API to retrieve account information.
```json
{
  "payload":     {  
      "ClientName": "client3",  
      "FILoginAcctId": "{\"u_guid\":\"USR-701a457e-5b93-4598-b7a1-b968c495ee3f\", \"m_guid\": \"MBR-d699c457-90f7-4b96-96c1-c50a445eabec\", \"a_guid\": \"ACT-9f5549d6-e402-43f4-8351-cd4018de7a80\"}",  
      "user_id": "a2c7f64f-3df9-4090-b3bd-ad6fc3003c90",  
      "user_password": "735e33b9-78ec-4887-99d7-a3056997ceb9" },
  "type": "pageSuccess"
}
```
