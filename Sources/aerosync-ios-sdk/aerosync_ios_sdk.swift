// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import WebKit

var environments = ["dev": "dev.aerosync.com/",
                    "staging": "staging.aerosync.com/",
                    "production": "www.aerosync.com/"]

#if os(iOS)
@available(iOS 14.0, *)
public struct AerosyncSDK: UIViewRepresentable{
    @State fileprivate var shouldDismiss = false
    
    var token: String? = nil
    var env: String = ""
    var deeplink: String? = nil
    var consumerId: String?
    var onEvent : (Any) -> ()
    var onSuccess : (Any) -> ()
    var onClose : (Any) -> ()
    var onLoad : (Any) -> ()
    var onError : (Any) -> ()
    
    public init(shouldDismiss: Bool = false, token: String? = nil, env: String, deeplink: String? = nil, consumerId: String? = nil, onEvent: @escaping (Any) -> Void, onSuccess: @escaping (Any) -> Void, onClose: @escaping (Any) -> Void, onLoad: @escaping (Any) -> Void, onError: @escaping (Any) -> Void) {
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
    }
    
    public func makeUIView(context: Context) -> WKWebView {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        let config = WKWebViewConfiguration()
        config.userContentController.add(Coordinator(wrapper: self), name: "onClose")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        // inject JS to capture console.log output and send to iOS
        let source = "function captureLog(msg) { window.webkit.messageHandlers.logHandler.postMessage(msg); } window.console.log = captureLog;"
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(script)
        // register the bridge script that listens for the output
        webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        webView.configuration.userContentController.add(Coordinator(wrapper: self), name: "logHandler")
        webView.configuration.userContentController.add(Coordinator(wrapper: self), name: "onEvent")
        webView.configuration.userContentController.add(Coordinator(wrapper: self), name: "onError")
        webView.configuration.userContentController.add(Coordinator(wrapper: self), name: "onSuccess")
        return webView
    }
    
    public func updateUIView(_ uiView: WKWebView, context: Context) {
        
        // capture oauth here???
        print("https://\(environments[env]!)?token=\(token!)&deeplink=\(deeplink!)\(consumerId != nil ? "&consumerId=\(consumerId!)" : "")")
        
        guard !shouldDismiss || !context.environment.presentationMode.wrappedValue.isPresented else {
               context.environment.presentationMode.wrappedValue.dismiss()
               return
          }
        
        let url = URL(string:"https://\(environments[env]!)?token=\(token!)&deeplink=\(deeplink!)\(consumerId != nil ? "&consumerId=\(consumerId!)" : "")")
        guard let myURL = url else {
            return
        }
        let request = URLRequest(url: myURL)
        uiView.load(request)
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(wrapper: self)
    }
    
    public class Coordinator : NSObject, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate{
        
        var wrapper: AerosyncSDK
        init(wrapper: AerosyncSDK) {
            self.wrapper = wrapper
        }
        
        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "onError", let messageBody = message.body as? String {
                print("Received message from the web: OnError \(messageBody)")
                wrapper.onError(messageBody)
            }
            if message.name == "onEvent", let messageBody = message.body as? String {
                print("Received message from the web: OnEvent \(messageBody)")
                wrapper.onEvent(messageBody)
    
            }
            if message.name == "onSuccess", let messageBody = message.body as? Any {
                print("Received message from the web: OnSuccess \(messageBody)")
                wrapper.shouldDismiss = true
                wrapper.onSuccess(messageBody)
            }
            if message.name == "onClose", let messageBody = message.body as? String {
                print("Received message from the web: OnClose \(messageBody)")
                wrapper.shouldDismiss = true
                wrapper.onClose("Closed")
            }
        }
        
        public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            print("UPDATING VIEW2:")
            decisionHandler(.allow)
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            wrapper.onLoad("\(webView.url!)")
        }
        
        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            print(navigationAction.request.url?.absoluteString)
           let urlToMatch = "https://workshop.appcoda.com/"
           if let urlStr = navigationAction.request.url?.absoluteString, urlStr == urlToMatch {
               //
           }
           decisionHandler(.allow)
       }
        public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            print("NEW WINDOW\(navigationAction.request.url?.absoluteString)")
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
