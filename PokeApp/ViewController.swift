// MARK: - Navigation Policy & Allowed URLs
    private func isAllowedInApp(url: URL) -> Bool {
        if url.scheme?.lowercased() == "poke" {
            return true
        }
        
        guard let host = url.host?.lowercased() else { return true }
        
        // Allow Poke domain
        if host == "poke.com" || host == "www.poke.com" {
            return true
        }
        
        // Allow OAuth / Authentication hosts so Integrations (Google, Microsoft, GitHub) work inside the app
        let allowedAuthHosts = [
            "google.com", "accounts.google.com",
            "microsoft.com", "login.microsoftonline.com", "login.live.com",
            "apple.com", "appleid.apple.com",
            "github.com"
        ]
        
        for authHost in allowedAuthHosts {
            if host == authHost || host.hasSuffix("." + authHost) {
                return true
            }
        }
        
        return false
    }

    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        // Handle poke:// scheme directly inside the app
        if url.scheme?.lowercased() == "poke" {
            handleDeepLink(url)
            decisionHandler(.cancel)
            return
        }
        
        if navigationAction.targetFrame?.isMainFrame == true {
            if isAllowedInApp(url: url) {
                decisionHandler(.allow)
            } else {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
            }
        } else {
            decisionHandler(.allow)
        }
    }
