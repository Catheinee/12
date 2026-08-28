import SwiftUI

struct CampusRootView: View {
    @EnvironmentObject private var store: CampusStore
    @State private var selection: CampusModule = .today

    var body: some View {
        NavigationStack {
            Group {
                switch selection {
                case .today: TodayView()
                case .plan: PlanView()
                case .schedule: ScheduleView()
                case .reminders: RemindersView()
                case .academic: AcademicView()
                case .tasks: TasksView()
                case .campus: CampusView()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                CampusTabBar(selection: $selection)
            }
        }
        .tint(CampusColors.teal)
        .background(CampusColors.canvas)
    }
}

struct CampusTabBar: View {
    @Binding var selection: CampusModule

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(CampusModule.allCases) { module in
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) { selection = module }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: module.symbol)
                                .font(.system(size: 16, weight: .semibold))
                            Text(module.rawValue)
                                .font(.caption2.weight(.semibold))
                        }
                        .frame(minWidth: 66, minHeight: CampusMetrics.minTouchTarget)
                        .foregroundStyle(selection == module ? CampusColors.teal : CampusColors.muted)
                        .background(selection == module ? CampusColors.tealWash : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(module.rawValue)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Rectangle().fill(CampusColors.line).frame(height: 1) }
    }
}

struct CampusPage<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, CampusMetrics.pagePadding)
                .padding(.top, CampusMetrics.pagePadding)
                .padding(.bottom, CampusMetrics.sectionGap)
        }
        .scrollIndicators(.hidden)
        .background(CampusColors.canvas.ignoresSafeArea())
    }
}

struct CampusHeader: View {
    let eyebrow: String
    let title: String
    var detail: String?

    var body: some View {
        HStack(alignment: .top) {
            CampusSectionTitle(eyebrow: eyebrow, title: title, detail: detail)
            Spacer(minLength: 12)
            Text("同")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(CampusColors.coral)
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }
    }
}

struct CampusStat: View {
    let value: String
    let label: String
    var tint: Color = CampusColors.teal

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.title3.weight(.bold)).foregroundStyle(CampusColors.ink)
            Text(label).font(.caption).foregroundStyle(CampusColors.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 10)
        .overlay(alignment: .leading) { Rectangle().fill(tint).frame(width: 2) }
    }
}
