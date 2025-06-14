//
//  SettingView.swift
//  Lumis
//
//  Created by Shuiii on 3/12/25.
//

import SwiftUI


struct SettingsView: View {
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ProUpgradeCard()
                settingsList
                bottomActions
            }
            .padding(.top,16)
            .padding(.horizontal, 16)
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.whiteGray))
    }
    
    // MARK: - Subviews
    private var settingsList: some View {
        VStack(spacing: 0) {
            ForEach(SettingsItem.allCases) { item in
                SettingsRow(item: item)
                if item != SettingsItem.allCases.last {
                    Divider().padding(.horizontal)
                }
            }
        }
        .cardStyle()
    }
    
    private var bottomActions: some View {
        VStack(spacing: 10) {
            Button("恢复购买") {}
                .secondaryButtonStyle()
            
            HStack(spacing: 20) {
                Button("隐私政策") {}
                Button("用户协议") {}
            }
            .secondaryButtonStyle()
        }
        .padding(.top, 12)
        .padding(.bottom, 20)
    }
}

// MARK: - Settings Components
private struct ProUpgradeCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            description
            upgradeButton
        }
        .padding(16)
        .background(gradientBackground)
        .cornerRadius(24)
    }
    
    private var header: some View {
        Text("👑 Lumis Pro")
            .cardTitleStyle()
    }
    
    private var description: some View {
        Text("心愿无限，生活无边\n解锁更多功能，更好体验")
            .cardDescriptionStyle()
    }
    
    private var upgradeButton: some View {
        Button("了解更多") {}
            .upgradeButtonStyle()
    }
    
    private var gradientBackground: some View {
        LinearGradient(
            gradient: Gradient(
                colors: [
                    .softPeach.opacity(0.5),
                    .softPurple.opacity(0.5),
                    .softBlue.opacity(0.6)
                ]
            ),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Models
private enum SettingsItem: CaseIterable, Identifiable {
    case language, feedback, rate, share, about
    
    var id: Self { self }
    
    var icon: String {
        switch self {
        case .language: return "globe"
        case .feedback: return "bubble.left.and.bubble.right"
        case .rate: return "star"
        case .share: return "square.and.arrow.up"
        case .about: return "info.circle"
        }
    }
    
    var title: String {
        switch self {
        case .language: return "语言"
        case .feedback: return "对我们的期望"
        case .rate: return "给个好评"
        case .share: return "分享"
        case .about: return "关于我们"
        }
    }
}

// MARK: - Settings Row Component
private struct SettingsRow: View {
    let item: SettingsItem  // 使用枚举数据源
    var trailingText: String? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            iconView
            titleView
            Spacer()
            trailingContentView
            navigationChevron
        }
        .contentShape(Rectangle())  // 扩大点击区域
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Subviews
    private var iconView: some View {
        Image(systemName: item.icon)
            .symbolRenderingMode(.monochrome)
            .frame(width: 24, height: 24)
            .foregroundStyle(.secondary)
    }
    
    private var titleView: some View {
        Text(item.title)
            .customFont(size: 17)
            .foregroundStyle(.primary)
    }
    
    @ViewBuilder
    private var trailingContentView: some View {
        if let text = trailingText {
            Text(text)
                .customFont(size: 15)
                .foregroundStyle(.secondary)
        }
    }
    
    private var navigationChevron: some View {
        Image(systemName: "chevron.right")
            .font(.footnote)
            .foregroundStyle(.tertiary)
    }
}

// MARK: - View Extensions
private extension View {
    func cardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
            )
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .font(.system(size: 14))
            .foregroundColor(.gray)
    }
    
    func upgradeButtonStyle() -> some View {
        self
            .customFont(size: 17)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.silent)
            .cornerRadius(12)
    }
}

private extension Text {
    func cardTitleStyle() -> some View {
        self
            .customFont(size: 24)
            .fontWeight(.bold)
            .padding(.bottom)
    }
    
    func cardDescriptionStyle() -> some View {
        self
            .customFont(size: 14)
            .foregroundColor(.gray)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
