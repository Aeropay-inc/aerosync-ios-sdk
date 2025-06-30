import SwiftUI
import WebKit

#if os(iOS)
@available(iOS 14.0, *)
public struct AerosyncEmbeddedView: UIViewRepresentable {
    var token: String
    var env: String
    var deeplink: String
    var configurationId: String?
    var theme: String
    var onLoad: (Any) -> ()
    var onBankClick: (Any) -> ()
    var onError: (Any) -> ()

    public init(
        token: String,
        env: String,
        deeplink: String,
        configurationId: String? = nil,
        theme: String = "light",
        onLoad: @escaping (Any) -> Void,
        onBankClick: @escaping (Any) -> Void,
        onError: @escaping (Any) -> Void
    ) {
        self.token = token
        self.env = env
        self.deeplink = deeplink
        self.configurationId = configurationId
        self.theme = theme
        self.onLoad = onLoad
        self.onBankClick = onBankClick
        self.onError = onError
    }

    public func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default() // Fix when banks are not being loaded
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true


        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        let userController = config.userContentController
        userController.add(context.coordinator, name: "onEvent")
        userController.add(context.coordinator, name: "onBankClick")
        userController.add(context.coordinator, name: "onError")
        userController.add(context.coordinator, name: "messageHandler")

        let messageScript = """
            (function() {
                // Override postMessage to capture all messages
                const originalPostMessage = window.postMessage;
                window.postMessage = function(message, targetOrigin) {
                    console.log('[iOS Bridge] Intercepted postMessage:', message);
                    if (typeof message === 'object' && message.type) {
                        window.webkit.messageHandlers.messageHandler.postMessage(JSON.stringify(message));
                    }
                    return originalPostMessage.call(this, message, targetOrigin);
                };

                // Also listen for message events
                window.addEventListener('message', function(event) {
                    console.log('[iOS Bridge] Received message event:', event.data);
                    if (typeof event.data === 'object' && event.data.type) {
                        window.webkit.messageHandlers.messageHandler.postMessage(JSON.stringify(event.data));
                    }
                });

                const originalLog = console.log;
                console.log = function(message) {
                    window.webkit.messageHandlers.logHandler.postMessage(message);
                    originalLog.apply(console, arguments);
                };
            })();
        """
        let userScript = WKUserScript(source: messageScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        config.userContentController.addUserScript(userScript)
        config.userContentController.add(context.coordinator, name: "logHandler")

        context.coordinator.webView = webView

        var baseURL = "https://qa-sync.aero.inc"
        switch env.lowercased() {
        case "production": baseURL = "https://sync.aero.inc"
        case "sandbox": baseURL = "https://sandbox.aerosync.com"
        case "staging": baseURL = "https://staging-sync.aero.inc"
        default: break
        }

        var urlString = "\(baseURL)/embedded-view?token=\(token)&deeplink=\(deeplink)&defaultTheme=\(theme)&version=2.0.0"
        if let configId = configurationId {
            urlString += "&configurationId=\(configId)"
        }

        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(wrapper: self)
    }

    public class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate {
        var wrapper: AerosyncEmbeddedView
        var webView: WKWebView?
        var token: String
        var env: String
        var configurationId: String?

        init(wrapper: AerosyncEmbeddedView) {
            self.wrapper = wrapper
            self.token = wrapper.token
            self.env = wrapper.env
            self.configurationId = wrapper.configurationId
        }

        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

            switch message.name {
            case "messageHandler":
                handleGenericMessage(message.body)
            case "onEvent":
                wrapper.onLoad(message.body)
            case "onBankClick":
                handleBankClickMessage(message.body)
            case "onError":
                wrapper.onError(message.body)
            case "logHandler":
                // Skip logging console messages to prevent infinite loop
                break
            default:
                break
            }
        }

        private func handleGenericMessage(_ messageBody: Any) {
            guard let bodyStr = messageBody as? String,
                  let data = bodyStr.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let type = json["type"] as? String else {
                return
            }

            switch type {
            case "widgetBankClick":
                if let payload = json["payload"] as? [String: Any],
                   let stateCode = payload["stateCode"] as? String {
                    wrapper.onBankClick(payload)
                    DispatchQueue.main.async {
                        // Pass both stateCode and token from embedded view
                        let launchData = [
                            "stateCode": stateCode,
                            "token": self.token,
                            "env": self.env,
                            "configurationId": self.configurationId ?? ""
                        ]
                        NotificationCenter.default.post(name: Notification.Name("LaunchWidgetFromEmbedded"), object: launchData)
                    }
                }
            case "widgetError":
                if let payload = json["payload"] {
                    wrapper.onError(payload)
                }
            default:
                break
            }
        }

        private func handleBankClickMessage(_ messageBody: Any) {
            var stateCode: String?

            // Approach 1: Direct dictionary access
            if let dict = messageBody as? [String: Any],
               let payload = dict["payload"] as? [String: Any],
               let code = payload["stateCode"] as? String {
                stateCode = code
            }
            // Approach 2: String parsing
            else if let bodyStr = messageBody as? String,
                    let data = bodyStr.data(using: .utf8),
                    let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                    let payload = json["payload"] as? [String: Any],
                    let code = payload["stateCode"] as? String {
                stateCode = code
            }
            // Approach 3: Check if stateCode is directly in the body
            else if let dict = messageBody as? [String: Any],
                    let code = dict["stateCode"] as? String {
                stateCode = code
            }

            if let stateCode = stateCode {
                wrapper.onBankClick(messageBody)
                DispatchQueue.main.async {
                    // Pass both stateCode and token from embedded view
                    let launchData = [
                        "stateCode": stateCode,
                        "token": self.token,
                        "env": self.env,
                        "configurationId": self.configurationId ?? ""
                    ]
                    NotificationCenter.default.post(name: Notification.Name("LaunchWidgetFromEmbedded"), object: launchData)
                }
            } else {
                wrapper.onBankClick(messageBody)
            }
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            wrapper.onLoad(webView.url?.absoluteString ?? "")

            let triggerEventScript = """
                console.log('[iOS Debug] Setting up iOS environment...');

                // Set iOSReady flag immediately
                window.iOSReady = true;
                console.log('[iOS Debug] Set window.iOSReady = true');

                // Dispatch the iOSReady event
                var event = new CustomEvent('iOSReady', { detail: 'iOS Ready' });
                window.dispatchEvent(event);
                console.log('[iOS Debug] Dispatched iOSReady event');

                // Debug: Log all postMessage calls
                console.log('[iOS Debug] Page loaded, setting up message debugging');

                // Check if our message handlers are available
                if (window.webkit && window.webkit.messageHandlers) {
                    console.log('[iOS Debug] Available message handlers:', Object.keys(window.webkit.messageHandlers));
                } else {
                    console.log('[iOS Debug] No webkit message handlers found');
                }

                // Test message handler
                setTimeout(function() {
                    console.log('[iOS Debug] Testing message handlers after 1 second...');
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.onBankClick) {
                        console.log('[iOS Debug] onBankClick handler is available');
                    } else {
                        console.log('[iOS Debug] onBankClick handler is NOT available');
                    }
                }, 1000);
            """
            webView.evaluateJavaScript(triggerEventScript) { (result, error) in
                if let error = error {
                    print("Error triggering event: \(error)")
                } else {
                    print("Event triggered successfully")
                }
            }
        }
    }
}
#endif