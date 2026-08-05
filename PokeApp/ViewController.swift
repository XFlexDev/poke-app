import UIKit
import WebKit
import LocalAuthentication
import AVFoundation
import AudioToolbox
import UserNotifications

class CustomWebView: WKWebView {
    override var inputAccessoryView: UIView? {
        return nil
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
}

class ViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate {
    
    private var webView: CustomWebView!
    private var splashOverlay: UIView!
    private var isSplashFaded = false
    
    var pendingDeepLink: URL?
    private let themeColor = UIColor(red: 17/255, green: 23/255, blue: 32/255, alpha: 1.0)
    
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    private let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionHaptic = UISelectionFeedbackGenerator()
    private let notificationHaptic = UINotificationFeedbackGenerator()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = themeColor
        prepareHaptics()
        setupWebView()
        setupSplashOverlay()
        
        if let deepLink = pendingDeepLink {
            handleDeepLink(deepLink)
            pendingDeepLink = nil
        } else {
            loadTargetURL()
        }
        
        checkForUpdates()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func prepareHaptics() {
        lightHaptic.prepare()
        mediumHaptic.prepare()
        heavyHaptic.prepare()
        selectionHaptic.prepare()
        notificationHaptic.prepare()
    }

    func handleDeepLink(_ url: URL) {
        guard url.scheme?.lowercased() == "poke" else { return }
        
        let host = url.host?.lowercased() ?? ""
        let path = url.path.lowercased()
        
        if host == "inbox" || path.contains("inbox") {
            if let inboxURL = URL(string: "https://poke.com/inbox") {
                let request = URLRequest(url: inboxURL)
                webView?.load(request)
            }
        }
    }

    private func setupSplashOverlay() {
        splashOverlay = UIView(frame: view.bounds)
        splashOverlay.backgroundColor = themeColor
        splashOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        if let logoImage = UIImage(named: "LaunchLogo") {
            let imageView = UIImageView(image: logoImage)
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            splashOverlay.addSubview(imageView)
            
            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: splashOverlay.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: splashOverlay.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 180),
                imageView.heightAnchor.constraint(equalToConstant: 180)
            ])
        }
        
        view.addSubview(splashOverlay)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.dismissSplashOverlay()
        }
    }

    private func dismissSplashOverlay() {
        guard !isSplashFaded else { return }
        isSplashFaded = true
        
        UIView.animate(withDuration: 0.5, delay: 0.1, options: .curveEaseInOut, animations: {
            self.splashOverlay.alpha = 0.0
        }) { _ in
            self.splashOverlay.removeFromSuperview()
        }
    }

    private func setupWebView() {
        let contentController = WKUserContentController()
        
        let handlers = [
            "nativeHaptic",
            "nativeShare",
            "nativeTorch",
            "nativeClipboard",
            "nativeBrightness",
            "nativeAuthenticate",
            "nativeSound",
            "nativeBadge"
        ]
        
        for handler in handlers {
            contentController.add(self, name: handler)
        }
        
        let jsScript = """
        (function() {
            var meta = document.querySelector('meta[name="viewport"]');
            if (!meta) {
                meta = document.createElement('meta');
                meta.name = 'viewport';
                document.head.appendChild(meta);
            }
            meta.content = 'width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';

            window._pokeCallbacks = {};

            window.PokeNative = {
                haptic: function(style) {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.nativeHaptic) {
                        window.webkit.messageHandlers.nativeHaptic.postMessage(style || 'medium');
                    }
                },
                share: function(options) {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.nativeShare) {
                        window.webkit.messageHandlers.nativeShare.postMessage(options || {});
                    }
                },
                setTorch: function(enabled) {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.nativeTorch) {
                        window.webkit.messageHandlers.nativeTorch.postMessage(!!enabled);
                    }
                },
                copyToClipboard: function(text) {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.nativeClipboard) {
                        window.webkit.messageHandlers.nativeClipboard.postMessage(text || '');
                    }
                },
                setBrightness: function(level) {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.nativeBrightness) {
                        window.webkit.messageHandlers.nativeBrightness.postMessage(level);
                    }
                },
                playSound: function(soundId) {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.nativeSound) {
                        window.webkit.messageHandlers.nativeSound.postMessage(soundId || 1057);
                    }
                },
                setBadge: function(count) {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.nativeBadge) {
                        window.webkit.messageHandlers.nativeBadge.postMessage(count || 0);
                    }
                },
                authenticate: function(reason) {
                    return new Promise(function(resolve, reject) {
                        var reqId = 'req_' + Date.now() + '_' + Math.floor(Math.random() * 10000);
                        window._pokeCallbacks[reqId] = function(success, errorMsg) {
                            if (success) {
                                resolve(true);
                            } else {
                                reject(errorMsg || 'Authentication failed');
                            }
                            delete window._pokeCallbacks[reqId];
                        };
                        window.webkit.messageHandlers.nativeAuthenticate.postMessage({
                            reason: reason || 'Unlock Poke feature',
                            reqId: reqId
                        });
                    });
                }
            };

            var style = document.createElement('style');
            style.id = 'poke-strict-native-styles';
            style.innerHTML = `
                *, *::before, *::after {
                    -webkit-touch-callout: none !important;
                    -webkit-user-select: none !important;
                    -khtml-user-select: none !important;
                    -moz-user-select: none !important;
                    -ms-user-select: none !important;
                    user-select: none !important;
                    -webkit-tap-highlight-color: transparent !important;
                    -webkit-user-drag: none !important;
                }
                input, textarea, [contenteditable="true"] {
                    -webkit-user-select: text !important;
                    user-select: text !important;
                    caret-color: #007aff !important;
                    font-size: 16px !important;
                }
                ::-webkit-scrollbar {
                    display: none !important;
                }
                :root, html, body, ion-app {
                    --ion-safe-area-top: max(env(safe-area-inset-top, 47px), 47px) !important;
                }
                [data-silk-sheet-wrapper],
                ion-modal,
                div[data-silk-sheet-wrapper] {
                    margin-top: max(env(safe-area-inset-top, 47px), 47px) !important;
                    max-height: calc(100vh - max(env(safe-area-inset-top, 47px), 47px)) !important;
                    border-top-left-radius: 24px !important;
                    border-top-right-radius: 24px !important;
                    overflow: hidden !important;
                }
                .ion-page[style*="z-index: 101"],
                div.h-full.ion-page {
                    margin-top: 0 !important;
                }
            `;
            document.head.appendChild(style);

            document.addEventListener('selectstart', function(e) {
                var tag = e.target.tagName ? e.target.tagName.toUpperCase() : '';
                if (tag !== 'INPUT' && tag !== 'TEXTAREA') {
                    e.preventDefault();
                }
            }, true);
            
            document.addEventListener('contextmenu', function(e) { e.preventDefault(); }, true);

            function applyOption2Layout() {
                ['Recipes', 'Message'].forEach(function(name) {
                    var el = document.querySelector('[aria-label="' + name + '"]');
                    if (!el) {
                        var elements = Array.from(document.querySelectorAll('button, a'));
                        el = elements.find(function(item) {
                            return item.innerText && item.innerText.trim() === name;
                        });
                    }
                    if (el) {
                        var wrapper = el.closest('.min-w-0') || el;
                        wrapper.remove();
                    }
                });

                var mailBtn = document.querySelector('[aria-label="Mail"]') ||
                               Array.from(document.querySelectorAll('a')).find(function(el) {
                                   return el.innerText && el.innerText.trim() === 'Mail';
                               });
                
                if (mailBtn) {
                    var mailWrapper = mailBtn.closest('.min-w-0');
                    if (mailWrapper) {
                        mailWrapper.style.width = '100%';
                        mailWrapper.style.flex = '1 1 100%';
                    }
                }

                injectKreatixSection();
            }

            function injectKreatixSection() {
                if (document.getElementById('kreatix-custom-row')) return;

                var twitterEl = Array.from(document.querySelectorAll('a, button, div')).find(function(el) {
                    return el.innerText && el.innerText.trim() === 'Twitter';
                });

                if (!twitterEl) return;

                var twitterLink = twitterEl.tagName === 'A' ? twitterEl : twitterEl.closest('a');
                if (!twitterLink || !twitterLink.parentNode) return;

                twitterLink.style.borderBottomLeftRadius = '0px';
                twitterLink.style.borderBottomRightRadius = '0px';

                var row = document.createElement('a');
                row.id = 'kreatix-custom-row';
                row.href = 'https://x.com/KreatixDev';
                row.target = '_blank';
                row.rel = 'noopener noreferrer';
                row.className = twitterLink.className || '';
                
                row.style.cssText = `
                    display: flex !important;
                    flex-direction: row !important;
                    align-items: center !important;
                    justify-content: space-between !important;
                    width: 100% !important;
                    box-sizing: border-box !important;
                    padding: 14px 16px !important;
                    border-top: 1px solid rgba(0, 0, 0, 0.06) !important;
                    border-bottom-left-radius: 20px !important;
                    border-bottom-right-radius: 20px !important;
                    text-decoration: none !important;
                `;

                row.innerHTML = `
                    <div style="display: flex !important; align-items: center !important; gap: 12px !important; min-width: 0 !important; flex: 1 !important;">
                        <svg style="width: 18px !important; height: 18px !important; min-width: 18px !important; fill: #4b5563 !important; flex-shrink: 0 !important;" viewBox="0 0 24 24">
                            <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
                        </svg>
                        <span style="font-size: 14px !important; font-weight: 500 !important; color: #1f2937 !important; white-space: nowrap !important; overflow: hidden !important; text-overflow: ellipsis !important;">iOS app made by KreatixDev</span>
                    </div>
                    <svg style="width: 16px !important; height: 16px !important; min-width: 16px !important; stroke: #9ca3af !important; fill: none !important; flex-shrink: 0 !important; margin-left: 8px !important;" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
                    </svg>
                `;

                twitterLink.parentNode.insertBefore(row, twitterLink.nextSibling);

                var cardContainer = twitterLink;
                while (cardContainer && cardContainer.parentElement) {
                    if (cardContainer.classList && (cardContainer.classList.contains('rounded-3xl') || cardContainer.classList.contains('rounded-2xl') || cardContainer.classList.contains('border'))) {
                        break;
                    }
                    cardContainer = cardContainer.parentElement;
                }

                if (cardContainer && cardContainer.parentNode && !document.getElementById('kreatix-disclaimer')) {
                    var disclaimer = document.createElement('div');
                    disclaimer.id = 'kreatix-disclaimer';
                    disclaimer.style.cssText = 'width: 100% !important; text-align: center !important; font-size: 11px !important; font-weight: 500 !important; color: #9ca3af !important; margin-top: 12px !important; margin-bottom: 8px !important; opacity: 0.8 !important; display: block !important; clear: both !important;';
                    disclaimer.innerText = 'Not affiliated with Interaction or Cognition';
                    cardContainer.parentNode.insertBefore(disclaimer, cardContainer.nextSibling);
                }
            }

            applyOption2Layout();
            var observer = new MutationObserver(applyOption2Layout);
            observer.observe(document.body || document.documentElement, { childList: true, subtree: true });

            var lastTouchTime = 0;
            function handleTouchStart(e) {
                var target = e.target;
                if (!target) return;

                var btn = target.closest('button, a[href], [role="button"], [aria-label="About"], [aria-label="Settings"], [aria-label="Automations"], [aria-label="Integrations"], [aria-label="Mail"]');
                
                if (!btn) return;

                var rect = btn.getBoundingClientRect();
                if (rect.width > window.innerWidth * 0.95 && rect.height > window.innerHeight * 0.90) return;

                var now = Date.now();
                if (now - lastTouchTime < 120) return;
                lastTouchTime = now;

                var label = btn.getAttribute ? btn.getAttribute('aria-label') : '';
                if (label === 'About' || label === 'Settings' || (btn.querySelector && btn.querySelector('img[alt="Avatar"]'))) {
                    window.PokeNative.haptic('selection');
                } else {
                    window.PokeNative.haptic('medium');
                }
            }

            document.addEventListener('touchstart', handleTouchStart, { capture: true, passive: true });
            document.addEventListener('mousedown', handleTouchStart, { capture: true, passive: true });
        })();
        """
        
        let userScript = WKUserScript(source: jsScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        contentController.addUserScript(userScript)

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.allowsInlineMediaPlayback = true

        webView = CustomWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        webView.scrollView.delegate = self
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = themeColor

        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func loadTargetURL() {
        if let url = URL(string: "https://poke.com/home") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    private func checkForUpdates() {
        guard let repo = Bundle.main.object(forInfoDictionaryKey: "GitHubRepository") as? String,
              !repo.isEmpty, !repo.contains("$") else { return }
        
        let apiUrlString = "https://api.github.com/repos/\(repo)/releases/latest"
        guard let apiUrl = URL(string: apiUrlString) else { return }
        
        var request = URLRequest(url: apiUrl)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else { return }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String else { return }
            
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
            let latestVersion = tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            let currentClean = currentVersion.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            
            if latestVersion != currentClean {
                DispatchQueue.main.async {
                    self?.showUpdateAlert()
                }
            }
        }.resume()
    }

    private func showUpdateAlert() {
        let alert = UIAlertController(
            title: "Update Available",
            message: nil,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Update", style: .default) { _ in
            if let downloadUrl = URL(string: "https://github.com/XFlexDev/poke-app/releases/latest/download/Poke.ipa") {
                UIApplication.shared.open(downloadUrl, options: [:], completionHandler: nil)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Later", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }

    private func isAllowedInApp(url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return true }
        
        guard host == "poke.com" || host == "www.poke.com" else {
            return false
        }
        
        let path = url.path.lowercased()
        
        if path == "" || path == "/" ||
           path == "/home" || path == "/home/" ||
           path == "/about" || path == "/about/" ||
           path.hasPrefix("/settings") ||
           path.hasPrefix("/automations") ||
           path.hasPrefix("/inbox") ||
           path.hasPrefix("/integrations") {
            return true
        }
        
        return false
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }

    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
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

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        dismissSplashOverlay()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        dismissSplashOverlay()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        dismissSplashOverlay()
    }

    // MARK: - WKUIDelegate
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            if isAllowedInApp(url: url) {
                webView.load(navigationAction.request)
            } else {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        return nil
    }

    // MARK: - WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "nativeHaptic":
            if let type = message.body as? String {
                switch type {
                case "light": lightHaptic.impactOccurred()
                case "medium": mediumHaptic.impactOccurred()
                case "heavy": heavyHaptic.impactOccurred()
                case "selection": selectionHaptic.selectionChanged()
                case "success": notificationHaptic.notificationOccurred(.success)
                case "warning": notificationHaptic.notificationOccurred(.warning)
                case "error": notificationHaptic.notificationOccurred(.error)
                default: mediumHaptic.impactOccurred()
                }
            }
        case "nativeShare":
            if let dict = message.body as? [String: Any] {
                var items: [Any] = []
                if let text = dict["text"] as? String { items.append(text) }
                if let urlString = dict["url"] as? String, let url = URL(string: urlString) { items.append(url) }
                guard !items.isEmpty else { return }
                let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
                present(activityVC, animated: true)
            }
        case "nativeTorch":
            if let enable = message.body as? Bool,
               let device = AVCaptureDevice.default(for: .video), device.hasTorch {
                try? device.lockForConfiguration()
                device.torchMode = enable ? .on : .off
                device.unlockForConfiguration()
            }
        case "nativeClipboard":
            if let text = message.body as? String {
                UIPasteboard.general.string = text
                notificationHaptic.notificationOccurred(.success)
            }
        case "nativeBrightness":
            if let level = message.body as? Double {
                UIScreen.main.brightness = CGFloat(level)
            }
        case "nativeSound":
            if let soundId = message.body as? UInt32 {
                AudioServicesPlaySystemSound(soundId)
            }
        case "nativeBadge":
            if let count = message.body as? Int {
                if #available(iOS 16.0, *) {
                    UNUserNotificationCenter.current().setBadgeCount(count)
                } else {
                    UIApplication.shared.applicationIconBadgeNumber = count
                }
            }
        case "nativeAuthenticate":
            if let dict = message.body as? [String: String],
               let reason = dict["reason"],
               let reqId = dict["reqId"] {
                let context = LAContext()
                var error: NSError?
                if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                    context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, evalError in
                        DispatchQueue.main.async {
                            let js = "window._pokeCallbacks['\(reqId)'](\(success), '\(evalError?.localizedDescription ?? "")');"
                            self?.webView.evaluateJavaScript(js, completionHandler: nil)
                        }
                    }
                } else {
                    let js = "window._pokeCallbacks['\(reqId)'](false, 'Biometrics not available');"
                    webView.evaluateJavaScript(js, completionHandler: nil)
                }
            }
        default:
            break
        }
    }
}
