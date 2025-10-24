import AppKit

let app = NSApplication.shared
app.delegate = MainActor.assumeIsolated {
    AppDelegate()
}

app.run()
