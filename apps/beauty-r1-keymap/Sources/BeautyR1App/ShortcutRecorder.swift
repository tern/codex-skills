import SwiftUI

struct ShortcutRecorder: NSViewRepresentable {
    @Binding var shortcut: KeyboardShortcut

    func makeCoordinator() -> Coordinator { Coordinator(shortcut: $shortcut) }

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton(title: shortcut.label, target: context.coordinator, action: #selector(Coordinator.begin))
        button.bezelStyle = .rounded
        context.coordinator.button = button
        return button
    }

    func updateNSView(_ button: NSButton, context: Context) {
        context.coordinator.shortcut = $shortcut
        if context.coordinator.monitor == nil { button.title = shortcut.label }
    }

    static func dismantleNSView(_ button: NSButton, coordinator: Coordinator) {
        coordinator.cancel()
    }

    @MainActor final class Coordinator: NSObject {
        var shortcut: Binding<KeyboardShortcut>
        weak var button: NSButton?
        var monitor: Any?
        var pendingModifier: NSEvent?

        init(shortcut: Binding<KeyboardShortcut>) { self.shortcut = shortcut }

        @objc func begin() {
            stop()
            button?.title = "請按鍵盤按鍵…"
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
                guard let self else { return event }
                if event.type == .flagsChanged {
                    if !event.modifierFlags.intersection([.command, .control, .option, .shift]).isEmpty {
                        self.pendingModifier = event
                        return nil
                    }
                    guard let pending = self.pendingModifier else { return nil }
                    self.shortcut.wrappedValue = KeyboardShortcut(event: pending)
                } else {
                    self.shortcut.wrappedValue = KeyboardShortcut(event: event)
                }
                self.stop()
                return nil
            }
        }

        private func stop() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
            pendingModifier = nil
            button?.title = shortcut.wrappedValue.label
        }

        func cancel() { stop() }
    }
}
