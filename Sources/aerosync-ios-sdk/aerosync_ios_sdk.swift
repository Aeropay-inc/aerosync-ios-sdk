import SwiftUI
import WebKit

var environments = ["dev": "https://qa-sync.aero.inc",
                    "sandbox": "https://sandbox.aerosync.com",
                    "staging": "https://staging-sync.aero.inc",
                    "production": "https://sync.aero.inc"]

#if os(iOS)
@available(iOS 14.0, *)
public struct AerosyncSDK: UIViewRepresentable{
    @State fileprivate var shouldDismiss = false
    
    var token: String
    var env: String
    var deeplink: String
    var configurationId: String?
    var aeroPassUserUuid: String
    var stateCode: String?
    var theme: String
    var manualLinkOnly: Bool
    var handleMFA : Bool
    var jobId: String?
    var connectionId: String?
    var onEvent : (Any) -> ()
    var onSuccess : (String) -> ()
    var onClose : (Any) -> ()
    var onLoad : (Any) -> ()
    var onError : (Any) -> ()
    
    public init(shouldDismiss: Bool = false, token: String, env: String, deeplink: String, aeroPassUserUuid: String, configurationId: String? = nil, stateCode: String? = nil, theme: String = "light", manualLinkOnly: Bool = false, handleMFA: Bool = false, jobId: String? = "", connectionId: String? = "", onEvent: @escaping (Any) -> Void, onSuccess: @escaping (String) -> Void, onClose: @escaping (Any) -> Void, onLoad: @escaping (Any) -> Void, onError: @escaping (Any) -> Void) {
        self.shouldDismiss = shouldDismiss
        self.token = token
        self.env = env
        self.deeplink = deeplink
        self.configurationId = configurationId
        self.aeroPassUserUuid = aeroPassUserUuid
        self.stateCode = stateCode
        self.theme = theme
        self.manualLinkOnly = manualLinkOnly
        self.handleMFA = handleMFA
        self.jobId = jobId
        self.connectionId = connectionId
        self.onEvent = onEvent
        self.onSuccess = onSuccess
        self.onClose = onClose
        self.onLoad = onLoad
        self.onError = onError
    }
    
    public func makeUIView(context: Context) -> WKWebView {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        let config = WKWebViewConfiguration()
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        // inject JS to capture console.log output and send to iOS
        let source = "function captureLog(msg) { window.webkit.messageHandlers.logHandler.postMessage(msg); } window.console.log = captureLog;"
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(script)
        
        // register the bridge script that listens for the output
        webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        webView.configuration.userContentController.add(Coordinator(wrapper: self), name: "onClose")
        webView.configuration.userContentController.add(Coordinator(wrapper: self), name: "logHandler")
        webView.configuration.userContentController.add(Coordinator(wrapper: self), name: "onEvent")
        webView.configuration.userContentController.add(Coordinator(wrapper: self), name: "onError")
        webView.configuration.userContentController.add(Coordinator(wrapper: self), name: "onSuccess")
        webView.configuration.userContentController.add(Coordinator(wrapper: self), name: "onBankClick")
        context.coordinator.webView = webView

        // SETUP GESTURE RECOGNIZER
        let gestureRecognizerBack = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleBack))
        gestureRecognizerBack.direction = .right // back navigation
        gestureRecognizerBack.delegate = context.coordinator
        webView.addGestureRecognizer(gestureRecognizerBack)
        
        let gestureRecognizerForward = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleForward))
        gestureRecognizerForward.direction = .left // forward navigation
        gestureRecognizerForward.delegate = context.coordinator
        webView.addGestureRecognizer(gestureRecognizerForward)
        
        webView.isUserInteractionEnabled = true
        webView.allowsBackForwardNavigationGestures = true
        
        // Build URL components properly with encoding
        var components = URLComponents(string: environments[env]!)!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "deeplink", value: deeplink),
            URLQueryItem(name: "version", value: "2.0.0")
        ]

        if let configId = configurationId {
            queryItems.append(URLQueryItem(name: "configurationId", value: configId))
        }

        queryItems.append(URLQueryItem(name: "aeroPassUserUuid", value: aeroPassUserUuid))

        if let stateCodeValue = stateCode {
            queryItems.append(URLQueryItem(name: "stateCode", value: stateCodeValue))
        }

        queryItems.append(URLQueryItem(name: "defaultTheme", value: theme))

        if manualLinkOnly {
            queryItems.append(URLQueryItem(name: "manualLinkOnly", value: "true"))
        }

        if handleMFA {
            queryItems.append(URLQueryItem(name: "handleMFA", value: "true"))
            if let connId = connectionId {
                queryItems.append(URLQueryItem(name: "connectionId", value: connId))
            }
            if let jId = jobId {
                queryItems.append(URLQueryItem(name: "jobId", value: jId))
            }
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            return webView
        }
        print("Loading Widget URL: \(url)")

        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    
    public func updateUIView(_ uiView: WKWebView, context: Context) {
        guard !shouldDismiss || !context.environment.presentationMode.wrappedValue.isPresented else {
               context.environment.presentationMode.wrappedValue.dismiss()
               return
          }
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(wrapper: self)
    }

    public class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate, UIGestureRecognizerDelegate {
        
        var wrapper: AerosyncSDK
        var webView: WKWebView?
        
        init(wrapper: AerosyncSDK) {
            self.wrapper = wrapper
        }
        
        public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
        
        public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
        
        @objc public func handleBack() {
            if webView!.canGoBack {
                webView!.goBack()
            }
        }
        
        @objc public func handleForward() {
            if webView!.canGoForward {
                webView!.goForward()
            }
        }
        
        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            switch message.name {
                case "onError":
                    wrapper.onError(message.body)
                case "onBankClick":
                    wrapper.onEvent(message.body)
                case "onEvent":
                    print("onEvent: \(message.body)")
                    wrapper.onEvent(message.body)
                case "onSuccess":
                    wrapper.shouldDismiss = true
                    if let body = message.body as? String {
                        wrapper.onSuccess(body)
                    } else {
                        wrapper.onSuccess("\(message.body)")
                    }
                case "onClose":
                    wrapper.shouldDismiss = true
                    wrapper.onClose("Closed")
                default:
                    print("Unhandled event type: \(message.name)")
            }
        }
        
        public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            decisionHandler(.allow)
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            wrapper.onLoad("\(webView.url!)")
            let triggerEventScript = """
                var event = new CustomEvent('iOSReady', { detail: 'iOS Ready' });
                window.dispatchEvent(event);
            """
            webView.evaluateJavaScript(triggerEventScript) { (result, error) in
                if let error = error {
                    print("Error triggering event: \(error)")
                } else {
                    print("Event triggered successfully")
                }
            }
        }
        
        public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url {
                if navigationAction.targetFrame == nil {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
            }
            return nil
        }
    }
}
#endif