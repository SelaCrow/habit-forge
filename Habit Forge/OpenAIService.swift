//
//  OpenAIService.swift
//  Habit Forge
//
//  Created by Marisela Gomez on 7/27/25.
//

import Foundation

class OpenAIService {
    static let shared = OpenAIService()
    private let apiKey = Secrets.OPENAI_API_KEY
    
    func generateDailyQuest(
        flavor: String,
        userClass: String,
        completion: @escaping (String?) -> Void
    ) {
        let normalizedFlavor = flavor.lowercased()
        let normalizedClass = userClass.capitalized
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        let prompt = """
        Write aproductivity task as a quest in a \(normalizedFlavor) style for a \(normalizedClass) character. Make it funny, creative, and only 1 to 2 sentences long.
        
        **Format exactly like this:**
        [Short quest title that ends with either a period (.), exclamation mark (!), or colon (:)]
        Description: [One to two whimsical, playful sentences encouraging action.]

        **Important:**
        - The quest title MUST end in a period, exclamation mark, or colon.
        - Do NOT use quotation marks around the title or description.
        - The description should be a full sentence, but do not repeat the title in it.

        """
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a creative quest designer for a productivity RPG app."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 70,
            "temperature": 0.9
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("API call error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let data = data else {
                print("No data received from API.")
                completion(nil)
                return
            }
            if let raw = String(data: data, encoding: .utf8) {
                print("Raw API response: \(raw)")
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let aiText = message["content"] as? String {
                    completion(aiText.trimmingCharacters(in: .whitespacesAndNewlines))
                } else {
                    print("Failed to parse AI response JSON.")
                    completion(nil)
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }

    func flavorizeQuest(
        task: String,
        flavor: String,
        userClass: String,
        completion: @escaping (String?) -> Void
    ) {
        let normalizedFlavor = flavor.lowercased()
//        let normalizedClass = userClass.capitalized
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        let prompt = """
        Rewrite the following productivity task as a quest in a \(normalizedFlavor) style for a \(userClass) character. Make it funny, creative, and only 1 to 2 sentences long.

        **Format exactly like this:**
        [Short quest title that ends with either a period (.), exclamation mark (!), or colon (:)]
        Description: [One to two whimsical, playful sentences encouraging action.]

        **Important:**
        - The quest title MUST end in a period, exclamation mark, or colon.
        - Do NOT use quotation marks around the title or description.
        - The description should be a full sentence, but do not repeat the title in it.

        Task: "\(task)"
        """
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a creative quest designer for a productivity RPG app."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 50,
            "temperature": 0.9
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("API call error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let data = data else {
                print("No data received from API.")
                completion(nil)
                return
            }
            if let raw = String(data: data, encoding: .utf8) {
                print("Raw API response: \(raw)")
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let aiText = message["content"] as? String {
                    completion(aiText.trimmingCharacters(in: .whitespacesAndNewlines))
                } else if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let errorDict = json["error"] as? [String: Any],
                          let errorMessage = errorDict["message"] as? String {
                    print("OpenAI API error: \(errorMessage)")
                    completion(nil)
                } else {
                    print("Failed to parse AI response JSON.")
                    completion(nil)
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }
}
