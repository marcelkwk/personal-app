import SwiftUI
import WebKit

@main
struct PersonalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

final class WebModel: ObservableObject {
    @Published var progress: Double = 0
    @Published var failed = false
    @Published var reloadToken = UUID()

    let url = URL(string: "https://marcelkwk.github.io/personal-app/")!

    func reload() {
        failed = false
        progress = 0
        reloadToken = UUID()
    }
}

struct ContentView: View {
    @StateObject private var model = WebModel()

    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.05, green: 0.06, blue: 0.07).ignoresSafeArea()

            WebView(model: model)

            if model.progress > 0 && model.progress < 1 {
                ProgressView(value: model.progress)
                    .progressViewStyle(.linear)
                    .tint(Color(red: 0.49, green: 0.84, blue: 0.42))
            }

            if model.failed {
                VStack(spacing: 14) {
                    Text("Keine Verbindung")
                        .font(.headline)
                    Text("Die Seite ist beim ersten Start nicht erreichbar.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Nochmal") { model.reload() }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0.49, green: 0.84, blue: 0.42))
                }
                .padding(24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                .padding(32)
                .frame(maxHeight: .infinity)
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    @ObservedObject var model: WebModel

    func makeCoordinator() -> Coordinator { Coordinator(model: model) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true

        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.isOpaque = false
        view.backgroundColor = UIColor(red: 0.05, green: 0.06, blue: 0.07, alpha: 1)
        view.load(URLRequest(url: model.url))
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        if context.coordinator.token != model.reloadToken {
            context.coordinator.token = model.reloadToken
            view.load(URLRequest(url: model.url))
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let model: WebModel
        var token = UUID()

        init(model: WebModel) {
            self.model = model
            self.token = model.reloadToken
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            model.progress = 0.1
            model.failed = false
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            model.progress = 1
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            model.progress = 1
            model.failed = true
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            model.progress = 1
            model.failed = true
        }
    }
}
