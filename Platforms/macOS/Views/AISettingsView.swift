#if os(macOS)
    import SwiftUI

    struct AISettingsView: View {
        @EnvironmentObject var settings: AppSettingsModel
        @StateObject private var router = AIRouter.shared
        @StateObject private var modelManager = LocalModelManager.shared
        @State private var showingBYOConfig = false
        @State private var byoType: BYOProviderType = .openai
        @State private var byoAPIKey = ""
        @State private var byoEndpoint = ""
        @State private var testingConnection = false
        @State private var connectionResult: ConnectionResult?
        @State private var showingDisableAlert = false

        enum ConnectionResult {
            case success
            case failure(String)
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 24) {
                headerSection

                Divider()

                llmEnabledSection

                if settings.enableLLMAssistance {
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
            }
            .padding()
            .sheet(isPresented: $showingBYOConfig) {
                byoConfigurationSheet
            }
            .onAppear {
                loadBYOConfiguration()
            }
            .alert(
                NSLocalizedString(
                    "settings.llm.disable.alert.title",
                    value: "Disable LLM Assistance?",
                    comment: "Alert title when disabling LLM"
                ),
                isPresented: $showingDisableAlert
            ) {
                Button(
                    NSLocalizedString("settings.llm.disable.alert.cancel", value: "Cancel", comment: "Cancel button"),
                    role: .cancel
                ) {}
                Button(
                    NSLocalizedString(
                        "settings.llm.disable.alert.confirm",
                        value: "Disable",
                        comment: "Confirm disable button"
                    ),
                    role: .destructive
                ) {
                    settings.enableLLMAssistance = false
                    AIEngine.shared.resetProviderState()
                }
            } message: {
                Text(NSLocalizedString(
                    "settings.llm.disable.alert.message",
                    value: "All LLM features will be disabled. Planning and parsing will use deterministic algorithms only.",
                    comment: "Alert message explaining LLM disable"
                ))
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
                        Text(NSLocalizedString(
                            "settings.llm.header.title",
                            value: "LLM Configuration",
                            comment: "LLM settings page title"
                        ))
                        .font(.title.weight(.semibold))

                        Text(NSLocalizedString(
                            "settings.llm.header.subtitle",
                            value: "Configure LLM providers and routing behavior",
                            comment: "LLM settings page subtitle"
                        ))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }

        // MARK: - LLM Enable/Disable

        private var llmEnabledSection: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text(NSLocalizedString(
                    "settings.llm.assistance.title",
                    value: "LLM Assistance",
                    comment: "LLM assistance section title"
                ))
                .font(.headline)

                Toggle(
                    NSLocalizedString(
                        "settings.llm.assistance.toggle",
                        value: "Enable LLM Assistance",
                        comment: "Toggle to enable LLM assistance"
                    ),
                    isOn: Binding(
                        get: { settings.enableLLMAssistance },
                        set: { newValue in
                            if !newValue {
                                showingDisableAlert = true
                            } else {
                                settings.enableLLMAssistance = newValue
                                AIEngine.shared.resetProviderState()
                                LOG_SETTINGS(.info, "LLMSettings", "LLM features enabled")
                            }
                        }
                    )
                )
                .toggleStyle(.switch)

                if settings.enableLLMAssistance {
                    Text(NSLocalizedString(
                        "settings.llm.assistance.enabled.description",
                        value: "LLM assistance is enabled. Itori can use Apple Intelligence, local models, or custom providers to improve parsing accuracy and add redundancy checks to generated plans.",
                        comment: "Description when LLM is enabled"
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } else {
                    Text(NSLocalizedString(
                        "settings.llm.assistance.disabled.description",
                        value: "All LLM features are disabled. Planning and parsing use deterministic algorithms only.",
                        comment: "Description when LLM is disabled"
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }

        // MARK: - Mode Selection

        private var modeSelectionSection: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text(NSLocalizedString("settings.llm.mode.title", value: "Mode", comment: "AI mode section title"))
                    .font(.headline)

                ForEach(AIMode.allCases) { mode in
                    Button {
                        router.mode = mode
                    } label: {
                        HStack {
                            Image(systemName: router.mode == mode ? "circle.fill" : "circle")
                                .foregroundStyle(router.mode == mode ? Color.accentColor : .secondary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(modeTitle(for: mode))
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

        private func modeTitle(for mode: AIMode) -> String {
            switch mode {
            case .byoOnly:
                NSLocalizedString(
                    "settings.llm.mode.external",
                    value: "External Provider",
                    comment: "LLM mode label for external provider"
                )
            default:
                mode.displayName
            }
        }

        // MARK: - Provider Status

        private var providerStatusSection: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text(NSLocalizedString(
                    "settings.llm.provider.status.title",
                    value: "Provider Status",
                    comment: "Provider status section title"
                ))
                .font(.headline)

                VStack(spacing: 8) {
                    providerRow(
                        name: NSLocalizedString(
                            "settings.llm.provider.apple",
                            value: "Apple Intelligence",
                            comment: "Apple Intelligence provider name"
                        ),
                        icon: "apple.logo",
                        available: checkAppleIntelligence(),
                        description: appleIntelligenceDescription()
                    )

                    #if os(macOS)
                        providerRow(
                            name: NSLocalizedString(
                                "settings.llm.provider.local.macos",
                                value: "Local Model (macOS Standard)",
                                comment: "Local macOS model provider name"
                            ),
                            icon: "brain.head.profile",
                            available: modelManager.isModelDownloaded(.macOSStandard),
                            description: NSLocalizedString(
                                "settings.llm.provider.local.macos.description",
                                value: "800 MB • Full capabilities",
                                comment: "Local macOS model description"
                            )
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
                        name: "External Provider",
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
                Text(NSLocalizedString(
                    "settings.llm.model.title",
                    value: "Local Model",
                    comment: "Local model section title"
                ))
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

                            Text(String(
                                format: NSLocalizedString(
                                    "settings.llm.model.size",
                                    value: "Size: %@",
                                    comment: "Model size display"
                                ),
                                modelType.estimatedSize
                            ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if modelManager.isDownloading(modelType) {
                            ProgressView(value: modelManager.downloadProgress(modelType))
                                .frame(width: 100)
                        } else if modelManager.isModelDownloaded(modelType) {
                            Button(NSLocalizedString(
                                "settings.llm.model.button.delete",
                                value: "Delete",
                                comment: "Delete model button"
                            )) {
                                Task {
                                    try? modelManager.deleteModel(modelType)
                                }
                            }
                            .buttonStyle(.itoriLiquidProminent)
                        } else {
                            Button(NSLocalizedString(
                                "settings.llm.model.button.download",
                                value: "Download",
                                comment: "Download model button"
                            )) {
                                Task {
                                    do {
                                        try await modelManager.downloadModel(modelType)
                                    } catch {
                                        print("Download failed: \(error)")
                                    }
                                }
                            }
                            .buttonStyle(.itoriLiquidProminent)
                        }
                    }

                    if modelManager.isModelDownloaded(modelType) {
                        Text(NSLocalizedString(
                            "settings.llm.model.ready",
                            value: "✓ Model ready for offline use",
                            comment: "Model ready status"
                        ))
                        .font(.caption)
                        .foregroundStyle(.green)
                    } else {
                        Text(NSLocalizedString(
                            "settings.llm.model.download.required",
                            value: "Download required for local-only mode",
                            comment: "Download required message"
                        ))
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
                    Text(NSLocalizedString(
                        "settings.llm.byo.title",
                        value: "External Provider",
                        comment: "BYO provider section title"
                    ))
                    .font(.headline)

                    Spacer()

                    Button(NSLocalizedString(
                        "settings.llm.byo.configure.button.short",
                        value: "Configure",
                        comment: "Configure BYO button"
                    )) {
                        showingBYOConfig = true
                    }
                    .buttonStyle(.itariLiquid)
                }

                if checkBYOProvider() {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString(
                            "settings.llm.byo.configured",
                            value: "✓ External provider configured",
                            comment: "BYO configured status"
                        ))
                        .font(.caption)
                        .foregroundStyle(.green)

                        Button(NSLocalizedString(
                            "settings.llm.byo.remove.button",
                            value: "Remove Configuration",
                            comment: "Remove BYO configuration button"
                        )) {
                            AIRouter.shared.removeBYOProvider()
                            // Clear persisted configuration
                            UserDefaults.standard.removeObject(forKey: "byoProviderType")
                            UserDefaults.standard.removeObject(forKey: "byoProviderAPIKey")
                            UserDefaults.standard.removeObject(forKey: "byoProviderEndpoint")
                            byoAPIKey = ""
                            byoEndpoint = ""
                        }
                        .buttonStyle(.itoriLiquidProminent)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.secondaryBackground)
                    )
                } else {
                    Text(NSLocalizedString(
                        "settings.llm.byo.description",
                        value: "Configure an external AI provider (OpenAI, Anthropic, or custom API)",
                        comment: "BYO provider description"
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }

        private var byoConfigurationSheet: some View {
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString(
                    "settings.llm.byo.configure.title",
                    value: "Configure External Provider",
                    comment: "BYO configuration sheet title"
                ))
                .font(.title2.weight(.semibold))

                Picker(
                    NSLocalizedString(
                        "settings.llm.byo.provider.type",
                        value: "Provider Type",
                        comment: "Provider type picker label"
                    ),
                    selection: $byoType
                ) {
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
                    Button(NSLocalizedString("Cancel", value: "Cancel", comment: "")) {
                        showingBYOConfig = false
                        connectionResult = nil
                    }

                    Spacer()

                    Button(NSLocalizedString("Test Connection", value: "Test Connection", comment: "")) {
                        testBYOConnection()
                    }
                    .disabled(byoAPIKey.isEmpty || testingConnection)

                    Button(NSLocalizedString("Save", value: "Save", comment: "")) {
                        saveBYOProvider()
                    }
                    .buttonStyle(.itoriLiquidProminent)
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
                    Text(NSLocalizedString(
                        "settings.llm.observability.title",
                        value: "Observability",
                        comment: "Observability section title"
                    ))
                    .font(.headline)

                    Spacer()

                    Button(NSLocalizedString(
                        "settings.llm.observability.clear.button",
                        value: "Clear Logs",
                        comment: "Clear logs button"
                    )) {
                        router.clearRoutingLog()
                    }
                }

                let logs = router.getRoutingLog().suffix(5)

                if logs.isEmpty {
                    Text(NSLocalizedString(
                        "settings.llm.observability.no.requests",
                        value: "No recent AI requests",
                        comment: "No recent requests message"
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString(
                            "settings.llm.observability.recent.title",
                            value: "Recent Requests",
                            comment: "Recent requests title"
                        ))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                        ForEach(Array(logs), id: \.timestamp) { event in
                            HStack {
                                Image(systemName: event.success ? "checkmark.circle" : "xmark.circle")
                                    .foregroundStyle(event.success ? .green : .red)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.provider)
                                        .font(.caption.weight(.medium))

                                    Text(verbatim: "\(event.task.displayName) • \(event.latencyMs)ms")
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

            // Persist configuration
            UserDefaults.standard.set(byoType.rawValue, forKey: "byoProviderType")
            UserDefaults.standard.set(byoAPIKey, forKey: "byoProviderAPIKey")
            UserDefaults.standard.set(byoEndpoint, forKey: "byoProviderEndpoint")

            showingBYOConfig = false
            connectionResult = nil
        }

        private func loadBYOConfiguration() {
            // Load saved BYO configuration
            if let typeRaw = UserDefaults.standard.string(forKey: "byoProviderType"),
               let type = BYOProviderType(rawValue: typeRaw)
            {
                byoType = type
            }

            if let apiKey = UserDefaults.standard.string(forKey: "byoProviderAPIKey"), !apiKey.isEmpty {
                byoAPIKey = apiKey
            }

            if let endpoint = UserDefaults.standard.string(forKey: "byoProviderEndpoint") {
                byoEndpoint = endpoint
            }

            // Register provider if configured
            if !byoAPIKey.isEmpty {
                let provider = BYOProvider(
                    type: byoType,
                    apiKey: byoAPIKey,
                    endpoint: byoEndpoint.isEmpty ? nil : byoEndpoint
                )
                router.registerBYOProvider(provider)
            }
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
                "Connection successful"
            case let .failure(error):
                error
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
