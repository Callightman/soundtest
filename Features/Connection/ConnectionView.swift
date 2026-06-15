import SwiftUI
import SoundTestCore

struct ConnectionView: View {
    @StateObject private var model = ConnectionViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                statusCard
                if let r = model.report { detailGrid(r) }
            }
            .padding(60)
        }
        .onAppear { model.refresh() }
    }

    private var statusCard: some View {
        VStack(spacing: 16) {
            Image(systemName: statusSymbol)
                .font(.system(size: 64))
                .foregroundStyle(statusColor)
            Text(statusTitle).font(.title2.bold())
            Button("Run Audio Diagnostics") { model.refresh() }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    }

    private func detailGrid(_ r: CapabilityReport) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 24) {
            infoTile("Output", "\(r.portName) — \(r.portType)")
            infoTile("Channels", "\(r.outputChannels) / max \(r.maxOutputChannels)")
            infoTile("Sample Rate", String(format: "%.0f Hz", r.sampleRate))
            infoTile("Stereo", r.stereo.rawValue)
            infoTile("5.1 Surround", r.surround51.rawValue)
            infoTile("7.1 Surround", r.surround71.rawValue)
            infoTile("Dolby Atmos", r.atmos.rawValue)
            infoTile("DTS", "Not output by Apple TV")
        }
    }

    private func infoTile(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline).foregroundStyle(.secondary)
            Text(value).font(.title3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(28)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var statusSymbol: String {
        switch model.report?.atmos {
        case .supported: return "checkmark.circle.fill"
        case .unsupported: return "xmark.circle.fill"
        default: return "questionmark.circle.fill"
        }
    }
    private var statusColor: Color {
        switch model.report?.atmos {
        case .supported: return .green
        case .unsupported: return .red
        default: return .yellow
        }
    }
    private var statusTitle: String {
        switch model.report?.atmos {
        case .supported: return "Dolby Atmos supported"
        case .unsupported: return "Dolby Atmos not available"
        default: return "Unknown status"
        }
    }
}
