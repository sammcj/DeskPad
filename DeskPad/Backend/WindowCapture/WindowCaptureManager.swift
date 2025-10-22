import AppKit
import Foundation
import ScreenCaptureKit

class WindowCaptureManager: NSObject {
    private var stream: SCStream?
    private var streamOutput: StreamOutput?
    private var renderWindow: NSWindow?
    private var virtualDisplayID: CGDirectDisplayID?
    private var currentWindowID: CGWindowID?
    private var streamConfiguration: SCStreamConfiguration?

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func startCapture(mode: CaptureMode, virtualDisplayID: CGDirectDisplayID) async throws {
        self.virtualDisplayID = virtualDisplayID

        switch mode {
        case .fullDesktop:
            currentWindowID = nil
            stopCapture()
        case let .window(windowID):
            currentWindowID = windowID
            try await captureWindow(windowID: windowID, virtualDisplayID: virtualDisplayID)
        }
    }

    func stopCapture() {
        Task {
            try? await stream?.stopCapture()
        }
        stream = nil
        streamOutput = nil
        streamConfiguration = nil
        renderWindow?.close()
        renderWindow = nil
    }

    @objc private func screenParametersChanged() {
        guard let virtualDisplayID = virtualDisplayID,
              let windowID = currentWindowID
        else {
            return
        }

        Task {
            try? await reconfigureCapture(windowID: windowID, virtualDisplayID: virtualDisplayID)
        }
    }

    private func reconfigureCapture(windowID _: CGWindowID, virtualDisplayID: CGDirectDisplayID) async throws {
        guard let screen = NSScreen.screens.first(where: { $0.displayID == virtualDisplayID }),
              let configuration = streamConfiguration
        else {
            return
        }

        // Capture at 3x display resolution for quality
        let displayWidth = Int(screen.frame.width * screen.backingScaleFactor * 3)
        let displayHeight = Int(screen.frame.height * screen.backingScaleFactor * 3)

        if configuration.width != displayWidth || configuration.height != displayHeight {
            configuration.width = displayWidth
            configuration.height = displayHeight
            try await stream?.updateConfiguration(configuration)

            await MainActor.run {
                updateRenderWindow(on: virtualDisplayID)
            }
        }
    }

    private func updateRenderWindow(on displayID: CGDirectDisplayID) {
        guard let screen = NSScreen.screens.first(where: { $0.displayID == displayID }),
              let window = renderWindow,
              let contentView = window.contentView as? CaptureRenderView
        else {
            return
        }

        let visibleFrame = screen.visibleFrame
        window.setFrame(visibleFrame, display: true, animate: false)
        contentView.setFrameSize(visibleFrame.size)
        contentView.setScaleFactor(screen.backingScaleFactor)
    }

    private func captureWindow(windowID: CGWindowID, virtualDisplayID: CGDirectDisplayID) async throws {
        stopCapture()

        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: false
        )

        guard let window = content.windows.first(where: { $0.windowID == windowID }) else {
            throw CaptureError.windowNotFound
        }

        let filter = SCContentFilter(desktopIndependentWindow: window)

        // Get the virtual display resolution
        guard let screen = NSScreen.screens.first(where: { $0.displayID == virtualDisplayID }) else {
            throw CaptureError.windowNotFound
        }

        // Capture at high resolution for crisp text
        // Use 3x the display resolution to maintain quality
        let displayWidth = Int(screen.frame.width * screen.backingScaleFactor * 3)
        let displayHeight = Int(screen.frame.height * screen.backingScaleFactor * 3)

        let configuration = SCStreamConfiguration()
        configuration.width = displayWidth
        configuration.height = displayHeight
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.showsCursor = true
        configuration.scalesToFit = true
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        configuration.queueDepth = 3

        streamConfiguration = configuration
        streamOutput = StreamOutput()
        stream = SCStream(filter: filter, configuration: configuration, delegate: self)

        if let streamOutput = streamOutput {
            try stream?.addStreamOutput(streamOutput, type: .screen, sampleHandlerQueue: .main)
        }

        try await stream?.startCapture()

        await MainActor.run {
            createRenderWindow(on: virtualDisplayID)
        }
    }

    private func createRenderWindow(on displayID: CGDirectDisplayID) {
        guard let screen = NSScreen.screens.first(where: { $0.displayID == displayID }) else {
            return
        }

        // Account for menu bar - use visible frame instead of full frame
        let visibleFrame = screen.visibleFrame

        // Create window with local coordinates relative to the screen
        let windowRect = CGRect(origin: .zero, size: visibleFrame.size)
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        // Position the window in the visible area (below menu bar)
        window.setFrame(visibleFrame, display: true)
        window.backgroundColor = .black
        window.level = .statusBar // Above normal windows but below menu bar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.ignoresMouseEvents = false

        let contentView = CaptureRenderView(frame: windowRect)
        contentView.setScaleFactor(screen.backingScaleFactor)
        window.contentView = contentView

        streamOutput?.renderView = contentView

        window.makeKeyAndOrderFront(nil)
        renderWindow = window
    }
}

extension WindowCaptureManager: SCStreamDelegate {
    func stream(_: SCStream, didStopWithError error: Error) {
        print("Stream stopped with error: \(error)")
        stopCapture()
    }
}

private class StreamOutput: NSObject, SCStreamOutput {
    weak var renderView: CaptureRenderView?

    func stream(
        _: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard type == .screen,
              let imageBuffer = sampleBuffer.imageBuffer
        else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.renderView?.updateFrame(imageBuffer: imageBuffer)
        }
    }
}

private class CaptureRenderView: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true

        guard let layer = layer else { return }
        layer.backgroundColor = NSColor.black.cgColor
        layer.contentsGravity = .resizeAspectFill
        layer.minificationFilter = .linear
        layer.magnificationFilter = .linear
        layer.isOpaque = true
        layer.drawsAsynchronously = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setScaleFactor(_ scaleFactor: CGFloat) {
        layer?.contentsScale = scaleFactor
    }

    func updateFrame(imageBuffer: CVImageBuffer) {
        // Convert CVImageBuffer to IOSurface and set as layer contents
        guard let ioSurface = CVPixelBufferGetIOSurface(imageBuffer)?.takeUnretainedValue() else {
            return
        }

        // Already on main thread from StreamOutput, no need to dispatch again
        layer?.contents = ioSurface
    }
}

enum CaptureError: Error {
    case windowNotFound
    case permissionDenied
}
