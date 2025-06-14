//
//  DeepSeekViewModel.swift
//  Lumis
//
//  Created by Shuiii on 2/26/25.
//

import Foundation
import SwiftData

class DiagnosisViewModel: ObservableObject {
    @Published var errorMessage: String? = nil
    @Published var diagnosisResponse: DiagnosisResponse = .init(detectedEmotions: [], chakraBalance: [:], energyState: "")
    @Published var cardResponse: CardResponse = .init(response: "", quote: "")
    @Published var isLoading = false
    @Published var showCard = false
    @Published var invalidResponseNotice = false

    var cardText: String { cardResponse.response }
    var cardQuote: String { cardResponse.quote }
    var emotion: [String] { diagnosisResponse.detectedEmotions }

    private let apiClient: APIClient
    private let endpoint = "/api/v3/chat/completions" // DeepSeek API端点

    init() {
        let apiKey = AIModel.deepseekKey
        self.apiClient = APIClient(baseURL: URL(string: "https://ark.cn-beijing.volces.com")!, apiKey: apiKey)
    }

    // 发送DeepSeek API请求
    func sendDiagnosisRequest(messages: [SendMessage]) {
        showCard = false
        isLoading = true

        let parameters: [String: Any] = [
            "model": AIModel.deepseekModel,
            "messages": messages.map { $0.toDictionary() }, // 将 [DeepSeekMessage] 转换为 [[String: Any]]
            "stream": false
        ]

        apiClient.sendRequest(endpoint: endpoint, method: .post, parameters: parameters) { (result: Result<DeepSeekResponse, APIError>) in
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    if let firstChoice = response.choices.first {
                        if firstChoice.message.isInvalidInput {
                            // 检测到无效输入
                            self.invalidResponseNotice = true
                            self.isLoading = false
                            return
                        }

                        if let formattedContent = firstChoice.message.formattedDiagnosisResponse {
                            print("Formatted Content: \(formattedContent)")
                            self.diagnosisResponse = formattedContent
                            self.errorMessage = nil
                            self.invalidResponseNotice = false

                            // 只有在有效输入时才发送卡片请求
                            if let userMessage = messages.last(where: { $0.role == .user }) {
                                let systemMessage = SendMessage(role: .system, content: DiagnosisViewModel.system)
                                self.sendCardRequest(messages: [systemMessage, userMessage])
                            }
                        } else {
                            self.errorMessage = "无法解析响应内容"
                            self.invalidResponseNotice = true
                            self.isLoading = false
                        }
                    }
                }

            case .failure(let error):
                DispatchQueue.main.async {
                    self.errorMessage = "Error: \(error)"
                }
            }
        }
    }

    func sendCardRequest(messages: [SendMessage]) {
        showCard = false
        isLoading = true

        let parameters: [String: Any] = [
            "model": AIModel.deepseekModel,
            "messages": messages.map { $0.toDictionary() },
            "stream": false
        ]

        // 使用APIClient发起请求
        apiClient.sendRequest(endpoint: endpoint, method: .post, parameters: parameters) { (result: Result<DeepSeekResponse, APIError>) in
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    if let firstChoice = response.choices.first,
                       let formattedContent = firstChoice.message.formattedCardResponse
                    {
                        self.cardResponse = formattedContent
                        self.showCard = true
                        self.invalidResponseNotice = false

                    } else {
                        self.errorMessage = "无法解析响应内容"
                    }
                }

                print(response)

            case .failure(let error):
                DispatchQueue.main.async {
                    self.errorMessage = "Error: \(error)"
                }
            }
        }
    }
}

struct SendMessage: Codable {
    let role: Participant
    let content: String
}

extension SendMessage {
    func toDictionary() -> [String: Any] {
        [
            "role": role.rawValue,
            "content": content
        ]
    }
}

enum Participant: String, Codable {
    case system
    case user
    case assistant
}

extension DiagnosisViewModel {
    //提示词
    static let energyDiagnosisPrompt: String = """
    """
    
    static let system: String = """
    """
}

