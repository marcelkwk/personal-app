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
    @ObservedObject private var reminder = Reminder.shared
    @State private var showSettings = false

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

            HStack {
                Spacer()
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: reminder.dailyOn ? "bell.badge.fill" : "bell")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .tint(.primary)
            }
            .padding(.trailing, 14)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 128)
        }
        .sheet(isPresented: $showSettings) {
            ReminderSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .task {
            reminder.refreshStatus()
            reminder.applyDaily()
        }
    }
}

struct ReminderSheet: View {
    @ObservedObject var reminder = Reminder.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    switch reminder.status {
                    case .authorized, .provisional, .ephemeral:
                        Toggle("Täglich erinnern", isOn: $reminder.dailyOn)
                        if reminder.dailyOn {
                            DatePicker("Uhrzeit", selection: $reminder.time, displayedComponents: .hourAndMinute)
                        }
                    case .denied:
                        Text("Benachrichtigungen sind für Logbuch abgeschaltet.")
                            .font(.footnote)
                        Button("In den Einstellungen erlauben") { reminder.openSystem() }
                    default:
                        Text("Für Erinnerungen braucht Logbuch deine Freigabe.")
                            .font(.footnote)
                        Button("Benachrichtigungen erlauben") { reminder.ask() }
                            .buttonStyle(.borderedProminent)
                    }
                } header: {
                    Text("Erinnerungen")
                } footer: {
                    Text("Die tägliche Erinnerung kommt lokal, ohne Server. Sie bleibt gesetzt, bis du sie hier abschaltest.")
                }

                Section {
                    Button("Test schicken") { reminder.test() }
                        .disabled(reminder.status == .denied)
                }
            }
            .navigationTitle("Benachrichtigungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
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
        config.userContentController.add(context.coordinator, name: "notify")

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

    static func dismantleUIView(_ view: WKWebView, coordinator: Coordinator) {
        view.configuration.userContentController.removeScriptMessageHandler(forName: "notify")
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let model: WebModel
        var token = UUID()

        init(model: WebModel) {
            self.model = model
            self.token = model.reloadToken
        }

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "notify",
                  let body = message.body as? [String: Any],
                  let text = body["body"] as? String else { return }

            let title = body["title"] as? String ?? "Logbuch"
            let minutes = body["minutes"] as? Double ?? 60

            DispatchQueue.main.async {
                Reminder.shared.later(title: title, body: text, minutes: minutes)
            }
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
