import SwiftUI

struct OnboardingView: View {
    var onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Brand.ink.ignoresSafeArea()

            // Subtle atmosphere — soft radial wash, not a flat fill.
            RadialGradient(
                colors: [
                    Color(hex: 0x2A3036),
                    Brand.ink
                ],
                center: .center,
                startRadius: 40,
                endRadius: 420
            )
            .ignoresSafeArea()
            .opacity(0.9)

            VStack(spacing: 28) {
                Spacer(minLength: 40)

                CrosshairMark()
                    .frame(width: 72, height: 72)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 4)

                Text("Blink")
                    .font(.system(size: 42, weight: .semibold, design: .default))
                    .foregroundStyle(Brand.paper)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 4)

                Text("Select any part of your screen. Get the text.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Brand.fog)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 4)

                Spacer(minLength: 24)

                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Brand.ink)
                        .frame(maxWidth: 240)
                        .padding(.vertical, 12)
                        .background(Brand.mint)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 4)
                .padding(.bottom, 48)
            }
            .padding(.horizontal, 32)
        }
        .frame(width: 440, height: 480)
        .onAppear {
            withAnimation(.easeOut(duration: 0.28)) {
                appeared = true
            }
        }
    }
}

struct PermissionsFollowUpView: View {
    var onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Allow capture")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Brand.paper)

            Text("Blink needs Screen Recording to frame your screen. Accessibility is only for Experimental hover OCR.")
                .font(.system(size: 13))
                .foregroundStyle(Brand.fog)
                .fixedSize(horizontal: false, vertical: true)

            permissionRow(
                title: "Screen Recording",
                detail: "Required for ⌘⇧2 capture.",
                status: PermissionGate.screenRecording()
            ) {
                PermissionGate.requestScreenRecording()
                PermissionGate.openSystemSettings(for: .screenRecording)
            }

            permissionRow(
                title: "Accessibility",
                detail: "Optional — Experimental click-to-copy.",
                status: PermissionGate.accessibility()
            ) {
                PermissionGate.requestAccessibility()
                PermissionGate.openSystemSettings(for: .accessibility)
            }

            Spacer()

            Button("Done") {
                onDone()
            }
            .buttonStyle(.plain)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Brand.ink)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Brand.mint)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(28)
        .frame(width: 420, height: 360)
        .background(Brand.ink)
    }

    @ViewBuilder
    private func permissionRow(
        title: String,
        detail: String,
        status: PermissionStatus,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Brand.paper)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Brand.fog)
            }
            Spacer()
            Button(status.isUsable ? "On" : "Enable") {
                action()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(status.isUsable ? Brand.mintDim : Brand.mint)
            .disabled(status.isUsable)
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

/// Mint crosshair mark matching the product icon.
struct CrosshairMark: View {
    var body: some View {
        Canvas { context, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let arm = size.width * 0.38
            let gap = size.width * 0.12
            let box = size.width * 0.18
            var path = Path()
            path.move(to: CGPoint(x: cx, y: cy - arm))
            path.addLine(to: CGPoint(x: cx, y: cy - gap))
            path.move(to: CGPoint(x: cx, y: cy + gap))
            path.addLine(to: CGPoint(x: cx, y: cy + arm))
            path.move(to: CGPoint(x: cx - arm, y: cy))
            path.addLine(to: CGPoint(x: cx - gap, y: cy))
            path.move(to: CGPoint(x: cx + gap, y: cy))
            path.addLine(to: CGPoint(x: cx + arm, y: cy))
            context.stroke(path, with: .color(Brand.mint), lineWidth: 3)

            let square = Path(roundedRect: CGRect(x: cx - box / 2, y: cy - box / 2, width: box, height: box), cornerRadius: 0)
            context.stroke(square, with: .color(Brand.mint), lineWidth: 3)
        }
    }
}
