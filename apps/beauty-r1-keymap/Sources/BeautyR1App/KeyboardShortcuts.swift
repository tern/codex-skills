import AppKit
import BeautyR1Core

struct KeyboardShortcut: Codable, Equatable {
    var keyCode: UInt16
    var modifiers: UInt8
    var label: String

    init(_ keyCode: UInt16, _ label: String, modifiers: UInt8 = 0) {
        self.keyCode = keyCode
        self.label = label
        self.modifiers = modifiers
    }

    init(event: NSEvent) {
        keyCode = event.keyCode
        let flags = event.modifierFlags
        let capturedModifiers: UInt8 = event.type == .flagsChanged ? 0 : (flags.contains(.command) ? 1 : 0)
            | (flags.contains(.control) ? 2 : 0)
            | (flags.contains(.option) ? 4 : 0)
            | (flags.contains(.shift) ? 8 : 0)
        modifiers = capturedModifiers
        let special: [UInt16: String] = [
            36: "Enter", 48: "Tab", 49: "Space", 51: "Delete", 53: "Esc",
            55: "⌘", 54: "⌘", 56: "⇧", 60: "⇧", 58: "⌥", 61: "⌥", 59: "⌃", 62: "⌃",
            123: "←", 124: "→", 125: "↓", 126: "↑", 116: "Page Up", 121: "Page Down",
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
            98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12"
        ]
        let characters = event.charactersIgnoringModifiers?.uppercased()
        let key = special[event.keyCode] ?? (characters?.isEmpty == false ? characters! : "Key \(event.keyCode)")
        let prefixes = [(1, "⌘"), (2, "⌃"), (4, "⌥"), (8, "⇧")]
            .filter { capturedModifiers & $0.0 != 0 }.map(\.1).joined()
        label = prefixes + key
    }

    func post() {
        var flags: CGEventFlags = []
        if modifiers & 1 != 0 { flags.insert(.maskCommand) }
        if modifiers & 2 != 0 { flags.insert(.maskControl) }
        if modifiers & 4 != 0 { flags.insert(.maskAlternate) }
        if modifiers & 8 != 0 { flags.insert(.maskShift) }
        for down in [true, false] {
            guard let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: down) else { continue }
            event.flags = flags
            event.post(tap: .cghidEventTap)
        }
    }
}

struct KeyboardShortcuts: Codable, Equatable {
    var values: [String: KeyboardShortcut] = [
        RemoteButton.up.rawValue: KeyboardShortcut(126, "↑"),
        RemoteButton.down.rawValue: KeyboardShortcut(125, "↓"),
        RemoteButton.left.rawValue: KeyboardShortcut(123, "←"),
        RemoteButton.right.rawValue: KeyboardShortcut(124, "→"),
        RemoteButton.center.rawValue: KeyboardShortcut(36, "Enter")
    ]

    subscript(_ button: RemoteButton) -> KeyboardShortcut {
        get { values[button.rawValue] ?? KeyboardShortcut(36, "Enter") }
        set { values[button.rawValue] = newValue }
    }

    static func load() -> Self {
        guard let data = UserDefaults.standard.data(forKey: "BeautyR1KeyboardShortcuts"),
              let value = try? JSONDecoder().decode(Self.self, from: data) else { return Self() }
        return value
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: "BeautyR1KeyboardShortcuts")
    }
}
