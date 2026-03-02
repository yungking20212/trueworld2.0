import Foundation
import Supabase
import Combine
import SwiftUI
import PostgREST
import Realtime
internal import _Helpers

nonisolated struct SceneUpdatePayload: Encodable, Sendable {
    let scenes: [AIScene]
}

@MainActor
class ProductionService: ObservableObject {
    static let shared = ProductionService()
    private let client = SupabaseManager.shared.client
    
    @Published var productions: [AIProduction] = []
    @Published var isLoading = false
    @Published var selectedModel: String = "gen4_turbo" // Default to Gen-4
    
    func createProduction(title: String, prompt: String, genre: String, castImages: [Data], resolution: String = "4K", dimension: String = "4D", isTunvision: Bool = false) async throws -> AIProduction {
        let user = try await client.auth.session.user
        
        // 1. Upload Cast Images and get URLs
        var castURLs: [URL] = []
        for (index, data) in castImages.enumerated() {
            let path = "cast/\(user.id)/\(UUID().uuidString).jpg"
            _ = try await client.storage.from("media").upload(path: path, file: data)
            if let url = try? client.storage.from("media").getPublicURL(path: path) {
                castURLs.append(url)
            }
        }
        
        // 2. Generate Script (LLM Hook)
        let scenes = try await generateNeuralScript(prompt: prompt, genre: genre)
        
        // 3. Save to Supabase
        let dto = AIProductionDTO(
            id: UUID(),
            user_id: user.id,
            title: title,
            script_prompt: prompt,
            genre: genre,
            scenes: scenes,
            cast_member_urls: castURLs.map { $0.absoluteString },
            resolution: resolution,
            dimension: dimension,
            is_tunvision: isTunvision,
            created_at: Date()
        )
        
        try await performInsert(dto: dto)
        
        let newProduction = AIProduction(
            id: dto.id,
            userId: dto.user_id,
            title: dto.title,
            scriptPrompt: dto.script_prompt,
            genre: dto.genre,
            scenes: dto.scenes,
            castMemberURLs: castURLs,
            resolution: resolution,
            dimension: dimension,
            isTunvision: isTunvision,
            createdAt: dto.created_at
        )
        
        self.productions.insert(newProduction, at: 0)
        return newProduction
    }
    
    // Real LLM Integration using Gemini
    private func generateNeuralScript(prompt: String, genre: String) async throws -> [AIScene] {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(AIConfig.geminiKey)")!
        
        let systemPrompt = """
        You are the Trueworld AI Neural Brain. Generate a cinematic script based on the user's prompt and genre.
        Return ONLY a JSON array of 4 scenes. Each scene MUST have "title" and "description".
        Genre: \(genre)
        User Prompt: \(prompt)
        JSON Format example: [{"title": "Scene 1", "description": "Details..."}, ...]
        Do not include markdown formatting or extra text.
        """
        
        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": systemPrompt]]]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Parse Gemini response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw NSError(domain: "GeminiError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid API Response"])
        }
        
        // Clean the JSON string (Gemini sometimes adds markdown blocks)
        let cleanedJSON = text.replacingOccurrences(of: "```json", with: "")
                            .replacingOccurrences(of: "```", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        nonisolated struct GeminiScene: Codable {
            let title: String
            let description: String
        }
        
        let sceneDTOs = try JSONDecoder().decode([GeminiScene].self, from: Data(cleanedJSON.utf8))
        
        return sceneDTOs.map { dto in
            AIScene(title: dto.title, description: dto.description)
        }
    }
    
    // Real Video Generation Integration using RunwayML
    func triggerVideoGeneration(for sceneId: UUID, in productionId: UUID) async {
        guard let pIndex = productions.firstIndex(where: { $0.id == productionId }),
              let sIndex = productions[pIndex].scenes.firstIndex(where: { $0.id == sceneId }) else { return }
        
        let production = productions[pIndex]
        let scene = production.scenes[sIndex]
        
        // Use first cast image and the scene's description
        let imageURL = production.castMemberURLs.first?.absoluteString ?? ""
        let promptText = scene.description
        
        withAnimation { productions[pIndex].scenes[sIndex].status = .generating }
        
        do {
            let isVeo = self.selectedModel == "veo3.1"
            let endpoint = isVeo ? "text_to_video" : "image_to_video"
            let url = URL(string: "https://api.runwayml.com/v1/\(endpoint)")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(AIConfig.runwaySecret)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            var body: [String: Any] = [
                "model": self.selectedModel,
                "promptText": promptText
            ]
            
            if isVeo {
                body["ratio"] = "1280:720"
                body["duration"] = 8
            } else {
                body["promptImage"] = imageURL
                body["duration"] = 5
            }
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let taskId = json["id"] as? String else {
                throw NSError(domain: "RunwayError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create task"])
            }
            
            // Polling Loop for Completion
            var isCompleted = false
            var attempts = 0
            while !isCompleted && attempts < 20 { // Max 2 mins (approx)
                try await Task.sleep(nanoseconds: 6 * 1_000_000_000) // 6 second wait
                attempts += 1
                
                let pollUrl = URL(string: "https://api.runwayml.com/v1/tasks/\(taskId)")!
                var pollRequest = URLRequest(url: pollUrl)
                pollRequest.addValue("Bearer \(AIConfig.runwaySecret)", forHTTPHeaderField: "Authorization")
                
                let (pollData, _) = try await URLSession.shared.data(for: pollRequest)
                if let pollJson = try JSONSerialization.jsonObject(with: pollData) as? [String: Any],
                   let status = pollJson["status"] as? String {
                    
                    if status == "SUCCEEDED", let result = pollJson["output"] as? [String], let firstURL = result.first {
                        withAnimation {
                            productions[pIndex].scenes[sIndex].videoURL = URL(string: firstURL)
                            productions[pIndex].scenes[sIndex].status = .completed
                        }
                        isCompleted = true
                        
                        // Sync to Supabase
                        try await syncProductionUpdate(id: productionId)
                    } else if status == "FAILED" {
                        withAnimation { productions[pIndex].scenes[sIndex].status = .failed }
                        isCompleted = true
                    }
                }
            }
            
        } catch {
            print("Runway Error: \(error)")
            withAnimation { productions[pIndex].scenes[sIndex].status = .failed }
        }
    }
    
    private func syncProductionUpdate(id: UUID) async throws {
        guard let production = productions.first(where: { $0.id == id }) else { return }
        
        let update = SceneUpdateDTO(scenes: production.scenes)
        try await performUpdate(id: id, update: update)
    }
    
    // MARK: - Synchronized Helpers
    
    @MainActor
    private func performInsert(dto: AIProductionDTO) async throws {
        try await SupabaseManager.shared.client.database
            .from("ai_productions")
            .insert(dto)
            .execute()
    }
    
    @MainActor
    private func performUpdate(id: UUID, update: SceneUpdateDTO) async throws {
        let payload = SceneUpdatePayload(scenes: update.scenes)
        try await SupabaseManager.shared.client.database
            .from("ai_productions")
            .update(payload)
            .eq("id", value: id)
            .execute()
    }
    
    func fetchLibrary() async {
        isLoading = true
        do {
            let user = try await client.auth.session.user
            let response = try await client.database
                .from("ai_productions")
                .select()
                .eq("user_id", value: user.id)
                .order("created_at", ascending: false)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let dtos = try decoder.decode([AIProductionDTO].self, from: response.data)
            
            self.productions = dtos.map { dto in
                AIProduction(
                    id: dto.id,
                    userId: dto.user_id,
                    title: dto.title,
                    scriptPrompt: dto.script_prompt,
                    genre: dto.genre,
                    scenes: dto.scenes,
                    castMemberURLs: dto.cast_member_urls.compactMap { URL(string: $0) },
                    resolution: dto.resolution,
                    dimension: dto.dimension,
                    isTunvision: dto.is_tunvision,
                    createdAt: dto.created_at
                )
            }
        } catch {
            print("Fetch Library Error: \(error)")
        }
        isLoading = false
    }
}

