import XCTest
@testable import BeautyR1Core

final class KeymapTests: XCTestCase {
    private let original = """
    {
      "profiles": [
        {
          "name": "Default profile",
          "selected": true,
          "complex_modifications": {
            "rules": [
              {"description": "Keep me", "manipulators": []},
              {"description": "Beauty-R1: control Codex CLI in Ghostty", "manipulators": []}
            ]
          },
          "devices": [
            {"identifiers": {"vendor_id": 999, "product_id": 1}, "ignore": true}
          ]
        }
      ]
    }
    """.data(using: .utf8)!

    func testApplyPreservesUnrelatedRulesAndDevices() throws {
        let settings = KeymapSettings(
            longUp: ActionMapping(.pageUp),
            longDown: ActionMapping(.pageDown),
            shortPress: ActionMapping(.yesAndEnter)
        )
        let updated = try KarabinerKeymap.updatedConfiguration(original, settings: settings)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: updated) as? [String: Any])
        let profile = try XCTUnwrap((root["profiles"] as? [[String: Any]])?.first)
        let complex = try XCTUnwrap(profile["complex_modifications"] as? [String: Any])
        let rules = try XCTUnwrap(complex["rules"] as? [[String: Any]])
        XCTAssertEqual(rules.count, 2)
        XCTAssertEqual(rules[1]["description"] as? String, "Keep me")
        XCTAssertEqual(rules[0]["description"] as? String, KarabinerKeymap.ruleDescription)
        let devices = try XCTUnwrap(profile["devices"] as? [[String: Any]])
        XCTAssertEqual(devices.count, 2)
        XCTAssertEqual(devices[0]["ignore"] as? Bool, true)
        XCTAssertEqual(devices[1]["ignore"] as? Bool, false)
        XCTAssertEqual(KarabinerKeymap.currentSettings(from: updated), settings)
    }

    func testOriginalActionRemovesOnlyItsManipulator() throws {
        let settings = KeymapSettings(longUp: ActionMapping(.original))
        let rule = try XCTUnwrap(KarabinerKeymap.rule(for: settings))
        let manipulators = try XCTUnwrap(rule["manipulators"] as? [[String: Any]])
        XCTAssertEqual(manipulators.count, 2)
        XCTAssertFalse(manipulators.contains { item in
            (item["from"] as? [String: String])?["consumer_key_code"] == "volume_increment"
        })
    }

    func testCustomShortcutAndInvalidKey() throws {
        let shortcut = ActionMapping(.custom, customKeyCode: "f5", command: true, shift: true)
        let output = try XCTUnwrap(shortcut.outputEvents())
        XCTAssertEqual(output[0]["key_code"] as? String, "f5")
        XCTAssertEqual(output[0]["modifiers"] as? [String], ["left_command", "left_shift"])
        XCTAssertThrowsError(try ActionMapping(.custom, customKeyCode: "f5;rm").outputEvents())
    }

    func testInvalidBundleIDDoesNotProduceRule() {
        let settings = KeymapSettings(bundleID: "Ghostty[bad]")
        XCTAssertThrowsError(try KarabinerKeymap.rule(for: settings))
    }
}
