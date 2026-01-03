#if os(iOS)
import SwiftUI

struct IOSAISettingsView: View {
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
        List {
            headerSection
            
            modeSelectionSection
            
            providerStatusSection
            
            if router.mode == .localOnly || router.mode == .auto {
                localModelSection
            }
            
            if router.mode == .byoOnly || router.mode == .auto {
                byoProviderSection
            }
            
            observabilitySection
        }
        .navigationTitle("AI & ML")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingBYOConfig) {
            NavigationStack {
                byoConfigurationSheet
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "cpu.fill")
                        .font(.title)
                        .foregroundStyle(.blue.gradient)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI & Machine Learning")
                            .font(.headline)
                        
                        Text("Configure AI providers and routing behavior")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Mode Selection
    
    private var modeSelectionSection: some View {
        Section {
            ForEach(AIMode.allCases) { mode in
                Button {
                    router.mode = mode
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mode.displayName)
                                .font(.body)
                                .foregroundStyle(.primary)
                            
                            Text(mode.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if router.mode == mode {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.accentColor)
                                .font(.body.weight(.semibold))
                        }
                    }
                }
            }
        } header: {
            Text("AI Mode")
        }
    }
    
    // MARK: - Provider Status
    
    private var providerStatusSection: some View {
        Section {
            providerStatusRow(
                name: "Apple Intelligence",
                icon: "apple.logo",
                isAvailable: AppleIntelligenceProvider.availability().available,
                statusText: AppleIntelligenceProvider.availability().reason
            )
            
            providerStatusRow(
                name: "Local Model (iOS Lite)",
                icon: "iphone",
                isAvailable: modelManager.isModelDownloaded(.iOSLite),
                statusText: modelManager.isModelDownloaded(.iOSLite) ? "Downloaded" : "Not downloaded"
            )
            
            providerStatusRow(
                name: "BYO Provider",
                icon: "network",
                isAvailable: router.hasBYOConfigured,
                statusText: router.hasBYOConfigured ? "Configured" : "Not configured"
            )
        } header: {
            Text("Provider Status")
        }
    }
    
    private func providerStatusRow(name: String, icon: String, isAvailable: Bool, statusText: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(isAvailable ? Color.green : .secondary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.body)
                
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(isAvailable ? Color.green : Color.secondary.opacity(0.3))
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Local Model
    
    private var localModelSection: some View {
        Section {
            if modelManager.isModelDownloaded(.iOSLite) {
                modelStatusCard(type: .iOSLite)
            } else {
                modelDownloadCard(type: .iOSLite)
            }
        } header: {
            Text("Local Model")
        } footer: {
            Text("Lite model optimized for iOS - smaller size, lower battery usage. Supports basic AI tasks offline.")
        }
    }
    
    private func modelStatusCard(type: LocalModelType) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Model Downloaded")
                    .font(.headline)
                Spacer()
            }
            
            if let size = modelManager.getModelSize(type) {
                Text("Size: \(size)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Button(role: .destructive) {
                Task {
                    await modelManager.deleteModel(type)
                }
            } label: {
                Label("Delete Model", systemImage: "trash")
                    .font(.subheadline)
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
    
    private func modelDownloadCard(type: LocalModelType) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.down.circle")
                    .foregroundStyle(.blue)
                Text("Download Required")
                    .font(.headline)
                Spacer()
            }
            
            Text("Model size: ~150 MB")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if modelManager.isDownloading {
                ProgressView(value: modelManager.downloadProgress)
                    .progressViewStyle(.linear)
                Text("\(Int(modelManager.downloadProgress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    Task {
                        await modelManager.downloadModel(type)
                    }
                } label: {
                    Label("Download Model", systemImage: "arrow.down.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - BYO Provider
    
    private var byoProviderSection: some View {
        Section {
            Button {
                showingBYOConfig = true
            } label: {
                HStack {
                    Label("Configure BYO Provider", systemImage: "gearshape")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Bring Your Own Provider")
        } footer: {
            Text("Use your own API key with OpenAI, Anthropic, or custom endpoints.")
        }
    }
    
    // MARK: - Observability
    
    private var observabilitySection: some View {
        Section {
            HStack {
                Text("Current Provider")
                Spacer()
                Text(router.currentProvider ?? "None")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text("Processing")
                Spacer()
                Text(router.isProcessing ? "Yes" : "No")
                    .foregroundStyle(.secondary)
            }
            
            NavigationLink {
                AIDebugView()
            } label: {
                Label("Debug Log", systemImage: "doc.text.magnifyingglass")
            }
        } header: {
            Text("Observability")
        }
    }
    
    // MARK: - BYO Configuration Sheet
    
    private var byoConfigurationSheet: some View {
        Form {
            Section {
                Picker("Provider Type", selection: $byoType) {
                    Text("OpenAI").tag(BYOProviderType.openai)
                    Text("Anthropic").tag(BYOProviderType.anthropic)
                    Text("Custom").tag(BYOProviderType.custom)
                }
                
                SecureField("API Key", text: $byoAPIKey)
                    .textContentType(.password)
                
                if byoType == .custom {
                    TextField("API Endpoint", text: $byoEndpoint)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                }
            } header: {
                Text("Provider Configuration")
            } footer: {
                Text("Your API key is stored securely in the Keychain and never leaves your device except to call your chosen provider.")
            }
            
            Section {
                Button {
                    testConnection()
                } label: {
                    if testingConnection {
                        HStack {
                            ProgressView()
                            Text("Testing Connection...")
                        }
                    } else {
                        Label("Test Connection", systemImage: "network")
                    }
                }
                .disabled(byoAPIKey.isEmpty || testingConnection)
                
                if let result = connectionResult {
                    switch result {
                    case .success:
                        Label("Connection Successful", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    case .failure(let error):
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Connection Failed", systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Configure Provider")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    showingBYOConfig = false
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveBYOConfig()
                    showingBYOConfig = false
                }
                .disabled(byoAPIKey.isEmpty)
            }
        }
    }
    
    // MARK: - Actions
    
    private func testConnection() {
        testingConnection = true
        connectionResult = nil
        
        Task {
            do {
                // Test with a simple prompt
                let _ = try await router.route(
                    prompt: "Test",
                    task: .textCompletion,
                    requireOffline: false
                )
                await MainActor.run {
                    connectionResult = .success
                    testingConnection = false
                }
            } catch {
                await MainActor.run {
                    connectionResult = .failure(error.localizedDescription)
                    testingConnection = false
                }
            }
        }
    }
    
    private func saveBYOConfig() {
        // Save to BYOProvider configuration
        Task {
            await BYOProvider.shared.configure(
                type: byoType,
                apiKey: byoAPIKey,
                endpoint: byoType == .custom ? byoEndpoint : nil
            )
        }
    }
}

// MARK: - Debug View

private struct AIDebugView: View {
    @StateObject private var router = AIRouter.shared
    
    var body: some View {
        List {
            Section("Routing Log") {
                if router.recentEvents.isEmpty {
                    Text("No events yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(router.recentEvents, id: \.timestamp) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(event.provider)
                                    .font(.headline)
                                Spacer()
                                Text("\(event.latencyMs)ms")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack {
                                Text(event.task.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Image(systemName: event.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(event.success ? .green : .red)
                            }
                            
                            if let error = event.errorMessage {
                                Text(error)
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("AI Debug Log")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#endif
