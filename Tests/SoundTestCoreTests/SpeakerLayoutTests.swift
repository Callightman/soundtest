import XCTest
@testable import SoundTestCore

final class SpeakerLayoutTests: XCTestCase {
    func test_channelCount_sumsMainLfeHeight() {
        XCTAssertEqual(SpeakerLayout(main: 7, lfe: 1, height: 4).channelCount, 12)
        XCTAssertEqual(SpeakerLayout(main: 2, lfe: 0, height: 0).channelCount, 2)
    }

    func test_description_usesXYZformat() {
        XCTAssertEqual(SpeakerLayout(main: 5, lfe: 1, height: 2).description, "5.1.2")
        XCTAssertEqual(SpeakerLayout(main: 2, lfe: 0, height: 0).description, "2.0.0")
    }

    func test_presets_includeStereoThrough916() {
        let descs = SpeakerLayout.presets.map(\.description)
        XCTAssertTrue(descs.contains("2.0.0"))
        XCTAssertTrue(descs.contains("5.1.0"))
        XCTAssertTrue(descs.contains("7.1.4"))
        XCTAssertTrue(descs.contains("9.1.6"))
    }
}
