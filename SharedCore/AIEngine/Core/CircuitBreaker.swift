import Foundation

/// Circuit breaker pattern implementation for provider resilience
/// Prevents cascading failures by temporarily disabling failing providers
class CircuitBreaker {
    enum State {
        case closed       // Normal operation
        case open         // Provider disabled due to failures
        case halfOpen     // Testing if provider has recovered
    }
    
    private let failureThreshold: Int
    private let cooldownInterval: TimeInterval
    private let testRequestInterval: TimeInterval
    
    private var state: State = .closed
    private var consecutiveFailures = 0
    private var lastFailureTime: Date?
    private var lastTestTime: Date?
    private let lock = NSLock()
    
    init(
        failureThreshold: Int = 3,
        cooldownInterval: TimeInterval = 30,
        testRequestInterval: TimeInterval = 10
    ) {
        self.failureThreshold = failureThreshold
        self.cooldownInterval = cooldownInterval
        self.testRequestInterval = testRequestInterval
    }
    
    // MARK: - State Management
    
    func canAttempt() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        switch state {
        case .closed:
            return true
            
        case .open:
            // Check if cooldown has passed
            guard let lastFailure = lastFailureTime else {
                state = .closed
                return true
            }
            
            if Date().timeIntervalSince(lastFailure) >= cooldownInterval {
                state = .halfOpen
                lastTestTime = Date()
                return true
            }
            return false
            
        case .halfOpen:
            // Allow test requests at intervals
            guard let lastTest = lastTestTime else {
                return true
            }
            
            if Date().timeIntervalSince(lastTest) >= testRequestInterval {
                lastTestTime = Date()
                return true
            }
            return false
        }
    }
    
    func recordSuccess() {
        lock.lock()
        defer { lock.unlock() }
        
        consecutiveFailures = 0
        
        if state == .halfOpen {
            state = .closed
        }
    }
    
    func recordFailure() {
        lock.lock()
        defer { lock.unlock() }
        
        consecutiveFailures += 1
        lastFailureTime = Date()
        
        if consecutiveFailures >= failureThreshold {
            state = .open
        }
    }
    
    func getCurrentState() -> State {
        lock.lock()
        defer { lock.unlock() }
        return state
    }
    
    func reset() {
        lock.lock()
        defer { lock.unlock() }
        
        state = .closed
        consecutiveFailures = 0
        lastFailureTime = nil
        lastTestTime = nil
    }
}

/// Time budget enforcement for ports
/// Ensures AI operations don't block UI with excessive latency
struct TimeBudget {
    let budget: TimeInterval
    let portName: String
    
    /// Standard budgets for different operation types
    static let estimate: TimeInterval = 0.2      // 200ms for duration estimates
    static let parse: TimeInterval = 0.8         // 800ms for document parsing
    static let schedule: TimeInterval = 0.3      // 300ms for schedule placement
    static let decompose: TimeInterval = 0.5     // 500ms for task decomposition
    static let forecast: TimeInterval = 0.4      // 400ms for workload forecast
    
    func execute<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        let start = Date()
        
        return try await withThrowingTaskGroup(of: T.self) { group in
            // Start the operation
            group.addTask {
                try await operation()
            }
            
            // Start timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(budget * 1_000_000_000))
                throw TimeBudgetError.timeout(
                    portName: portName,
                    budget: budget,
                    elapsed: Date().timeIntervalSince(start)
                )
            }
            
            // Return first result (either success or timeout)
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

enum TimeBudgetError: LocalizedError {
    case timeout(portName: String, budget: TimeInterval, elapsed: TimeInterval)
    
    var errorDescription: String? {
        switch self {
        case .timeout(let portName, let budget, let elapsed):
            return "Time budget exceeded for \(portName): \(Int(elapsed * 1000))ms (budget: \(Int(budget * 1000))ms)"
        }
    }
}

/// Provider reliability coordinator
/// Manages circuit breakers and time budgets for all providers
class ProviderReliability {
    private var circuitBreakers: [String: CircuitBreaker] = [:]
    private let lock = NSLock()
    
    func getCircuitBreaker(for providerName: String) -> CircuitBreaker {
        lock.lock()
        defer { lock.unlock() }
        
        if let breaker = circuitBreakers[providerName] {
            return breaker
        }
        
        let breaker = CircuitBreaker()
        circuitBreakers[providerName] = breaker
        return breaker
    }
    
    func canUseProvider(_ providerName: String) -> Bool {
        getCircuitBreaker(for: providerName).canAttempt()
    }
    
    func recordProviderSuccess(_ providerName: String) {
        getCircuitBreaker(for: providerName).recordSuccess()
    }
    
    func recordProviderFailure(_ providerName: String) {
        getCircuitBreaker(for: providerName).recordFailure()
    }
    
    func resetProvider(_ providerName: String) {
        getCircuitBreaker(for: providerName).reset()
    }
    
    func getProviderState(_ providerName: String) -> CircuitBreaker.State {
        getCircuitBreaker(for: providerName).getCurrentState()
    }
    
    func getAllProviderStates() -> [String: CircuitBreaker.State] {
        lock.lock()
        defer { lock.unlock() }
        
        var states: [String: CircuitBreaker.State] = [:]
        for (name, breaker) in circuitBreakers {
            states[name] = breaker.getCurrentState()
        }
        return states
    }
}
