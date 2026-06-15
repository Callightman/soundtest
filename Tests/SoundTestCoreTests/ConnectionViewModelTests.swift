import XCTest
@testable import SoundTestCore

final class ConnectionViewModelTests: XCTestCase {
    func test_makeReport_producesAtmosSupportedForHDMI12ch() {
        let snap = RouteSnapshot(outputChannels: 12, maxOutputChannels: 32,
                                 sampleRate: 48000, portName: "Living Room", portType: "HDMI")
        let report = ConnectionLogic.makeReport(from: snap)
        XCTAssertEqual(report.atmos, .supported)
        XCTAssertEqual(report.portName, "Living Room")
    }
}
