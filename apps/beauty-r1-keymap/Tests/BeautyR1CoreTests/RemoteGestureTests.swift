import XCTest
@testable import BeautyR1Core

final class RemoteGestureTests: XCTestCase {
    func testFiveShortPressesFromObservedDY10Motion() {
        let samples: [(RemoteButton, Int, Int)] = [
            (.up, 0, 122),
            (.down, 0, -120),
            (.left, 64, 0),
            (.right, -96, 0),
            (.center, 0, 0)
        ]
        for (expected, x, y) in samples {
            var decoder = RemoteGestureDecoder()
            // The remote first moves the pointer to a remote-specific origin.
            XCTAssertNil(decoder.receive(usagePage: 0x01, usage: 0x30, value: -2047))
            XCTAssertNil(decoder.receive(usagePage: 0x09, usage: 0x01, value: 1))
            let motion = x != 0
                ? decoder.receive(usagePage: 0x01, usage: 0x30, value: x)
                : y != 0
                    ? decoder.receive(usagePage: 0x01, usage: 0x31, value: y)
                    : nil
            XCTAssertEqual(motion, expected == .center ? nil : expected)
            XCTAssertEqual(decoder.receive(usagePage: 0x09, usage: 0x01, value: 0), expected == .center ? .center : nil)

        }
    }

    func testMotionWithoutButtonDoesNotProduceAKey() {
        var decoder = RemoteGestureDecoder()
        XCTAssertNil(decoder.receive(usagePage: 0x01, usage: 0x31, value: 120))
        XCTAssertNil(decoder.receive(usagePage: 0x09, usage: 0x01, value: 0))
    }

    func testDirectionEmitsBeforeReleaseOnlyOnce() {
        var decoder = RemoteGestureDecoder()
        XCTAssertNil(decoder.receive(usagePage: 0x09, usage: 0x01, value: 1))
        XCTAssertNil(decoder.receive(usagePage: 0x01, usage: 0x30, value: 32))
        XCTAssertEqual(decoder.receive(usagePage: 0x01, usage: 0x30, value: 32), .left)
        XCTAssertNil(decoder.receive(usagePage: 0x01, usage: 0x30, value: 32))
        XCTAssertNil(decoder.receive(usagePage: 0x09, usage: 0x01, value: 0))
    }
}
