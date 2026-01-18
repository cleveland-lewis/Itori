#if os(macOS)
    import SwiftUI

    struct LLMSettingsView: View {
        @State private var config: LLMBackendConfig
        @State private var isTestingConnection = false
        @State private var connectionStatus: ConnectionStatus = .unknown
        @State private var showingAPIKeyInput = false

        private let onConfigUpdate: (LLMBackendConfig) -> Void

        enum ConnectionStatus {
            case unknown
            case testing
            case connected
            case failed(String)

            var color: Color {
                switch self {
                case .unknown: .gray
                case .testing: .blue
                case .connected: .green
                case .failed: .red
                }
            }

            var icon: String {
                switch self {
                case .unknown: "circle"
                case .testing: "arrow.triangle.2.circlepath"
                case .connected: "checkmark.circle.fill"
                case .failed: "xmark.circle.fill"
                }
            }

            var text: String {
                switch self {
                case .unknown: "Not tested"
                case .testing: "Testing connection..."
                case .connected: "Connected"
                case let .failed(error): "Failed: \(error)"
                }
            }
        }

        init(config: LLMBackendConfig, onConfigUpdate: @escaping (LLMBackendConfig) -> Void) {
            _config = State(initialValue: config)
            self.onConfigUpdate = onConfigUpdate
        }

        var body: some View {
            Form {
                Section("Backend Type") {
                    Picker("LLM Backend", selection: $config.type) {
                        ForEach(LLMBackendType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .onChange(of: config.type) { _, newType in
                        updateConfigForType(newType)
                    }

                    // Connection status
                    HStack {
                        Image(systemName: connectionStatus.icon)
                            .foregroundStyle(connectionStatus.color)

                        Text(connectionStatus.text)
                            .font(.caption)
                            .foregroundStyle(connectionStatus.color)

                        Spacer()

                        Button(NSLocalizedString(
                            "settings.button.test.connection",
                            value: "Test Connection",
                            comment: "Test Connection"
                        )) {
                            testConnection()
                        }
                        .disabled(isTestingConnection)
                    }
                }

                Section("Model Configuration") {
                    TextField("Model Name", text: $config.modelName)
                        .help("The name of the model to use")

                    switch config.type {
                    case .mock:
                        Text(NSLocalizedString(
                            "settings.mock.backend.no.configuration.needed",
                            value: "Mock backend - no configuration needed",
                            comment: "Mock backend - no configuration needed"
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    case .mlx:
                        mlxSettings

                    case .ollama:
                        ollamaSettings

                    case .openaiCompatible:
                        openAISettings
                    }
                }

                Section("Generation Parameters") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(
                            format: NSLocalizedString(
                                "llm.settings.temperature",
                                value: "Temperature: %.2f",
                                comment: "Temperature label"
                            ),
                            config.temperature
                        ))
                        .font(.caption)
                        Slider(value: $config.temperature, in: 0 ... 2, step: 0.1)
                    }
                    .help("Controls randomness: 0 = deterministic, 2 = very random")

                    VStack(alignment: .leading, spacing: 8) {
                        Text(verbatim: "Max Tokens: \(config.maxTokens)")
                            .font(.caption)
                        Slider(value: Binding(
                            get: { Double(config.maxTokens) },
                            set: { config.maxTokens = Int($0) }
                        ), in: 128 ... 4096, step: 128)
                    }
                    .help("Maximum number of tokens to generate")

                    VStack(alignment: .leading, spacing: 8) {
                        Text(verbatim: "Timeout: \(Int(config.timeout))s")
                            .font(.caption)
                        Slider(value: $config.timeout, in: 10 ... 300, step: 10)
                    }
                    .help("Request timeout in seconds")
                }

                Section {
                    HStack {
                        Button(NSLocalizedString(
                            "settings.button.reset.to.defaults",
                            value: "Reset to Defaults",
                            comment: "Reset to Defaults"
                        )) {
                            resetToDefaults()
                        }

                        Spacer()

                        Button(NSLocalizedString(
                            "settings.button.save.configuration",
                            value: "Save Configuration",
                            comment: "Save Configuration"
                        )) {
                            saveConfiguration()
                        }
                        .buttonStyle(.itoriLiquidProminent)
                    }
                }
            }
            .formStyle(.grouped)
            .compactFormSections()
            .scrollContentBackground(.hidden)
            .background(Color(nsColor: .controlBackgroundColor))
            .frame(minWidth: 500, minHeight: 600)
        }

        // MARK: - Backend-Specific Settings

        private var mlxSettings: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString(
                    "settings.mlx.configuration",
                    value: "MLX Configuration",
                    comment: "MLX Configuration"
                ))
                .font(.headline)

                Text(NSLocalizedString(
                    "settings.mlx.models.are.loaded.from",
                    value: "MLX models are loaded from the Hugging Face hub or local cache",
                    comment: "MLX models are loaded from the Hugging Face hub or..."
                ))
                .font(.caption)
                .foregroundStyle(.secondary)

                if let path = config.mlxModelPath {
                    TextField("Model Path (optional)", text: Binding(
                        get: { path },
                        set: { config.mlxModelPath = $0 }
                    ))
                } else {
                    Button(NSLocalizedString(
                        "settings.button.set.custom.model.path",
                        value: "Set Custom Model Path",
                        comment: "Set Custom Model Path"
                    )) {
                        config.mlxModelPath = ""
                    }
                }

                Text(NSLocalizedString(
                    "settings.common.mlx.models",
                    value: "Common MLX models:",
                    comment: "Common MLX models:"
                ))
                .font(.caption.bold())

                ForEach([
                    "mlx-community/Meta-Llama-3-8B-Instruct-4bit",
                    "mlx-community/Mistral-7B-Instruct-v0.3-4bit",
                    "mlx-community/Qwen2.5-7B-Instruct-4bit"
                ], id: \.self) { model in
                    Button(model) {
                        config.modelName = model
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                }
            }
        }

        private var ollamaSettings: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString(
                    "settings.ollama.configuration",
                    value: "Ollama Configuration",
                    comment: "Ollama Configuration"
                ))
                .font(.headline)

                TextField("Ollama Host", text: Binding(
                    get: { config.ollamaHost ?? "http://localhost:11434" },
                    set: { config.ollamaHost = $0 }
                ))
                .help("Ollama server address")

                Text(NSLocalizedString(
                    "settings.common.ollama.models",
                    value: "Common Ollama models:",
                    comment: "Common Ollama models:"
                ))
                .font(.caption.bold())

                ForEach([
                    "llama3.2:3b",
                    "llama3.1:8b",
                    "mistral:7b",
                    "qwen2.5:7b"
                ], id: \.self) { model in
                    Button(model) {
                        config.modelName = model
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                }
            }
        }

        private var openAISettings: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString(
                    "settings.openaicompatible.llm.api.configuration",
                    value: "OpenAI-Compatible LLM API Configuration",
                    comment: "OpenAI-Compatible LLM API Configuration"
                ))
                .font(.headline)

                TextField("API Endpoint", text: Binding(
                    get: { config.apiEndpoint ?? "https://api.openai.com/v1" },
                    set: { config.apiEndpoint = $0 }
                ))
                .help("API endpoint URL")

                SecureField("API Key", text: Binding(
                    get: { config.apiKey ?? "" },
                    set: { config.apiKey = $0 }
                ))
                .help("Your API key")

                Text(NSLocalizedString(
                    "settings.works.with.openai.azure.openai",
                    value: "Works with OpenAI, Azure OpenAI, LM Studio, and other compatible LLM APIs",
                    comment: "Works with OpenAI, Azure OpenAI, LM Studio, and ot..."
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }

        // MARK: - Actions

        private func updateConfigForType(_ type: LLMBackendType) {
            switch type {
            case .mock:
                config = .mockConfig
            case .mlx:
                config = .mlxDefault
            case .ollama:
                config = .ollamaDefault
            case .openaiCompatible:
                config = .openaiCompatible(apiKey: "")
            }
            connectionStatus = .unknown
        }

        private func testConnection() {
            isTestingConnection = true
            connectionStatus = .testing

            Task {
                let backend = LLMBackendFactory.createBackend(config: config)
                let available = await backend.isAvailable

                await MainActor.run {
                    if available {
                        connectionStatus = .connected
                    } else {
                        connectionStatus = .failed("Backend not available")
                    }
                    isTestingConnection = false
                }
            }
        }

        private func resetToDefaults() {
            updateConfigForType(config.type)
        }

        private func saveConfiguration() {
            LLMBackendFactory.saveConfig(config)
            onConfigUpdate(config)
        }
    }

    #if !DISABLE_PREVIEWS
        #Preview {
            LLMSettingsView(config: .mockConfig) { _ in }
        }
    #endif

#endif
