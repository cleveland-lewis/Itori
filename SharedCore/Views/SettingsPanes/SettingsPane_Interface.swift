import SwiftUI

struct SettingsPane_Interface: View {
    @EnvironmentObject private var settings: AppSettingsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            GroupBox {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                        HStack {
                            Text(NSLocalizedString("settings.light.glass.strength", value: "Light glass strength", comment: "Light glass strength"))
                            Spacer()
                            Text(verbatim: "\(Int(settings.glassStrength.light * 100))%")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: Binding(
                            get: { settings.glassStrength.light },
                            set: { newVal in settings.glassStrength = GlassStrength(light: newVal, dark: settings.glassStrength.dark); settings.save() }
                        ), in: 0.05...0.5)
                    }

                    VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                        HStack {
                            Text(NSLocalizedString("settings.dark.glass.strength", value: "Dark glass strength", comment: "Dark glass strength"))
                            Spacer()
                            Text(verbatim: "\(Int(settings.glassStrength.dark * 100))%")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: Binding(
                            get: { settings.glassStrength.dark },
                            set: { newVal in settings.glassStrength = GlassStrength(light: settings.glassStrength.light, dark: newVal); settings.save() }
                        ), in: 0.05...0.5)
                    }
                }
            } label: {
                Label(NSLocalizedString("settings.label.glass", value: "Glass", comment: "Glass"), systemImage: "circle.hexagongrid")
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Card radius", selection: $settings.cardRadius) {
                        ForEach(CardRadius.allCases) { radius in
                            Text(radius.label).tag(radius)
                        }
                    }
                    #if os(macOS)
                    .pickerStyle(.radioGroup)
                    #endif

                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("settings.animation.softness", value: "Animation softness", comment: "Animation softness"))
                        Slider(value: Binding(get: { settings.animationSoftness }, set: { newVal in settings.animationSoftness = newVal; settings.save() }), in: 0.15...1)
                        Text(NSLocalizedString("settings.higher.values.make.transitions.feel.gentler", value: "Higher values make transitions feel gentler.", comment: "Higher values make transitions feel gentler."))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } label: {
                Label(NSLocalizedString("settings.label.geometry.motion", value: "Geometry & Motion", comment: "Geometry & Motion"), systemImage: "sparkles")
            }

            Spacer()

            GroupBox {
                HStack {
                    Text(NSLocalizedString("settings.clock.format", value: "Clock format", comment: "Clock format"))
                    Spacer()
                    Picker("Clock format", selection: Binding(get: { settings.use24HourTime }, set: { settings.use24HourTime = $0 })) {
                        Text(NSLocalizedString("settings.12hour", value: "12-hour", comment: "12-hour")).tag(false)
                        Text(NSLocalizedString("settings.24hour", value: "24-hour", comment: "24-hour")).tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                .padding(.vertical, 6)
            } label: {
                Label(NSLocalizedString("settings.label.clock", value: "Clock", comment: "Clock"), systemImage: "clock")
            }

            GroupBox {
                Toggle(isOn: Binding(
                    get: { settings.hideGPAOnDashboard },
                    set: { newValue in
                        settings.hideGPAOnDashboard = newValue
                        settings.save()
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("settings.dashboard.hide_gpa", value: "Hide GPA on dashboard", comment: "Hide GPA toggle label"))
                        Text(NSLocalizedString("settings.dashboard.hide_gpa.detail", value: "Remove GPA labels from the dashboard grade charts.", comment: "Hide GPA detail"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            } label: {
                Label(NSLocalizedString("settings.dashboard.label", value: "Dashboard", comment: "Label for dashboard-related settings"), systemImage: "chart.line.uptrend.xyaxis")
            }

            Divider().padding(.vertical)

            HStack(spacing: 20) {
                #if os(macOS)
                tabEditor
                Divider()
                #endif
                quickActionsEditor
            }
            .padding(.top)
        }
        .frame(maxWidth: 640)
    }
}
