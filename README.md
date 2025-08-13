# OpenAIChatLibrary
OpenAIChatLibrary
A SwiftUI library for integrating OpenAI's ChatGPT API into your iOS or macOS apps. Provides a reusable chat interface and API interaction logic.
Installation </br>

Add the package via Swift Package Manager:
dependencies: [
    .package(url: "https://github.com/your-repo/OpenAIChatLibrary.git", from: "1.0.0")
]

Usage

Initialize the ViewModel:

import OpenAIChatLibrary

let viewModel = ChatViewModel(apiKey: "your-openai-api-key")


Integrate the ChatView:

import SwiftUI
import OpenAIChatLibrary

struct ContentView: View {
    @StateObject var viewModel = ChatViewModel(apiKey: "your-openai-api-key")
    
    var body: some View {
        NavigationView {
            ChatView(viewModel: viewModel)
                .navigationTitle("ChatGPT")
        }
    }
}


Secure API Key (Optional):Use KeychainHelper to store the API key:

KeychainHelper.shared.save(key: "openai_api_key", data: "your-openai-api-key")
if let apiKey = KeychainHelper.shared.load(key: "openai_api_key") {
    let viewModel = ChatViewModel(apiKey: apiKey)
}

Requirements

iOS 15.0+, macOS 12.0+
Xcode 14.0+
OpenAI API key

License
MIT License
