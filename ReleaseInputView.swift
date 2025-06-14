//
//  ReleaseInputView.swift
//  Lumis
//
//  Created by Shuiii on 3/7/25.
//

import SwiftUI

struct ReleaseInputView: View {
    // MARK: - Properties
    @FocusState private var isFocused: Bool
    @Binding var showInput: Bool
    @ObservedObject var tfManager = TFManager()
    @ObservedObject var viewModel: DiagnosisViewModel
    @Environment(\.modelContext) private var modelContext
    @StateObject private var releaseManager = ReleaseManager()
    
    // View States
    @State private var isEditorVisible = false
    @State private var showLoading = false
    @State private var showFlipCard = false
    @State private var showLimitReachedAlert = false
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            mainContent
                .background(gradientBackground)
                .toolbar { toolbarContent }
                .alert(isPresented: $showLimitReachedAlert) { releaseLimitAlert }
        }
        .overlay { overlayContent }
        .onChange(of: viewModel.cardResponse) { handleAPIResponse($1) }
        .onAppear { animateEditorAppearance() }
    }
    
    // MARK: - Subviews
    private var mainContent: some View {
        VStack(spacing: 24) {
            emotionTextEditor
            releaseButtonSection
        }
        .padding(.horizontal, 24)
        .vSpacing(.top)
    }
    
    private var emotionTextEditor: some View {
        TextEditor(text: $tfManager.text)
            .focused($isFocused)
            .frame(height: isEditorVisible ? 320 : 0)
            .editorStyle(isVisible: isEditorVisible)
    }
    
    private var releaseButtonSection: some View {
        VStack(spacing: 0) {
            characterCountIndicator
            releaseButton
        }
    }
    
    @ViewBuilder
    private var characterCountIndicator: some View {
        if !tfManager.text.isEmpty {
            HStack {
                Spacer()
                Text("\(tfManager.text.count) /200")
                    .countIndicatorStyle()
            }
        }
    }
    
    private var releaseButton: some View {
        Button(action: handleRelease) {
            Text("释放\(releaseManager.releaseCount)/5")
                .releaseButtonStyle()
        }
        .opacity(tfManager.text.isEmpty ? 0 : 1)
    }
    
    // MARK: - Backgrounds & Overlays
    private var gradientBackground: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [.softPurple, .softBlue.opacity(0.49), .softPeach.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: 1000
                )
            )
            .frame(width: UIScreen.main.bounds.width * 2)
            .blur(radius: 100)
            .offset(y: -300)
    }
    
    @ViewBuilder
    private var overlayContent: some View {
        if viewModel.invalidResponseNotice {
            invalidResponseView(retryAction: resetEditor)
        } else {
            ZStack {
                Color.black.opacity(0.0001)
                    .backgroundBlur(showInput: showInput)
                
                if showLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
                
                if showFlipCard {
                    FlipCardView(
                        emotions: viewModel.emotion,
                        message: viewModel.cardText,
                        quote: viewModel.cardQuote,
                        dismiss: $showInput
                    )
                }
            }
            .opacity(showLoading || showFlipCard ? 1 : 0)
        }
    }
    
    // MARK: - Toolbar
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: dismiss) {
                    Label("取消", systemImage: "chevron.left")
                        .foregroundStyle(Color.vividViolet)
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Text(Date.now.formattedDate(style: .fullWithTime))
                    .customFont(size: 17)
            }
        }
    }
    
    private var releaseLimitAlert: Alert {
        Alert(
            title: Text("能量释放上限已达"),
            message: Text("今天的能量释放次数已用完\n休息一下，明天再来吧！\n您的成长每一天都在发生 💫"),
            dismissButton: .default(Text("好的"))
        )
    }
    
    // MARK: - Methods
    private func handleRelease() {
        guard !tfManager.text.isEmpty else { return }
        
        if !releaseManager.canRelease() {
            showLimitReachedAlert = true
            return
        }
        
        releaseManager.release()
        let messages = prepareAPIMessages()
        viewModel.sendDiagnosisRequest(messages: messages)
        tfManager.text = ""
        dismissEditor()
    }
    
    private func prepareAPIMessages() -> [SendMessage] {
        [
            SendMessage(role: .system, content: DiagnosisViewModel.energyDiagnosisPrompt),
            SendMessage(role: .user, content: tfManager.text)
        ]
    }
    
    private func dismiss() {
        withAnimation(.editorTransition) {
            isFocused = false
            isEditorVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showInput = false
        }
    }
    
    private func dismissEditor() {
        withAnimation(.editorTransition) {
            isFocused = false
            isEditorVisible = false
        }
    }
    
    private func resetEditor() {
        viewModel.invalidResponseNotice = false
        isEditorVisible = true
        isFocused = true
    }
    
    private func handleAPIResponse(_ response: CardResponse) {
        withAnimation {
            showLoading = false
            showFlipCard = true
        }
        saveResponseToSwiftData()
    }
    
    private func animateEditorAppearance() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                isEditorVisible = true
                isFocused = true
            }
        }
    }
    
    private func saveResponseToSwiftData() {
        let newDiagnosis = EnergyDiagnosis(
            detectedEmotions: viewModel.diagnosisResponse.detectedEmotions,
            energyState: EnergyState(rawValue: viewModel.diagnosisResponse.energyState) ?? .balanced
        )
        
        let newEmotionCard = EmotionCard(
            rawInput: tfManager.text,
            responseText: viewModel.cardResponse.response,
            quote: viewModel.cardResponse.quote
        )
        
        newDiagnosis.timestamp = Date()
        newDiagnosis.chakraBalance = viewModel.diagnosisResponse.chakraBalance
            .compactMapKeys { ChakraType.from($0) }
        
        newEmotionCard.relatedEnergyDiagnosis = newDiagnosis
        
        modelContext.insert(newDiagnosis)
        modelContext.insert(newEmotionCard)
        
        try? modelContext.save()
    }
}

// MARK: - View Extensions
private extension View {
    func editorStyle(isVisible: Bool) -> some View {
        self
            .scrollContentBackground(.hidden)
            .multilineTextAlignment(.leading)
            .customFont(size: 17)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.paper)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .padding(.top, 24)
            .scaleEffect(isVisible ? 1 : 0.8)
            .opacity(isVisible ? 1 : 0)
            .animation(.editorTransition, value: isVisible)
            .tint(.vividViolet)
    }
    
    func backgroundBlur(showInput: Bool) -> some View {
        self
            .ignoresSafeArea()
            .background(.ultraThinMaterial)
            .blur(radius: showInput ? 8 : 0)
            .animation(.easeInOut(duration: 0.3), value: showInput)
    }
}

fileprivate extension Text {
    func countIndicatorStyle() -> some View {
        self
            .customFont(size: 12)
            .foregroundStyle(.secondary)
            .padding(.trailing)
    }
    
    func releaseButtonStyle() -> some View {
        self
            .foregroundStyle(.white.opacity(0.87))
            .customFont(size: 17)
            .fontWeight(.bold)
            .padding(.vertical, 14)
            .padding(.horizontal, 80)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.vividViolet)
            )
            .padding()
    }
}

extension Animation {
    static let editorTransition = spring(
        response: 0.5,
        dampingFraction: 0.7,
        blendDuration: 0.5
    )
}

#Preview {
    TabsView()
}
