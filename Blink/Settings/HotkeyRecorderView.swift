import AppKit
import SwiftUI

/// Click to record a global capture shortcut; Esc cancels recording.
struct HotkeyRecorderView: View {
    @Binding var chord: HotkeyChord
    var registrationFailed: Bool

    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Button {
                    beginRecording()
                } label: {
                    Text(isRecording ? "Type shortcut…" : chord.displayLabel)
                        .font(.system(size: 13, weight: .medium).monospaced())
                        .frame(minWidth: 88, alignment: .center)
                }
                .buttonStyle(.bordered)
                .tint(isRecording ? Brand.mint : nil)
                .help(isRecording ? "Press a key with modifiers. Esc cancels." : "Click to record a new shortcut")

                if chord != .captureDefault {
                    Button("Reset") {
                        endRecording(commit: nil)
                        chord = .captureDefault
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Brand.fog)
                    .font(.system(size: 12))
                }
            }

            if isRecording {
                Text("Press keys now · Esc cancels")
                    .font(.system(size: 11))
                    .foregroundStyle(Brand.fog)
            } else if registrationFailed {
                Text("Couldn’t register that shortcut — it may be in use. Try another.")
                    .font(.system(size: 11))
                    .foregroundStyle(Brand.alert)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onDisappear {
            endRecording(commit: nil)
        }
    }

    private func beginRecording() {
        endRecording(commit: nil)
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Escape
                DispatchQueue.main.async {
                    endRecording(commit: nil)
                }
                return nil
            }
            if let next = HotkeyChord(nsEvent: event) {
                DispatchQueue.main.async {
                    endRecording(commit: next)
                }
                return nil
            }
            return nil
        }
    }

    private func endRecording(commit: HotkeyChord?) {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        isRecording = false
        if let commit {
            chord = commit
        }
    }
}
