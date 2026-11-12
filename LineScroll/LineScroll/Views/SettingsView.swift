import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: ReaderSettings
    @State private var showCredit = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Reading") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Font size")
                            Spacer()
                            Text("\(Int(settings.fontSize)) pt")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $settings.fontSize, in: 16...34, step: 1)
                    }

                    Picker("Appearance", selection: Binding(
                        get: { settings.colorSchemePreference },
                        set: { settings.colorSchemePreference = $0 }
                    )) {
                        ForEach(ColorSchemePreference.allCases) { preference in
                            Text(preference.title).tag(preference)
                        }
                    }
                }

                Section("About") {
                    LabeledContent("App", value: "LineScroll")
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    Button("Project Gutenberg credit & disclaimer") {
                        showCredit = true
                    }
                }

                Section {
                    Text("Scroll unit is a TextKit layout line (word-wrapped at the current width), not a raw file newline. Swipe vertically to snap one line at a time.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showCredit) {
                CreditView()
            }
        }
    }
}
