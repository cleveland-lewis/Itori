//
// LLMCallCounterView.swift
// Dev-Only LLM Call Counter Panel
//
// Shows provider attempt counters to verify toggle OFF => 0 attempts
//

import SwiftUI

#if DEBUG || DEVELOPER_MODE

struct LLMCallCounterView: View {
    @State private var counters: AIHealthMonitor.LLMProviderCounters?
    @State private var isExporting = false
    @State private var exportedJSON = ""
    
    var body: some View {
        Form {
            Section {
                Text("LLM Provider Attempt Tracking")
                    .font(.headline)
                
                Text("This panel shows provider invocation counters to verify that the 'Enable LLM Assistance' toggle enforcement is airtight.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let counters = counters {
                // Session Counters
                Section("Session Statistics") {
                    counterRow(
                        title: "Provider Attempts",
                        value: counters.providerAttemptCountTotal,
                        critical: counters.providerAttemptCountTotal > 0 && !AppSettingsModel.shared.enableLLMAssistance
                    )
                    
                    counterRow(
                        title: "Suppressed by Toggle",
                        value: counters.suppressedByLLMToggleCount,
                        critical: false
                    )
                    
                    counterRow(
                        title: "Fallback-Only Executions",
                        value: counters.fallbackOnlyCount,
                        critical: false
                    )
                    
                    if let lastAttempt = counters.lastAttemptTimestamp {
                        HStack {
                            Text("Last Attempt:")
                            Spacer()
                            Text(lastAttempt, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let lastSuppression = counters.lastSuppressionTimestamp {
                        HStack {
                            Text("Last Suppression:")
                            Spacer()
                            Text(lastSuppression, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let reason = counters.lastSuppressionReason {
                        HStack {
                            Text("Last Reason:")
                            Spacer()
                            Text(reason)
                                .foregroundColor(.secondary)
                                .font(.caption.monospaced())
                        }
                    }
                }
                
                // By Provider Breakdown
                if !counters.providerAttemptCountByProvider.isEmpty {
                    Section("Attempts by Provider") {
                        ForEach(Array(counters.providerAttemptCountByProvider.sorted(by: { $0.value > $1.value })), id: \.key) { provider, count in
                            HStack {
                                Text(provider)
                                    .font(.caption.monospaced())
                                Spacer()
                                Text("\(count)")
                                    .foregroundColor(count > 0 ? .primary : .secondary)
                            }
                        }
                    }
                }
                
                // By Port Breakdown
                if !counters.providerAttemptCountByPort.isEmpty {
                    Section("Attempts by Port") {
                        ForEach(Array(counters.providerAttemptCountByPort.sorted(by: { $0.value > $1.value })), id: \.key) { port, count in
                            HStack {
                                Text(port)
                                    .font(.caption.monospaced())
                                Spacer()
                                Text("\(count)")
                                    .foregroundColor(count > 0 ? .primary : .secondary)
                            }
                        }
                    }
                }
                
                // Enforcement Status
                Section("Toggle Enforcement Status") {
                    HStack {
                        Text("LLM Assistance Enabled:")
                        Spacer()
                        Text(AppSettingsModel.shared.enableLLMAssistance ? "YES" : "NO")
                            .foregroundColor(AppSettingsModel.shared.enableLLMAssistance ? .green : .red)
                            .fontWeight(.bold)
                    }
                    
                    if !AppSettingsModel.shared.enableLLMAssistance {
                        if counters.providerAttemptCountTotal == 0 {
                            Label("✅ Enforcement: PASSING", systemImage: "checkmark.shield.fill")
                                .foregroundColor(.green)
                        } else {
                            Label("❌ Enforcement: FAILING", systemImage: "xmark.shield.fill")
                                .foregroundColor(.red)
                        }
                        
                        Text("Expected: 0 provider attempts when toggle is OFF")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Section {
                    Text("Loading counters...")
                        .foregroundColor(.secondary)
                }
            }
            
            // Actions
            Section("Actions") {
                Button("Refresh Counters") {
                    refreshCounters()
                }
                
                Button("Reset Counters") {
                    resetCounters()
                }
                .foregroundColor(.red)
                
                Button("Export Diagnostics JSON") {
                    exportDiagnostics()
                }
                
                if isExporting {
                    TextEditor(text: .constant(exportedJSON))
                        .frame(height: 200)
                        .font(.caption.monospaced())
                        .border(Color.gray, width: 1)
                }
            }
        }
        .navigationTitle("LLM Call Counter")
        #if os(macOS)
        .frame(minWidth: 600, minHeight: 500)
        #endif
        .onAppear {
            refreshCounters()
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func counterRow(title: String, value: Int, critical: Bool) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value)")
                .fontWeight(.bold)
                .foregroundColor(critical ? .red : (value > 0 ? .primary : .secondary))
        }
    }
    
    // MARK: - Actions
    
    private func refreshCounters() {
        Task {
            counters = await AIEngine.healthMonitor.getLLMCounters()
        }
    }
    
    private func resetCounters() {
        Task {
            await AIEngine.healthMonitor.resetLLMCounters()
            refreshCounters()
        }
    }
    
    private func exportDiagnostics() {
        Task {
            let counters = await AIEngine.healthMonitor.getLLMCounters()
            exportedJSON = counters.exportJSON()
            isExporting = true
        }
    }
}

#if DEBUG
struct LLMCallCounterView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LLMCallCounterView()
        }
    }
}
#endif

#endif
