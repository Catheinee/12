import SwiftUI

enum CampusColors {
    static let ink = Color(hex: "173331")
    static let muted = Color(hex: "667570")
    static let line = Color(hex: "DEDBD4")
    static let surface = Color(hex: "FBFCFB")
    static let canvas = Color(hex: "F6F7F5")
    static let teal = Color(hex: "167D78")
    static let tealWash = Color(hex: "EEF7F3")
    static let coral = Color(hex: "E76F51")
    static let amber = Color(hex: "D49B42")
    static let danger = Color(hex: "B06B3D")
    static let blue = Color(hex: "5277A8")
    static let purple = Color(hex: "8064A2")
}

enum CampusMetrics {
    static let pagePadding: CGFloat = 20
    static let compactPadding: CGFloat = 14
    static let smallGap: CGFloat = 8
    static let standardGap: CGFloat = 14
    static let sectionGap: CGFloat = 24
    static let radius: CGFloat = 8
    static let minTouchTarget: CGFloat = 44
    static let scheduleHourHeight: CGFloat = 64
    static let scheduleDayWidth: CGFloat = 138
    static let scheduleStartHour = 8
    static let scheduleEndHour = 22
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex, radix: 16) ?? 0
        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: 1
        )
    }
}

struct CampusSectionTitle: View {
    let eyebrow: String
    let title: String
    var detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(CampusColors.teal)
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(CampusColors.ink)
            if let detail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(CampusColors.muted)
            }
        }
    }
}

struct CampusPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(CampusMetrics.standardGap)
            .background(CampusColors.surface)
            .overlay(RoundedRectangle(cornerRadius: CampusMetrics.radius).stroke(CampusColors.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: CampusMetrics.radius))
    }
}

struct CampusChip: View {
    let title: String
    var symbol: String?
    var tint: Color = CampusColors.teal

    var body: some View {
        HStack(spacing: 5) {
            if let symbol { Image(systemName: symbol) }
            Text(title)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(tint.opacity(0.10))
        .clipShape(Capsule())
    }
}

struct CampusIconButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.headline.weight(.semibold))
                .frame(width: CampusMetrics.minTouchTarget, height: CampusMetrics.minTouchTarget)
                .foregroundStyle(CampusColors.teal)
                .background(CampusColors.tealWash)
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
