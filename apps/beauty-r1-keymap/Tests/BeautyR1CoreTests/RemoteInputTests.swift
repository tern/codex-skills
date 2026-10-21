import XCTest
@testable import BeautyR1Core

final class RemoteInputTests: XCTestCase {
    func testRecognizesBeautyR1PressEvents() {
        XCTAssertEqual(RemoteInput(usagePage: 0x0C, usage: 0xE9, value: 1), .longUp)
        XCTAssertEqual(RemoteInput(usagePage: 0x0C, usage: 0xEA, value: 1), .longDown)
        XCTAssertEqual(RemoteInput(usagePage: 0x09, usage: 0x01, value: 1), .shortPress)
        XCTAssertNil(RemoteInput(usagePage: 0x0C, usage: 0xE9, value: 0))
        XCTAssertNil(RemoteInput(usagePage: 0x09, usage: 0x02, value: 1))
    }

    func testPreviewUsesSelectedMapping() {
        let settings = KeymapSettings(
            longUp: ActionMapping(.pageUp),
            longDown: ActionMapping(.pageDown),
            shortPress: ActionMapping(.yesAndEnter)
        )
        XCTAssertEqual(RemoteInput.longUp.mapping(in: settings).preset, .pageUp)
        XCTAssertEqual(RemoteInput.longDown.mapping(in: settings).preset, .pageDown)
        XCTAssertEqual(RemoteInput.shortPress.mapping(in: settings).preset, .yesAndEnter)
    }
}
