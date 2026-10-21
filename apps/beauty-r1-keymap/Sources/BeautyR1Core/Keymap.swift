import Foundation

public enum KeymapError: LocalizedError {
    case invalidConfiguration
    case selectedProfileMissing
    case invalidBundleID
    case invalidCustomKey

    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration: "Karabiner 設定檔格式無效。"
        case .selectedProfileMissing: "找不到目前使用的 Karabiner profile。"
        case .invalidBundleID: "請輸入有效的 App bundle ID，例如 com.mitchellh.ghostty。"
        case .invalidCustomKey: "自訂按鍵碼只能包含小寫英文字母、數字與底線。"
        }
    }
}

public enum ActionPreset: String, CaseIterable, Codable, Identifiable {
    case original
    case upArrow
    case downArrow
    case leftArrow
    case rightArrow
    case enter
    case escape
    case space
    case tab
    case pageUp
    case pageDown
    case yesAndEnter
    case noAndEnter
    case custom

    public var id: String { rawValue }
}

public struct ActionMapping: Codable, Equatable {
    public var preset: ActionPreset
    public var customKeyCode: String
    public var command: Bool
    public var control: Bool
    public var option: Bool
    public var shift: Bool

    public init(
        _ preset: ActionPreset,
        customKeyCode: String = "",
        command: Bool = false,
        control: Bool = false,
        option: Bool = false,
        shift: Bool = false
    ) {
        self.preset = preset
        self.customKeyCode = customKeyCode
        self.command = command
        self.control = control
        self.option = option
        self.shift = shift
    }

    public func outputEvents() throws -> [[String: Any]]? {
        let key: String
        switch preset {
        case .original: return nil
        case .upArrow: key = "up_arrow"
        case .downArrow: key = "down_arrow"
        case .leftArrow: key = "left_arrow"
        case .rightArrow: key = "right_arrow"
        case .enter: key = "return_or_enter"
        case .escape: key = "escape"
        case .space: key = "spacebar"
        case .tab: key = "tab"
        case .pageUp: key = "page_up"
        case .pageDown: key = "page_down"
        case .yesAndEnter:
            return [["key_code": "y"], ["key_code": "return_or_enter"]]
        case .noAndEnter:
            return [["key_code": "n"], ["key_code": "return_or_enter"]]
        case .custom:
            let value = customKeyCode.trimmingCharacters(in: .whitespacesAndNewlines)
            guard value.range(of: "^[a-z0-9_]+$", options: .regularExpression) != nil else {
                throw KeymapError.invalidCustomKey
            }
            key = value
        }

        var event: [String: Any] = ["key_code": key]
        if preset == .custom {
            var modifiers: [String] = []
            if command { modifiers.append("left_command") }
            if control { modifiers.append("left_control") }
            if option { modifiers.append("left_option") }
            if shift { modifiers.append("left_shift") }
            if !modifiers.isEmpty { event["modifiers"] = modifiers }
        }
        return [event]
    }
}

public struct KeymapSettings: Codable, Equatable {
    public var bundleID: String
    public var longUp: ActionMapping
    public var longDown: ActionMapping
    public var shortPress: ActionMapping

    public init(
        bundleID: String = "com.mitchellh.ghostty",
        longUp: ActionMapping = ActionMapping(.upArrow),
        longDown: ActionMapping = ActionMapping(.downArrow),
        shortPress: ActionMapping = ActionMapping(.enter)
    ) {
        self.bundleID = bundleID
        self.longUp = longUp
        self.longDown = longDown
        self.shortPress = shortPress
    }
}

public enum KarabinerKeymap {
    public static let ruleDescription = "Beauty-R1: customizable controls"
    public static let legacyRuleDescription = "Beauty-R1: control Codex CLI in Ghostty"

    private static var device: [String: Any] { [
        "vendor_id": 1452,
        "product_id": 556,
        "is_pointing_device": true
    ] }

    public static func rule(for settings: KeymapSettings) throws -> [String: Any]? {
        let bundle = settings.bundleID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard bundle.range(of: "^[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)+$", options: .regularExpression) != nil else {
            throw KeymapError.invalidBundleID
        }

        let conditions: [[String: Any]] = [
            ["type": "device_if", "identifiers": [device]],
            ["type": "frontmost_application_if", "bundle_identifiers": ["^\(NSRegularExpression.escapedPattern(for: bundle))$"]]
        ]
        let sources: [([String: Any], ActionMapping)] = [
            (["consumer_key_code": "volume_increment"], settings.longUp),
            (["consumer_key_code": "volume_decrement"], settings.longDown),
            (["pointing_button": "button1"], settings.shortPress)
        ]
        var manipulators: [[String: Any]] = []
        for (source, mapping) in sources {
            guard let output = try mapping.outputEvents() else { continue }
            manipulators.append([
                "type": "basic",
                "from": source,
                "to": output,
                "conditions": conditions
            ])
        }
        guard !manipulators.isEmpty else { return nil }
        return ["description": ruleDescription, "manipulators": manipulators]
    }

    public static func standaloneRuleData(for settings: KeymapSettings) throws -> Data? {
        guard let rule = try rule(for: settings) else { return nil }
        return try JSONSerialization.data(
            withJSONObject: ["title": "Beauty-R1 controls", "rules": [rule]],
            options: [.prettyPrinted, .sortedKeys]
        )
    }

    public static func updatedConfiguration(_ data: Data, settings: KeymapSettings) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              var profiles = root["profiles"] as? [[String: Any]],
              let index = profiles.firstIndex(where: { $0["selected"] as? Bool == true }) else {
            throw KeymapError.selectedProfileMissing
        }

        var profile = profiles[index]
        var complex = profile["complex_modifications"] as? [String: Any] ?? [:]
        var rules = complex["rules"] as? [[String: Any]] ?? []
        rules.removeAll { item in
            guard let description = item["description"] as? String else { return false }
            return description == ruleDescription || description == legacyRuleDescription
        }
        if let newRule = try rule(for: settings) { rules.insert(newRule, at: 0) }
        complex["rules"] = rules
        profile["complex_modifications"] = complex

        var devices = profile["devices"] as? [[String: Any]] ?? []
        if let deviceIndex = devices.firstIndex(where: { item in
            guard let identifiers = item["identifiers"] as? [String: Any] else { return false }
            return identifiers["vendor_id"] as? Int == 1452
                && identifiers["product_id"] as? Int == 556
                && identifiers["is_pointing_device"] as? Bool == true
        }) {
            devices[deviceIndex]["ignore"] = false
        } else {
            devices.append(["identifiers": device, "ignore": false])
        }
        profile["devices"] = devices
        profiles[index] = profile
        root["profiles"] = profiles
        return try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
    }

    public static func currentSettings(from data: Data) -> KeymapSettings? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let profiles = root["profiles"] as? [[String: Any]],
              let profile = profiles.first(where: { $0["selected"] as? Bool == true }),
              let complex = profile["complex_modifications"] as? [String: Any],
              let rules = complex["rules"] as? [[String: Any]],
              let rule = rules.first(where: {
                  let value = $0["description"] as? String
                  return value == ruleDescription || value == legacyRuleDescription
              }) else { return nil }

        var settings = KeymapSettings(
            longUp: ActionMapping(.original),
            longDown: ActionMapping(.original),
            shortPress: ActionMapping(.original)
        )
        guard let manipulators = rule["manipulators"] as? [[String: Any]] else { return settings }
        for manipulator in manipulators {
            guard let source = manipulator["from"] as? [String: Any],
                  let output = manipulator["to"] as? [[String: Any]] else { continue }
            let mapping = mapping(for: output)
            if source["consumer_key_code"] as? String == "volume_increment" { settings.longUp = mapping }
            if source["consumer_key_code"] as? String == "volume_decrement" { settings.longDown = mapping }
            if source["pointing_button"] as? String == "button1" { settings.shortPress = mapping }

            if let conditions = manipulator["conditions"] as? [[String: Any]],
               let app = conditions.first(where: { $0["type"] as? String == "frontmost_application_if" }),
               let patterns = app["bundle_identifiers"] as? [String],
               let pattern = patterns.first,
               pattern.hasPrefix("^"), pattern.hasSuffix("$") {
                settings.bundleID = String(pattern.dropFirst().dropLast()).replacingOccurrences(of: "\\.", with: ".")
            }
        }
        return settings
    }

    private static func mapping(for events: [[String: Any]]) -> ActionMapping {
        let keys = events.compactMap { $0["key_code"] as? String }
        if keys == ["y", "return_or_enter"] { return ActionMapping(.yesAndEnter) }
        if keys == ["n", "return_or_enter"] { return ActionMapping(.noAndEnter) }
        guard let key = keys.first else { return ActionMapping(.original) }
        if keys.count == 1, events[0]["modifiers"] == nil {
            let presets: [String: ActionPreset] = [
                "up_arrow": .upArrow, "down_arrow": .downArrow,
                "left_arrow": .leftArrow, "right_arrow": .rightArrow,
                "return_or_enter": .enter, "escape": .escape,
                "spacebar": .space, "tab": .tab,
                "page_up": .pageUp, "page_down": .pageDown
            ]
            if let preset = presets[key] { return ActionMapping(preset) }
        }
        let modifiers = events[0]["modifiers"] as? [String] ?? []
        return ActionMapping(
            .custom,
            customKeyCode: key,
            command: modifiers.contains("left_command"),
            control: modifiers.contains("left_control"),
            option: modifiers.contains("left_option"),
            shift: modifiers.contains("left_shift")
        )
    }
}
