import SwiftUI

struct BatchReviewSheet: View {
    let state: BatchReviewState
    let onApprove: () async -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)
                
                Text("Large Import Detected")
                    .font(.title2.weight(.bold))
                
                Text("Found \(state.totalItems) items in \(state.fileName)")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)
            
            // Content breakdown
            VStack(alignment: .leading, spacing: 12) {
                if !state.results.assignments.isEmpty {
                    HStack {
                        Image(systemName: "checklist")
                            .foregroundStyle(.blue)
                        Text("\(state.results.assignments.count) Assignments")
                            .font(.body.weight(.medium))
                        Spacer()
                    }
                }
                
                if !state.results.events.isEmpty {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(.purple)
                        Text("\(state.results.events.count) Tests/Exams")
                            .font(.body.weight(.medium))
                        Spacer()
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.secondary.opacity(0.1))
            )
            
            // Warning message
            Text("This is a large import. Would you like to add all these items to your schedule?")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            // Actions
            HStack(spacing: 12) {
                Button(action: {
                    onCancel()
                    dismiss()
                }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .disabled(isProcessing)
                
                Button(action: {
                    isProcessing = true
                    Task {
                        await onApprove()
                        dismiss()
                    }
                }) {
                    if isProcessing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Add All Items")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing)
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 32)
        .frame(width: 480, height: 520)
    }
}
