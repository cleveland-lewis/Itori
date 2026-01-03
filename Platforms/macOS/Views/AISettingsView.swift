#if os(macOS)
import SwiftUI

struct AISettingsView: View {
    @StateObject private var router = AIRouter.shared
    @StateObject private var modelManager = LocalModelManager.shared
    @State private var showingBYOConfig = false
    @State private var byoType: BYOProviderType = .openai
    @State private var byoAPIKey = ""
    @State private var byoEndpoint = ""
    @State private var testingConnection = false
    @State private var connectionResult: ConnectionResult?
    
    enum ConnectionResult {
        case success
        case failure(String)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerSection
            
            Divider()
            
            modeSelectionSection
            
            Divider()
            
            providerStatusSection
            
            Divider()
            
            if router.mode == .localOnly || router.mode == .auto {
                localModelSection
                Divider()
            }
            
            if router.mode == .byoOnly || router.mode == .auto {
                byoProviderSection
                Divider()
            }
            
            observabilitySection
        }
        .padding()
        .sheet(isPresented: $showingBYOConfig) {
            byoConfigurationSheet
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cpu.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.blue.gradient)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI & Machine Learning")
                        .font(.title.weight(.semibold))
                    
                    Text("Configure AI providers and routing behavior")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Mode Selection
    
    private var modeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Mode")
                .font(.headline)
            
            ForEach(AIMode.allCases) { mode in
                Button {
                    router.mode = mode
                } label: {
                    HStack {
                        Image(systemName: router.mode == mode ? "circle.fill" : "circle")
                            .foregroundStyle(router.mode == mode ? Color.accentColor : .secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mode.displayName)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                            
                            Text(mode.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(router.mode == mode ? .accentQuaternary : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Provider Status
    
    private var providerStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Provider Status")
                .font(.headline)
            
            VStack(spacing: 8) {
                providerRow(
                    name: "Apple Intelligence",
                    icon: "apple.logo",
                    available: checkAppleIntelligence(),
                    description: appleIntelligenceDescription()
                )
                
                #if os(macOS)
                providerRow(
                    name: "Local Model (macOS Standard)",
                    icon: "brain.head.profile",
                    available: modelManager.isModelDownloaded(.macOSStandard),
                    description: "800 MB • Full capabilities"
                )
                #else
                providerRow(
                    name: "Local Model (iOS Lite)",
                    icon: "brain.head.profile",
                    available: modelManager.isModelDownloaded(.iOSLite),
                    description: "150 MB • Core tasks"
                )
                #endif
                
                providerRow(
                    name: "BYO Provider",
                    icon: "network",
                    available: checkBYOProvider(),
                    description: byoProviderDescription()
                )
            }
        }
    }
    
    private func providerRow(name: String, icon: String, available: Bool, description: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(available ? .green : .secondary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body.weight(.medium))
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(available ? .green : .secondary)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Local Model Management
    
    private var localModelSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Local Model")
                .font(.headline)
            
            #if os(macOS)
            let modelType = LocalModelType.macOSStandard
            #else
            let modelType = LocalModelType.iOSLite
            #endif
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(modelType.displayName)
                            .font(.body.weight(.medium))
                        
                        Text("Size: \(modelType.estimatedSize)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if modelManager.isDownloading(modelType) {
                        ProgressView(value: modelManager.downloadProgress(modelType))
                            .frame(width: 100)
                    } else if modelManager.isModelDownloaded(modelType) {
                        Button("Delete") {
                            Task {
                                try? modelManager.deleteModel(modelType)
                            }
                        }
                        .foregroundStyle(.red)
                    } else {
                        Button("Download") {
                            Task {
                                do {
                                    try await modelManager.downloadModel(modelType)
                                } catch {
                                    print("Download failed: \(error)")
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                if modelManager.isModelDownloaded(modelType) {
                    Text("✓ Model ready for offline use")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text("Download required for local-only mode")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.secondaryBackground)
            )
        }
    }
    
    // MARK: - BYO Provider
    
    private var byoProviderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Bring Your Own Provider")
                    .font(.headline)
                
                Spacer()
                
                Button("Configure") {
                    showingBYOConfig = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            if checkBYOProvider() {
                VStack(alignment: .leading, spacing: 8) {
                    Text("✓ BYO provider configured")
                        .font(.caption)
                        .foregroundStyle(.green)
                    
                    Button("Remove Configuration") {
                        AIRouter.shared.removeBYOProvider()
                    }
                    .foregroundStyle(.red)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.secondaryBackground)
                )
            } else {
                Text("Configure your own AI provider (OpenAI, Anthropic, or custom API)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var byoConfigurationSheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Configure BYO Provider")
                .font(.title2.weight(.semibold))
            
            Picker("Provider Type", selection: $byoType) {
                ForEach(BYOProviderType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            SecureField("API Key", text: $byoAPIKey)
                .textFieldStyle(.roundedBorder)
            
            TextField("Endpoint URL (optional)", text: $byoEndpoint)
                .textFieldStyle(.roundedBorder)
            
            if let result = connectionResult {
                HStack {
                    Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(result.isSuccess ? .green : .red)
                    
                    Text(result.message)
                        .font(.caption)
                }
            }
            
            HStack {
                Button("Cancel") {
                    showingBYOConfig = false
                    connectionResult = nil
                }
                
                Spacer()
                
                Button("Test Connection") {
                    testBYOConnection()
                }
                .disabled(byoAPIKey.isEmpty || testingConnection)
                
                Button("Save") {
                    saveBYOProvider()
                }
                .buttonStyle(.borderedProminent)
                .disabled(byoAPIKey.isEmpty)
            }
        }
        .padding()
        .frame(width: 500)
    }
    
    // MARK: - Observability
    
    private var observabilitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Observability")
                    .font(.headline)
                
                Spacer()
                
                Button("Clear Logs") {
                    router.clearRoutingLog()
                }
            }
            
            let logs = router.getRoutingLog().suffix(5)
            
            if logs.isEmpty {
                Text("No recent AI requests")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent Requests")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    ForEach(Array(logs), id: \.timestamp) { event in
                        HStack {
                            Image(systemName: event.success ? "checkmark.circle" : "xmark.circle")
                                .foregroundStyle(event.success ? .green : .red)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.provider)
                                    .font(.caption.weight(.medium))
                                
                                Text("\(event.task.displayName) • \(event.latencyMs)ms")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.secondaryBackground)
                )
            }
        }
    }
    
    // MARK: - Helpers
    
    private func checkAppleIntelligence() -> Bool {
        let availability = AppleIntelligenceProvider.availability()
        return availability.available
    }
    
    private func appleIntelligenceDescription() -> String {
        let availability = AppleIntelligenceProvider.availability()
        return availability.available ? "On-device processing" : availability.reason
    }
    
    private func checkBYOProvider() -> Bool {
        Task {
            let providers = await router.getAvailableProviders()
            return providers["byo"] ?? false
        }
        return false
    }
    
    private func byoProviderDescription() -> String {
        checkBYOProvider() ? "Configured and ready" : "Not configured"
    }
    
    private func testBYOConnection() {
        testingConnection = true
        connectionResult = nil
        
        Task {
            let provider = BYOProvider(
                type: byoType,
                apiKey: byoAPIKey,
                endpoint: byoEndpoint.isEmpty ? nil : byoEndpoint
            )
            
            let available = await provider.isAvailable()
            
            await MainActor.run {
                connectionResult = available ? .success : .failure("Connection failed")
                testingConnection = false
            }
        }
    }
    
    private func saveBYOProvider() {
        let provider = BYOProvider(
            type: byoType,
            apiKey: byoAPIKey,
            endpoint: byoEndpoint.isEmpty ? nil : byoEndpoint
        )
        
        router.registerBYOProvider(provider)
        showingBYOConfig = false
        connectionResult = nil
    }
}

extension AISettingsView.ConnectionResult {
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    var message: String {
        switch self {
        case .success:
            return "Connection successful"
        case .failure(let error):
            return error
        }
    }
}

#if !DISABLE_PREVIEWS
#Preview {
    AISettingsView()
        .frame(width: 700, height: 800)
}
#endif

#endif
