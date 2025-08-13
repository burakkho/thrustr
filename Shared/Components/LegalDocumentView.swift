import SwiftUI
import WebKit

struct LegalDocumentView: View {
    let title: String
    let resourceBaseName: String // e.g., "terms" or "privacy"
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
            }
            .padding()
            Divider()
            WebView(htmlString: loadHTML())
                .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    private func loadHTML() -> String {
        // Try language-specific resources first
        let preferredOrder: [String] = {
            let lang = UserDefaults.standard.string(forKey: "app_language") ?? "system"
            let systemLang = Locale.preferredLanguages.first ?? "en"
            var codes: [String] = []
            if lang == "tr" { codes.append("tr") }
            else if lang == "en" { codes.append("en") }
            else { codes.append(String(systemLang.prefix(2))) }
            codes.append("en") // fallback
            return codes
        }()
        let bundle = Bundle.main
        for code in preferredOrder {
            if let url = bundle.url(forResource: "\(resourceBaseName)_\(code)", withExtension: "html"),
               let data = try? Data(contentsOf: url),
               let html = String(data: data, encoding: .utf8) {
                return html
            }
        }
        if let url = bundle.url(forResource: resourceBaseName, withExtension: "html"),
           let data = try? Data(contentsOf: url),
           let html = String(data: data, encoding: .utf8) {
            return html
        }
        // Placeholder content
        return """
        <html><head><meta name=\"viewport\" content=\"initial-scale=1, maximum-scale=1\"><style>body{font-family:-apple-system,BlinkMacSystemFont;line-height:1.5;padding:16px;} h1{font-size:20px;} p{color:#444;}</style></head><body>
        <h1>\(title)</h1>
        <p>Bu belge için geçici içerik gösteriliyor. Yayın öncesi gerçek yasal metin eklenecektir.</p>
        </body></html>
        """
    }
}

private struct WebView: UIViewRepresentable {
    let htmlString: String
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlString, baseURL: nil)
    }
}


