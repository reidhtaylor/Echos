//
//  SpotifyAuthView.swift
//  AM
//
//  Created by Reid Taylor on 8/9/24.
//

import SwiftUI
import WebKit

struct SpotifyAuthView: NSViewRepresentable {
    
    @State var library : MusicLibrary
    
    var onCompletion : () -> Void
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        
        return webView
    }
 
    func updateNSView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: library.spotifyAuthURL!)
        webView.load(request)
    }
    
    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(self)
    }
    
    class WebViewCoordinator: NSObject, WKNavigationDelegate {
        var parent: SpotifyAuthView
        var isDispatched : Bool = false

        init(_ parent: SpotifyAuthView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            let url : String = navigationAction.request.url!.absoluteString
            
            // Check if url is redirect for Auth
            if url.count >= MusicLibrary.redirectURI.count {
                if MusicLibrary.redirectURI == url[...url.index(url.startIndex, offsetBy: MusicLibrary.redirectURI.count - 1)] {
                    self.parent.library.spotifyAuthResponse = url
                    self.parent.library.ERROR = 777 // Set no error
                    self.parent.onCompletion()
                }
                else {
                    if !isDispatched && self.parent.library.musicSource == .spotify {
                        isDispatched = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            getRequest("https://captive.apple.com", authToken: "", onSuccess: { _ in }, onError: { err, status in
                                print("TEST CONNECTION: ERROR: \(err)")
                                
                                self.parent.library.ERROR = status
                            })
                            
                            self.isDispatched = false
                        }
                    }
                }
            }
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            guard let serverTrust = challenge.protectionSpace.serverTrust  else {
                completionHandler(.useCredential, nil)
                return
            }
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        }
    }
}
