import SwiftUI

/// Celebration animation for timer completion
/// Feature: UI Enhancements - Completion Celebrations
struct TimerCompletionCelebration: View {
    let onComplete: () -> Void
    
    @State private var isAnimating = false
    @State private var particles: [Particle] = []
    @State private var glowOpacity = 0.0
    @State private var scale = 1.0
    
    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.green.opacity(glowOpacity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .blur(radius: 20)
            
            // Particles
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
            }
            
            // Success icon
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(scale)
        }
        .onAppear {
            startCelebration()
        }
    }
    
    private func startCelebration() {
        // Haptic feedback
        HapticFeedbackManager.shared.celebrationPattern()
        
        // Glow animation
        withAnimation(.easeOut(duration: 0.3)) {
            glowOpacity = 0.6
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            glowOpacity = 0.0
        }
        
        // Scale animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
            scale = 1.2
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.2)) {
            scale = 1.0
        }
        
        // Create particles
        for i in 0..<20 {
            let angle = Double(i) * (360.0 / 20.0) * .pi / 180
            let distance = CGFloat.random(in: 50...120)
            
            let particle = Particle(
                x: cos(angle) * distance,
                y: sin(angle) * distance,
                size: CGFloat.random(in: 4...12),
                color: [Color.green, Color.blue, Color.yellow, Color.orange].randomElement()!,
                opacity: 1.0
            )
            
            particles.append(particle)
            
            // Animate particle
            withAnimation(.easeOut(duration: 0.8).delay(Double(i) * 0.02)) {
                if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                    particles[index].opacity = 0.0
                    particles[index].y -= 30
                }
            }
        }
        
        // Clean up after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onComplete()
        }
    }
    
    private struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var color: Color
        var opacity: Double
    }
}

/// Subtle celebration overlay for timer completion
struct SubtleCelebrationOverlay: View {
    @Binding var isShowing: Bool
    
    @State private var opacity = 0.0
    @State private var scale = 0.8
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .scaleEffect(scale)
                
                Text("Timer Complete!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Great work!")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .opacity(opacity)
        }
        .onAppear {
            // Haptic
            HapticFeedbackManager.shared.celebrationPattern()
            
            // Animations
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                opacity = 1.0
                scale = 1.0
            }
            
            // Auto dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isShowing = false
                }
            }
        }
    }
}

/// Confetti particle system
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    let particleCount: Int
    
    init(particleCount: Int = 50) {
        self.particleCount = particleCount
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(particle: particle)
                }
            }
            .onAppear {
                generateConfetti(in: geometry.size)
            }
        }
    }
    
    private func generateConfetti(in size: CGSize) {
        for _ in 0..<particleCount {
            let particle = ConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                color: [.red, .blue, .green, .yellow, .orange, .purple].randomElement()!,
                rotation: Double.random(in: 0...360),
                size: CGFloat.random(in: 6...12)
            )
            particles.append(particle)
            
            animateParticle(particle, maxHeight: size.height)
        }
    }
    
    private func animateParticle(_ particle: ConfettiParticle, maxHeight: CGFloat) {
        withAnimation(
            .linear(duration: Double.random(in: 2.0...4.0))
            .repeatForever(autoreverses: false)
        ) {
            if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                particles[index].y = maxHeight + 20
                particles[index].rotation += 720
            }
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var rotation: Double
    var size: CGFloat
}

private struct ConfettiPiece: View {
    let particle: ConfettiParticle
    
    var body: some View {
        Rectangle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size * 1.5)
            .rotationEffect(.degrees(particle.rotation))
            .position(x: particle.x, y: particle.y)
    }
}

// MARK: - View Modifiers

extension View {
    /// Add celebration overlay when timer completes
    func celebrateCompletion(isShowing: Binding<Bool>) -> some View {
        self.overlay {
            if isShowing.wrappedValue {
                SubtleCelebrationOverlay(isShowing: isShowing)
                    .transition(.opacity)
            }
        }
    }
    
    /// Add confetti effect
    func confetti(isActive: Bool, particleCount: Int = 50) -> some View {
        self.overlay {
            if isActive {
                ConfettiView(particleCount: particleCount)
                    .allowsHitTesting(false)
            }
        }
    }
}

#if DEBUG
#Preview("Celebration") {
    SubtleCelebrationOverlay(isShowing: .constant(true))
}

#Preview("Confetti") {
    Color.white
        .overlay {
            ConfettiView(particleCount: 30)
        }
}
#endif
