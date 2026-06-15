import XCTest
@testable import SoundTestCore

final class CapabilityProbeTests: XCTestCase {
    private func report(channels: Int, max: Int, port: String) -> CapabilityReport {
        let snap = RouteSnapshot(outputChannels: channels, maxOutputChannels: max,
                                 sampleRate: 48000, portName: "Living Room", portType: port)
        return CapabilityProbe().evaluate(snap)
    }

    func test_stereoAlwaysSupported_whenAtLeastTwoChannels() {
        XCTAssertEqual(report(channels: 2, max: 2, port: "HDMI").stereo, .supported)
    }

    func test_51requiresSixChannels() {
        XCTAssertEqual(report(channels: 2, max: 2, port: "HDMI").surround51, .unsupported)
        XCTAssertEqual(report(channels: 6, max: 8, port: "HDMI").surround51, .supported)
    }

    func test_71requiresEightChannels() {
        XCTAssertEqual(report(channels: 6, max: 6, port: "HDMI").surround71, .unsupported)
        XCTAssertEqual(report(channels: 8, max: 8, port: "HDMI").surround71, .supported)
    }

    func test_atmos_unknownUnlessHDMIWithEightPlus() {
        XCTAssertEqual(report(channels: 2, max: 2, port: "HDMI").atmos, .unknown)
        XCTAssertEqual(report(channels: 12, max: 32, port: "HDMI").atmos, .supported)
        XCTAssertEqual(report(channels: 8, max: 4, port: "HDMI").atmos, .supported)
        XCTAssertEqual(report(channels: 12, max: 32, port: "Bluetooth").atmos, .unknown)
    }
}
