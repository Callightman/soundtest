import XCTest
@testable import SoundTestCore

final class AudioSessionManagerTests: XCTestCase {
    func test_startsInactive() {
        XCTAssertEqual(AudioSessionState.machineInitial, .inactive)
    }

    func test_activate_thenInterrupt_thenResume_reprobesBeforeActive() {
        var s = AudioSessionState.machineInitial
        s = s.applying(.activate);                 XCTAssertEqual(s, .active)
        s = s.applying(.interruptionBegan);        XCTAssertEqual(s, .interrupted)
        s = s.applying(.interruptionEnded(shouldResume: true)); XCTAssertEqual(s, .needsReprobe)
        s = s.applying(.reprobed);                 XCTAssertEqual(s, .active)
    }

    func test_interruptionDuringReprobe_movesToInterrupted() {
        var s = AudioSessionState.needsReprobe
        s = s.applying(.interruptionBegan)
        XCTAssertEqual(s, .interrupted)
    }

    func test_routeChangeDuringInterruption_reprobesAfterResume() {
        var s = AudioSessionState.active
        s = s.applying(.interruptionBegan);  XCTAssertEqual(s, .interrupted)
        s = s.applying(.routeChanged);       XCTAssertEqual(s, .interrupted)
        s = s.applying(.interruptionEnded(shouldResume: true)); XCTAssertEqual(s, .needsReprobe)
        s = s.applying(.reprobed);           XCTAssertEqual(s, .active)
    }

    func test_interruptionEnded_withoutResume_goesInactive() {
        var s = AudioSessionState.active
        s = s.applying(.interruptionBegan)
        s = s.applying(.interruptionEnded(shouldResume: false))
        XCTAssertEqual(s, .inactive)
    }

    func test_routeChange_whileActive_requiresReprobe() {
        var s = AudioSessionState.active
        s = s.applying(.routeChanged)
        XCTAssertEqual(s, .needsReprobe)
        s = s.applying(.reprobed)
        XCTAssertEqual(s, .active)
    }

    func test_background_deactivates_andForegroundReactivates() {
        var s = AudioSessionState.active
        s = s.applying(.didEnterBackground); XCTAssertEqual(s, .inactive)
        s = s.applying(.willEnterForeground); XCTAssertEqual(s, .active)
    }
}
