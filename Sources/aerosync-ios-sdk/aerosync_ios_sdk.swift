// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import WebKit
import QuantumIOS
import UIKit

var environments = ["dev": "https://qa-sync.aero.inc",
                    "sandbox": "https://sandbox.aerosync.com",
                    "staging": "https://staging-sync.aero.inc",
                    "production": "https://sync.aero.inc"]

#if os(iOS)
@available(iOS 14.0, *)
public struct AerosyncSDK: UIViewControllerRepresentable {
    public typealias UIViewControllerType = UIKitViewController
    @State fileprivate var shouldDismiss = false
    
    var token: String
    var env: String
    var deeplink: String
    var consumerId: String?
    var onEvent : (Any) -> ()
    var onSuccess : (String) -> ()
    var onClose : (Any) -> ()
    var onLoad : (Any) -> ()
    var onError : (Any) -> ()
    var handleMFA : Bool
    var userId: String?
    var jobId: String?
    
    public init(shouldDismiss: Bool = false, token: String, env: String, deeplink: String, consumerId: String? = nil, onEvent: @escaping (Any) -> Void, onSuccess: @escaping (String) -> Void, onClose: @escaping (Any) -> Void, onLoad: @escaping (Any) -> Void, onError: @escaping (Any) -> Void, handleMFA: Bool = false, jobId: String? = "", userId: String? = "") {
        self.shouldDismiss = shouldDismiss
        self.token = token
        self.env = env
        self.deeplink = deeplink
        self.consumerId = consumerId
        self.onEvent = onEvent
        self.onSuccess = onSuccess
        self.onClose = onClose
        self.onLoad = onLoad
        self.onError = onError
        self.handleMFA = handleMFA
        self.jobId = jobId
        self.userId = userId
    }
    
    public func makeUIViewController(context: Context) -> UIKitViewController {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        let config = WKWebViewConfiguration()
        
        let webView = WKWebView(frame: .zero, configuration: config)
        
        let quantum: Quantum = Quantum(view: webView, controller: UIKitViewController())
        
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
        
        let url = URL(string: """
            \(environments[env]!)?token=\(token)&deeplink=\(deeplink)\
            \(consumerId != nil ? "&consumerId=\(consumerId!)" : "")\
            \(handleMFA != false ? "&handleMFA=\(handleMFA)&userID=\(userId!)&jobId=\(jobId!)" : "")
            """)
        let request = URLRequest(url: url!)
        webView.load(request)
        return UIKitViewController()
    }
    
    public func updateUIViewController(_ uiViewController: UIKitViewController, context: Context) {
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
            if message.name == "onError", let messageBody = message.body as? String {
                wrapper.onError(messageBody)
            }
            if message.name == "onEvent", let messageBody = message.body as? String {
                wrapper.onEvent(messageBody)
            }
            if message.name == "onSuccess", let messageBody = message.body as? String {
                wrapper.shouldDismiss = true
                wrapper.onSuccess(messageBody)
            }
            if message.name == "onClose", let messageBody = message.body as? Any {
                wrapper.shouldDismiss = true
                wrapper.onClose("Closed")
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

public class UIKitViewController: UIViewController {
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
}
