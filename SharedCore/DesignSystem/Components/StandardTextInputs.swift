import SwiftUI

// MARK: - Standard Text Field with Focus Animations

/// Text field with standardized focus and validation transitions
public struct StandardTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let validation: ((String) -> String?)?
    
    @FocusState private var isFocused: Bool
    @State private var validationMessage: String?
    
    public init(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        validation: ((String) -> String?)? = nil
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.validation = validation
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Text Field
            TextField(placeholder, text: $text)
                .textFieldStyle(FocusAnimatedTextFieldStyle(isFocused: isFocused))
                .focused($isFocused)
                .onChange(of: text) { _, newValue in
                    if let validation {
                        withAnimation(DesignSystem.AnimationCurves.defaultCurve) {
                            validationMessage = validation(newValue)
                        }
                    }
                }
            
            // Validation Message
            if let validationMessage {
                Label(validationMessage, systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .validationTransition()
            }
        }
    }
}

// MARK: - Standard Text Editor

/// Text editor with standardized focus and validation transitions
public struct StandardTextEditor: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let minHeight: CGFloat
    
    @FocusState private var isFocused: Bool
    
    public init(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        minHeight: CGFloat = 100
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.minHeight = minHeight
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Text Editor with Placeholder
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(.secondary.opacity(0.5))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                        .transition(DesignSystem.Transitions.placeholder)
                }
                
                TextEditor(text: $text)
                    .focused($isFocused)
                    .frame(minHeight: minHeight)
            }
            .textFieldStyle(FocusAnimatedTextFieldStyle(isFocused: isFocused))
        }
    }
}

// MARK: - Focus Animated Text Field Style

/// Text field style with animated focus ring
public struct FocusAnimatedTextFieldStyle: TextFieldStyle {
    let isFocused: Bool
    
    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? Color.accentColor : Color.clear, lineWidth: 2)
                    .focusAnimation(value: isFocused)
            )
    }
}

// MARK: - Search Bar

/// Standard search bar with animated focus
public struct StandardSearchBar: View {
    @Binding var searchText: String
    let placeholder: String
    let onCommit: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    
    public init(
        searchText: Binding<String>,
        placeholder: String = "Search",
        onCommit: (() -> Void)? = nil
    ) {
        self._searchText = searchText
        self.placeholder = placeholder
        self.onCommit = onCommit
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: $searchText)
                .focused($isFocused)
                .onSubmit {
                    onCommit?()
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    withAnimation(DesignSystem.AnimationCurves.focusCurve) {
                        searchText = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .transition(DesignSystem.Transitions.focusRing)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isFocused ? Color.accentColor : Color.clear, lineWidth: 2)
                .focusAnimation(value: isFocused)
        )
    }
}

// MARK: - Validated Text Field

/// Text field with real-time validation feedback
public struct ValidatedTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let validator: (String) -> ValidationResult
    
    @FocusState private var isFocused: Bool
    @State private var validationResult: ValidationResult = .neutral
    
    public init(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        validator: @escaping (String) -> ValidationResult
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.validator = validator
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Text Field
            HStack {
                TextField(placeholder, text: $text)
                    .focused($isFocused)
                    .onChange(of: text) { _, newValue in
                        withAnimation(DesignSystem.AnimationCurves.focusCurve) {
                            validationResult = validator(newValue)
                        }
                    }
                
                // Validation Icon
                Group {
                    switch validationResult {
                    case .neutral:
                        EmptyView()
                    case .valid:
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .transition(DesignSystem.Transitions.focusRing)
                    case .invalid:
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .transition(DesignSystem.Transitions.focusRing)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(validationStrokeColor, lineWidth: 2)
                    .focusAnimation(value: isFocused)
            )
            
            // Validation Message
            if case .invalid(let message) = validationResult {
                Label(message, systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .validationTransition()
            }
        }
    }
    
    private var validationStrokeColor: Color {
        if isFocused {
            return .accentColor
        }
        
        switch validationResult {
        case .neutral:
            return .clear
        case .valid:
            return .green
        case .invalid:
            return .red
        }
    }
}

// MARK: - Validation Result

public enum ValidationResult: Equatable {
    case neutral
    case valid
    case invalid(message: String)
}

// MARK: - Common Validators

extension ValidationResult {
    public static func email(_ email: String) -> ValidationResult {
        guard !email.isEmpty else { return .neutral }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        return emailPredicate.evaluate(with: email) 
            ? .valid 
            : .invalid(message: "Invalid email format")
    }
    
    public static func minLength(_ text: String, minimum: Int) -> ValidationResult {
        guard !text.isEmpty else { return .neutral }
        
        return text.count >= minimum 
            ? .valid 
            : .invalid(message: "Must be at least \(minimum) characters")
    }
    
    public static func notEmpty(_ text: String) -> ValidationResult {
        text.isEmpty 
            ? .invalid(message: "This field is required") 
            : .valid
    }
}
