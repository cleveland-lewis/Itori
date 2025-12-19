import Foundation
import SwiftUI // for Process availability on Apple platforms

#if os(macOS)

/// MLX LLM backend implementation (via Python subprocess)
class MLXBackend: LLMBackend {
    let config: LLMBackendConfig
    private let pythonPath: String
    
    init(config: LLMBackendConfig, pythonPath: String = "/opt/anaconda3/bin/python3") {
        self.config = config
        self.pythonPath = pythonPath
    }
    
    var isAvailable: Bool {
        get async {
            // Check if Python is available
            let process = Process()
            process.executableURL = URL(fileURLWithPath: pythonPath)
            process.arguments = ["-c", "import mlx_lm; print('OK')"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                return process.terminationStatus == 0 && output.contains("OK")
            } catch {
                return false
            }
        }
    }
    
    func generate(prompt: String) async throws -> LLMResponse {
        let startTime = Date()
        
        // Create a temporary Python script
        let script = createGenerationScript(prompt: prompt)
        let scriptPath = NSTemporaryDirectory() + "mlx_generate_\(UUID().uuidString).py"
        
        try script.write(toFile: scriptPath, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(atPath: scriptPath)
        }
        
        // Run the Python script
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = [scriptPath]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            
            // Wait with timeout
            let deadline = Date().addingTimeInterval(config.timeout)
            while process.isRunning && Date() < deadline {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
            
            if process.isRunning {
                process.terminate()
                throw LLMBackendError.timeoutError
            }
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            let output = String(data: outputData, encoding: .utf8) ?? ""
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            
            guard process.terminationStatus == 0 else {
                throw LLMBackendError.invalidResponse("MLX script failed: \(errorOutput)")
            }
            
            // Parse JSON response
            guard let jsonData = output.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let responseText = json["text"] as? String else {
                throw LLMBackendError.invalidResponse("Invalid JSON output from MLX")
            }
            
            let latency = Date().timeIntervalSince(startTime) * 1000
            
            return LLMResponse(
                text: responseText,
                tokensUsed: json["tokens"] as? Int,
                finishReason: "stop",
                model: config.modelName,
                latencyMs: latency
            )
            
        } catch let error as LLMBackendError {
            throw error
        } catch {
            throw LLMBackendError.networkError(error.localizedDescription)
        }
    }
    
    func generateJSON(prompt: String, schema: String?) async throws -> String {
        let jsonPrompt = """
        \(prompt)
        
        CRITICAL: Respond with ONLY valid JSON. No markdown, no explanations, no code blocks.
        Your response must start with { and end with }
        """
        
        let response = try await generate(prompt: jsonPrompt)
        return extractJSON(from: response.text)
    }
    
    private func createGenerationScript(prompt: String) -> String {
        // Escape the prompt for Python
        let escapedPrompt = prompt
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        
        let script = """
        #!/usr/bin/env python3
        import json
        import sys
        from mlx_lm import load, generate
        
        try:
            model, tokenizer = load("\(config.modelName)")
            
            prompt = '''\(escapedPrompt)'''
            
            response = generate(
                model,
                tokenizer,
                prompt=prompt,
                temp=\(config.temperature),
                max_tokens=\(config.maxTokens),
                verbose=False
            )
            
            # Count tokens (approximate)
            tokens = len(tokenizer.encode(response))
            
            result = {
                "text": response,
                "tokens": tokens
            }
            
            print(json.dumps(result))
            sys.exit(0)
            
        except Exception as e:
            print(f"Error: {str(e)}", file=sys.stderr)
            sys.exit(1)
        """
        
        return script
    }
    
    private func extractJSON(from text: String) -> String {
        var cleaned = text
        
        // Remove markdown code blocks
        if cleaned.contains("```json") {
            cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
        }
        if cleaned.contains("```") {
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        }
        
        // Find JSON boundaries
        if let firstBrace = cleaned.firstIndex(of: "{"),
           let lastBrace = cleaned.lastIndex(of: "}") {
            return String(cleaned[firstBrace...lastBrace])
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#endif
