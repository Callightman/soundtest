import XCTest
@testable import SoundTestCore

final class LevelMathTests: XCTestCase {
    func test_amplitude_fromDBFS() {
        XCTAssertEqual(LevelMath.amplitude(dbFS: 0), 1.0, accuracy: 1e-9)
        XCTAssertEqual(LevelMath.amplitude(dbFS: -20), 0.1, accuracy: 1e-9)
        XCTAssertEqual(LevelMath.amplitude(dbFS: -6), 0.501187, accuracy: 1e-5)
    }

    func test_lfeLevel_is10dBBelowReference() {
        XCTAssertEqual(LevelMath.lfeDBFS(referenceDBFS: -20), -30, accuracy: 1e-9)
        XCTAssertEqual(LevelMath.lfeDBFS(referenceDBFS: -30), -40, accuracy: 1e-9)
    }
}
