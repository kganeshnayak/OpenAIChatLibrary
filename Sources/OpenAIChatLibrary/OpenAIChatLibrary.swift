import Foundation
import SwiftUI
import OpenAISwift

// Re-export key public types to simplify imports for consumers
public typealias ChatMessage = OpenAIChatLibrary.ChatMessage
public typealias ChatViewModel = OpenAIChatLibrary.ChatViewModel
public typealias ChatView = OpenAIChatLibrary.ChatView
public typealias KeychainHelper = OpenAIChatLibrary.KeychainHelper

// Namespace for the library's components
public enum OpenAIChatLibrary {
    // MARK: - ChatMessage
    public struct ChatMessage: Identifiable, Codable {
        public let id: UUID
        public let message: String
        public let isUser: Bool
        public let timestamp: Date
        
        public init(id: UUID = UUID(), message: String, isUser: Bool, timestamp: Date = Date()) {
            self.id = id
            self.message = message
            self.isUser = isUser
            self.timestamp = timestamp
        }
        
        enum CodingKeys: String, CodingKey {
            case id, message, isUser, timestamp
        }
    }
    
    // MARK: - ChatViewModel
    public final class ChatViewModel: ObservableObject {
        @Published public private(set) var messages: [ChatMessage] = []
        private let openAI: OpenAISwift
        
        public init(apiKey: String) {
            let config = OpenAISwift.Config.makeDefaultOpenAI(apiKey: apiKey)
            self.openAI = OpenAISwift(config: config)
        }
        
        public func sendMessage(_ message: String, completion: @escaping (Result<ChatMessage, Error>) -> Void) {
            let userMessage = ChatMessage(message: message, isUser: true)
            messages.append(userMessage)
            
            openAI.sendCompletion(
                with: message,
                model: .chat(.chatgpt),
                maxTokens: 500
            ) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let model):
                        if let response = model.choices?.first?.text {
                            self?.receiveBotMessage(response)
                            let botMessage = ChatMessage(message: response.trimmingCharacters(in: .whitespacesAndNewlines), isUser: false)
                            completion(.success(botMessage))
                        } else {
                            let error = NSError(domain: "OpenAIChatLibrary", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response received"])
                            self?.handleError(error)
                            completion(.failure(error))
                        }
                    case .failure(let error):
                        self?.handleError(error)
                        completion(.failure(error))
                    }
                }
            }
        }
        
        private func receiveBotMessage(_ message: String) {
            let botMessage = ChatMessage(message: message.trimmingCharacters(in: .whitespacesAndNewlines), isUser: false)
            messages.append(botMessage)
        }
        
        private func handleError(_ error: Error) {
            let errorMessage = ChatMessage(message: "Error: \(error.localizedDescription)", isUser: false)
            messages.append(errorMessage)
        }
    }
    
    // MARK: - ChatView
    public struct ChatView: View {
        @ObservedObject public var viewModel: ChatViewModel
        @State private var newMessage = ""
        @State private var isLoading = false
        
        public init(viewModel: ChatViewModel) {
            self.viewModel = viewModel
        }
        
        public var body: some View {
            VStack {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageView(message: message)
                        }
                    }
                    .padding()
                }
                
                HStack {
                    TextField("Type your message", text: $newMessage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .disabled(isLoading)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                    }
                    .disabled(newMessage.isEmpty || isLoading)
                    .padding(.trailing)
                }
                .padding(.bottom)
            }
            .overlay(
                Group {
                    if isLoading {
                        ProgressView("Thinking...")
                            .padding()
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
            )
        }
        
        private func sendMessage() {
            guard !newMessage.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            isLoading = true
            viewModel.sendMessage(newMessage) { _ in
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.newMessage = ""
                }
            }
        }
    }
    
    // MARK: - MessageView
    private struct MessageView: View {
        let message: ChatMessage
        
        var body: some View {
            HStack {
                if message.isUser {
                    Spacer()
                    Text(message.message)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                } else {
                    Text(message.message)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.black)
                        .cornerRadius(10)
                    Spacer()
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - KeychainHelper
    public class KeychainHelper {
        public static let shared = KeychainHelper()
        
        private init() {}
        
        public func save(key: String, data: String) -> Bool {
            let data = Data(data.utf8)
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "com.yourapp.openai",
                kSecAttrAccount as String: key,
                kSecValueData as String: data
            ]
            
            SecItemDelete(query as CFDictionary)
            let status = SecItemAdd(query as CFDictionary, nil)
            return status == errSecSuccess
        }
        
        public func load(key: String) -> String? {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "com.yourapp.openai",
                kSecAttrAccount as String: key,
                kSecReturnData as String: kCFBooleanTrue!,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]
            
            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            guard status == errSecSuccess, let data = item as? Data else { return nil }
            return String(data: data, encoding: .utf8)
        }
    }
}
