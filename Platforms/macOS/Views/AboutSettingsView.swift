#if os(macOS)
import SwiftUI

struct AboutSettingsView: View {
    @ScaledMetric private var largeIconSize: CGFloat = 48

    @ScaledMetric private var appIconSize: CGFloat = 72

    @ScaledMetric private var appNameSize: CGFloat = 32

    
    @Environment(\.openURL) private var openURL
    
    private let appVersion: String = {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(version) (\(build))"
        }
        return "1.0.0"
    }()
    
    var body: some View {
        VStack(spacing: 32) {
            // App icon and title
            VStack(spacing: 16) {
                if let appIcon = NSImage(named: "AppIcon") {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 128, height: 128)
                        .cornerRadius(22)
                        .shadow(radius: 4)
                } else {
                    ZStack {
                        Circle()
                            .fill(.blue)
                            .frame(width: 128, height: 128)
                            .shadow(radius: 6)
                        Text(verbatim: "#")
                            .font(.system(size: appIconSize, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                
                VStack(spacing: 4) {
                    Text(NSLocalizedString("about.app.name", value: "Itori", comment: "App name"))
                        .font(.system(size: appNameSize, weight: .semibold))
                    
                    Text(NSLocalizedString("about.app.tagline", value: "Academic Planning & Productivity", comment: "App tagline"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Version info
            VStack(spacing: 8) {
                HStack {
                    Text(NSLocalizedString("about.version", value: "Version", comment: "Version label"))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(appVersion)
                        .fontWeight(.medium)
                }
                
                Divider()
                
                HStack {
                    Text(NSLocalizedString("about.build_date", value: "Build Date", comment: "Build date label"))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(NSLocalizedString("about.build_date_value", value: "January 2026", comment: "Build date value"))
                        .fontWeight(.medium)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            
            // Description
            Text(NSLocalizedString("about.description", value: "Itori helps students manage their academic workload with intelligent scheduling, assignment tracking, flashcard learning, and productivity tools.", comment: "App description"))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            // Links
            VStack(spacing: 12) {
                Button {
                    if let url = URL(string: "https://itori.app") {
                        openURL(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "globe")
                        Text(NSLocalizedString("about.visit_website", value: "Visit Website", comment: "Visit website button"))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button {
                    if let url = URL(string: "mailto:clevelandlewisiii@icloud.com") {
                        openURL(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "envelope")
                        Text(NSLocalizedString("about.contact", value: "Contact", comment: "Contact button"))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            // Copyright
            Text(NSLocalizedString("about.copyright", value: "© 2026 Itori. All rights reserved.", comment: "Copyright notice"))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

#if !DISABLE_PREVIEWS
#Preview {
    AboutSettingsView()
}
#endif
#endif
