import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct TodayView: View {
    @EnvironmentObject private var store: CampusStore
    private let calendar = Calendar.campus

    var body: some View {
        CampusPage {
            VStack(alignment: .leading, spacing: CampusMetrics.sectionGap) {
                CampusHeader(eyebrow: Date.now.formatted(.dateTime.year().month().day()), title: "今天，先完成三件事。", detail: "课程、任务和校园安排都在这里。")
                CampusPanel {
                    HStack(spacing: 16) {
                        CampusStat(value: "\(store.pendingTaskCount)", label: "待完成任务")
                        CampusStat(value: "\(todayCourses.count)", label: "今日课程", tint: CampusColors.coral)
                        CampusStat(value: "\(store.upcomingAcademicCount)", label: "学业节点", tint: CampusColors.amber)
                    }
                }
                SectionHeading(title: "今日课程", detail: todayCourses.isEmpty ? "今天没有固定课程" : "按开始时间排列")
                CampusPanel {
                    if todayCourses.isEmpty {
                        EmptyState(symbol: "sun.max", title: "今天没有课程", detail: "留出时间完成自己的计划。")
                    } else {
                        ForEach(todayCourses) { course in CampusCourseRow(course: course) }
                    }
                }
                SectionHeading(title: "今天的任务", detail: "\(store.tasks.filter { !$0.completed }.count) 项未完成")
                CampusPanel {
                    if store.tasks.isEmpty { EmptyState(symbol: "checklist", title: "还没有任务", detail: "到“任务”里添加第一项。") }
                    else { ForEach(store.tasks.prefix(3)) { CampusTaskRow(task: $0) } }
                }
                SectionHeading(title: "接下来", detail: "未完成提醒")
                CampusPanel {
                    let reminders = store.reminders.filter { !$0.completed }.sorted { $0.date < $1.date }.prefix(3)
                    if reminders.isEmpty { EmptyState(symbol: "bell.slash", title: "没有待处理提醒", detail: "你的接下来很清爽。") }
                    else { ForEach(reminders) { ReminderRow(reminder: $0) } }
                }
            }
        }
    }

    private var todayCourses: [Course] {
        store.courses.filter { $0.weekday == Date.now.mondayBasedWeekday }.sorted { $0.startMinutes < $1.startMinutes }
    }
}

struct PlanView: View {
    @EnvironmentObject private var store: CampusStore
    private let calendar = Calendar.campus

    var body: some View {
        CampusPage {
            VStack(alignment: .leading, spacing: CampusMetrics.sectionGap) {
                CampusHeader(eyebrow: "未来七天", title: "计划", detail: "把学习和生活安排到可执行的节奏里。")
                CampusPanel {
                    HStack(spacing: 16) {
                        CampusStat(value: "\(store.pendingTaskCount)", label: "待完成", tint: CampusColors.teal)
                        CampusStat(value: "\(store.reminders.filter { !$0.completed }.count)", label: "待提醒", tint: CampusColors.coral)
                        CampusStat(value: "\(store.academicItems.count)", label: "学业节点", tint: CampusColors.amber)
                    }
                }
                SectionHeading(title: "未来安排", detail: "课程、任务与节点合并查看")
                LazyVStack(spacing: 10) {
                    ForEach(upcomingDates, id: \.self) { date in
                        PlanDayRow(date: date, courses: courses(on: date), tasks: tasks(on: date))
                    }
                }
            }
        }
    }

    private var upcomingDates: [Date] {
        let start = calendar.startOfDay(for: .now)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private func courses(on date: Date) -> [Course] { store.courses.filter { $0.weekday == date.mondayBasedWeekday }.sorted { $0.startMinutes < $1.startMinutes } }
    private func tasks(on date: Date) -> [CampusTask] { store.tasks.filter { task in task.dueDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false } }
}

struct PlanDayRow: View {
    let date: Date
    let courses: [Course]
    let tasks: [CampusTask]

    var body: some View {
        CampusPanel {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(date.shortDateText).font(.headline.weight(.bold)).foregroundStyle(CampusColors.ink)
                    Text(date.isToday ? "今天" : date.weekdayText).font(.caption.weight(.semibold)).foregroundStyle(CampusColors.teal)
                }
                Rectangle().fill(CampusColors.line).frame(width: 1)
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(courses) { course in
                        Label { Text("\(course.timeText)  \(course.name)") } icon: { Image(systemName: "book.closed.fill") }
                            .font(.subheadline.weight(.semibold)).foregroundStyle(CampusColors.ink)
                    }
                    ForEach(tasks) { task in
                        Label { Text(task.title).strikethrough(task.completed) } icon: { Image(systemName: task.completed ? "checkmark.circle.fill" : "circle") }
                            .font(.caption).foregroundStyle(task.completed ? CampusColors.muted : CampusColors.ink)
                    }
                    if courses.isEmpty && tasks.isEmpty { Text("没有固定安排").font(.caption).foregroundStyle(CampusColors.muted) }
                }
                Spacer(minLength: 0)
            }
        }
    }
}

struct ScheduleView: View {
    @EnvironmentObject private var store: CampusStore
    @State private var selectedDay = Calendar.campus.startOfDay(for: .now)
    @State private var weekOffset = 0
    @State private var displayMode: ScheduleDisplayMode = .timeline
    @State private var showingImporter = false
    private let calendar = Calendar.campus

    var body: some View {
        CampusPage {
            VStack(alignment: .leading, spacing: CampusMetrics.sectionGap) {
                HStack(alignment: .top) {
                    CampusSectionTitle(eyebrow: weekTitle, title: "课表", detail: "选周、选日，再切换你习惯的查看方式。")
                    Spacer(minLength: 8)
                    CampusIconButton(symbol: "square.and.arrow.down", label: "导入课程") { showingImporter = true }
                }
                WeekNavigator(weekOffset: $weekOffset) { selectedDay = weekStart }
                DayPicker(selectedDay: $selectedDay, weekStart: weekStart)
                Picker("课表视图", selection: $displayMode) {
                    ForEach(ScheduleDisplayMode.allCases) { mode in Label(mode.rawValue, systemImage: mode.symbol).tag(mode) }
                }
                .pickerStyle(.segmented)
                .frame(minHeight: 44)
                if displayMode == .timeline { ScheduleTimeline(courses: selectedCourses) }
                else { ScheduleGrid(courses: store.courses, weekStart: weekStart) }
                SectionHeading(title: "校历提醒", detail: "和课程使用同一周次")
                CampusPanel {
                    ForEach(store.academicItems.prefix(3)) { AcademicRow(item: $0) }
                }
            }
        }
        .sheet(isPresented: $showingImporter) { CourseImportSheet() }
        .onChange(of: weekOffset) { _ in selectedDay = weekStart }
    }

    private var weekStart: Date {
        calendar.date(byAdding: .weekOfYear, value: weekOffset, to: calendar.mondayStart(for: .now)) ?? .now
    }

    private var weekTitle: String {
        let end = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return "\(weekStart.formatted(.dateTime.month().day())) - \(end.formatted(.dateTime.month().day()))"
    }

    private var selectedCourses: [Course] {
        store.courses.filter { $0.weekday == selectedDay.mondayBasedWeekday }.sorted { $0.startMinutes < $1.startMinutes }
    }
}

struct WeekNavigator: View {
    @Binding var weekOffset: Int
    let onReset: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            CampusIconButton(symbol: "chevron.left", label: "上一周") { weekOffset -= 1 }
            Button("回到本周") { weekOffset = 0; onReset() }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: CampusMetrics.minTouchTarget)
                .foregroundStyle(CampusColors.teal)
                .background(CampusColors.tealWash)
                .clipShape(RoundedRectangle(cornerRadius: 7))
            CampusIconButton(symbol: "chevron.right", label: "下一周") { weekOffset += 1 }
        }
    }
}

struct DayPicker: View {
    @Binding var selectedDay: Date
    let weekStart: Date
    private let calendar = Calendar.campus

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { offset in
                    let date = calendar.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
                    Button { selectedDay = date } label: {
                        VStack(spacing: 5) {
                            Text(date.weekdayShortText).font(.caption2.weight(.semibold))
                            Text(date.formatted(.dateTime.day())).font(.headline.weight(.bold))
                        }
                        .frame(width: 50, height: 58)
                        .foregroundStyle(calendar.isDate(selectedDay, inSameDayAs: date) ? CampusColors.teal : CampusColors.muted)
                        .background(calendar.isDate(selectedDay, inSameDayAs: date) ? CampusColors.tealWash : CampusColors.surface)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(calendar.isDate(selectedDay, inSameDayAs: date) ? CampusColors.teal : CampusColors.line, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ScheduleTimeline: View {
    let courses: [Course]

    var body: some View {
        CampusPanel {
            VStack(alignment: .leading, spacing: 0) {
                if courses.isEmpty { EmptyState(symbol: "calendar.badge.exclamationmark", title: "这一天没有课程", detail: "可以把时间留给任务或自习。") }
                else {
                    ForEach(courses) { course in
                        HStack(alignment: .top, spacing: 12) {
                            Text(course.timeText).font(.caption.monospacedDigit()).foregroundStyle(CampusColors.muted).frame(width: 82, alignment: .leading)
                            Rectangle().fill(Color(hex: course.colorHex)).frame(width: 4)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(course.name).font(.subheadline.weight(.bold)).foregroundStyle(CampusColors.ink)
                                Text("\(course.teacher) · \(course.room)").font(.caption).foregroundStyle(CampusColors.muted)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 10)
                        if course.id != courses.last?.id { Divider().padding(.leading, 98) }
                    }
                }
            }
        }
    }
}

struct ScheduleGrid: View {
    let courses: [Course]
    let weekStart: Date
    private let calendar = Calendar.campus
    private var hours: Range<Int> { CampusMetrics.scheduleStartHour..<CampusMetrics.scheduleEndHour }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text("").frame(width: 54, height: 48)
                        ForEach(0..<7, id: \.self) { offset in
                            let date = calendar.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
                            VStack(spacing: 3) {
                                Text(date.weekdayShortText).font(.caption2.weight(.bold)).foregroundStyle(CampusColors.teal)
                                Text(date.formatted(.dateTime.month().day())).font(.caption.weight(.bold)).foregroundStyle(CampusColors.ink)
                            }
                            .frame(width: CampusMetrics.scheduleDayWidth, height: 48)
                            .background(CampusColors.surface)
                            .overlay(Rectangle().stroke(CampusColors.line, lineWidth: 0.5))
                        }
                    }
                    HStack(alignment: .top, spacing: 0) {
                        VStack(spacing: 0) {
                            ForEach(Array(hours), id: \.self) { hour in
                                Text("\(hour):00")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(CampusColors.muted)
                                    .frame(width: 54, height: CampusMetrics.scheduleHourHeight, alignment: .topTrailing)
                                    .padding(.trailing, 6)
                            }
                        }
                        ForEach(0..<7, id: \.self) { offset in
                            let date = calendar.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
                            let dayCourses = courses.filter { $0.weekday == date.mondayBasedWeekday }.sorted { $0.startMinutes < $1.startMinutes }
                            ZStack(alignment: .topLeading) {
                                VStack(spacing: 0) {
                                    ForEach(Array(hours), id: \.self) { _ in
                                        Rectangle().fill(CampusColors.line.opacity(0.55)).frame(width: CampusMetrics.scheduleDayWidth, height: CampusMetrics.scheduleHourHeight).border(CampusColors.line.opacity(0.35), width: 0.5)
                                    }
                                }
                                ForEach(dayCourses) { course in
                                    CompactCourseCard(course: course)
                                        .frame(width: CampusMetrics.scheduleDayWidth - 8, height: courseGridHeight(for: course), alignment: .topLeading)
                                        .offset(x: 4, y: courseGridOffset(for: course))
                                }
                            }
                            .frame(width: CampusMetrics.scheduleDayWidth, height: CGFloat(hours.count) * CampusMetrics.scheduleHourHeight)
                        }
                    }
                }
            }
        }
    }

    private func courseGridOffset(for course: Course) -> CGFloat {
        CGFloat(course.startMinutes - CampusMetrics.scheduleStartHour * 60) / 60 * CampusMetrics.scheduleHourHeight + 3
    }

    private func courseGridHeight(for course: Course) -> CGFloat {
        max(46, CGFloat(course.durationMinutes) / 60 * CampusMetrics.scheduleHourHeight - 6)
    }
}

struct RemindersView: View {
    @EnvironmentObject private var store: CampusStore
    @State private var showingAdd = false

    var body: some View {
        CampusPage {
            VStack(alignment: .leading, spacing: CampusMetrics.sectionGap) {
                HStack(alignment: .top) {
                    CampusSectionTitle(eyebrow: "轻量提醒", title: "提醒", detail: "把重要时间放到不会忘记的位置。")
                    Spacer()
                    CampusIconButton(symbol: "plus", label: "新增提醒") { showingAdd = true }
                }
                CampusPanel {
                    ForEach(store.reminders.sorted { $0.date < $1.date }) { ReminderRow(reminder: $0) }
                    if store.reminders.isEmpty { EmptyState(symbol: "bell", title: "还没有提醒", detail: "为课程、作业或生活安排加一个提醒。") }
                }
            }
        }
        .sheet(isPresented: $showingAdd) { AddReminderSheet() }
    }
}

struct AcademicView: View {
    @EnvironmentObject private var store: CampusStore

    var body: some View {
        CampusPage {
            VStack(alignment: .leading, spacing: CampusMetrics.sectionGap) {
                CampusHeader(eyebrow: "学习进度", title: "学业", detail: "作业、测验和考试节点集中管理。")
                CampusPanel {
                    HStack(spacing: 16) {
                        CampusStat(value: "\(store.academicItems.count)", label: "全部节点", tint: CampusColors.amber)
                        CampusStat(value: "\(store.academicItems.filter { $0.kind == "考试" }.count)", label: "考试", tint: CampusColors.coral)
                        CampusStat(value: "\(store.academicItems.filter { $0.kind == "作业" }.count)", label: "作业", tint: CampusColors.teal)
                    }
                }
                SectionHeading(title: "学业时间线", detail: "按日期排列")
                CampusPanel {
                    ForEach(store.academicItems.sorted { $0.date < $1.date }) { AcademicRow(item: $0) }
                    if store.academicItems.isEmpty { EmptyState(symbol: "graduationcap", title: "还没有学业节点", detail: "把作业和考试加入你的学习节奏。") }
                }
            }
        }
    }
}

struct TasksView: View {
    @EnvironmentObject private var store: CampusStore
    @State private var showingAdd = false
    @State private var filter = "全部"

    private var filteredTasks: [CampusTask] {
        switch filter {
        case "未完成": return store.tasks.filter { !$0.completed }
        case "已完成": return store.tasks.filter(\.completed)
        default: return store.tasks
        }
    }

    var body: some View {
        CampusPage {
            VStack(alignment: .leading, spacing: CampusMetrics.sectionGap) {
                HStack(alignment: .top) {
                    CampusSectionTitle(eyebrow: "执行清单", title: "任务", detail: "先完成重要的，再处理琐碎的。")
                    Spacer()
                    CampusIconButton(symbol: "plus", label: "新增任务") { showingAdd = true }
                }
                Picker("任务筛选", selection: $filter) {
                    Text("全部").tag("全部")
                    Text("未完成").tag("未完成")
                    Text("已完成").tag("已完成")
                }
                .pickerStyle(.segmented)
                .frame(minHeight: 44)
                CampusPanel {
                    ForEach(filteredTasks) { CampusTaskRow(task: $0) }
                    if filteredTasks.isEmpty { EmptyState(symbol: "checkmark.circle", title: "这里还没有任务", detail: "新增一项小任务，开始推进今天。") }
                }
            }
        }
        .sheet(isPresented: $showingAdd) { AddTaskSheet() }
    }
}

struct CampusView: View {
    @EnvironmentObject private var store: CampusStore

    var body: some View {
        CampusPage {
            VStack(alignment: .leading, spacing: CampusMetrics.sectionGap) {
                CampusHeader(eyebrow: "校园生活", title: "校园", detail: "把学习空间、活动和生活提示放在身边。")
                LazyVStack(spacing: 10) {
                    ForEach(store.campusEvents) { event in
                        CampusPanel {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: event.category == "学习空间" ? "books.vertical.fill" : event.category == "校园活动" ? "person.3.fill" : "fork.knife")
                                    .font(.title3).foregroundStyle(CampusColors.coral).frame(width: 30, height: 30)
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(event.title).font(.subheadline.weight(.bold)).foregroundStyle(CampusColors.ink)
                                        Spacer()
                                        CampusChip(title: event.dateText, tint: CampusColors.amber)
                                    }
                                    Text(event.category).font(.caption.weight(.semibold)).foregroundStyle(CampusColors.teal)
                                    Text(event.detail).font(.caption).foregroundStyle(CampusColors.muted)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct CampusTaskRow: View {
    @EnvironmentObject private var store: CampusStore
    let task: CampusTask

    var body: some View {
        Button { store.toggleTask(task) } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: task.completed ? "checkmark.square.fill" : "square")
                    .font(.title3).foregroundStyle(task.completed ? CampusColors.teal : CampusColors.muted)
                    .frame(width: CampusMetrics.minTouchTarget, height: CampusMetrics.minTouchTarget)
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title).font(.subheadline.weight(.semibold)).foregroundStyle(task.completed ? CampusColors.muted : CampusColors.ink).strikethrough(task.completed).multilineTextAlignment(.leading)
                    HStack(spacing: 8) {
                        CampusChip(title: task.category, tint: CampusColors.muted)
                        if let dueDate = task.dueDate { Text(dueDate.shortDateText).foregroundStyle(CampusColors.muted) }
                        Text(task.priority.rawValue).foregroundStyle(task.priority == .high ? CampusColors.danger : CampusColors.muted)
                    }.font(.caption)
                }
                Spacer(minLength: 0)
            }.contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

struct CampusCourseRow: View {
    let course: Course
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: course.colorHex)).frame(width: 4)
            VStack(alignment: .leading, spacing: 4) {
                Text(course.name).font(.subheadline.weight(.bold)).foregroundStyle(CampusColors.ink)
                Text("\(course.timeText) · \(course.room)").font(.caption).foregroundStyle(CampusColors.muted)
            }
            Spacer(minLength: 8)
            Text(course.teacher).font(.caption).foregroundStyle(CampusColors.muted)
        }.padding(.vertical, 5)
    }
}

struct CompactCourseCard: View {
    let course: Course
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(course.name).font(.caption.weight(.bold)).foregroundStyle(CampusColors.ink).lineLimit(2)
            Text(course.timeText).font(.caption2.monospacedDigit()).foregroundStyle(CampusColors.muted)
            Text(course.room).font(.caption2).foregroundStyle(CampusColors.muted).lineLimit(1)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: course.colorHex).opacity(0.14))
        .overlay(alignment: .leading) { Rectangle().fill(Color(hex: course.colorHex)).frame(width: 3) }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct ReminderRow: View {
    @EnvironmentObject private var store: CampusStore
    let reminder: CampusReminder
    var body: some View {
        Button { store.toggleReminder(reminder) } label: {
            HStack(spacing: 10) {
                Image(systemName: reminder.completed ? "checkmark.circle.fill" : "bell.fill").foregroundStyle(reminder.completed ? CampusColors.teal : CampusColors.coral).frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(reminder.title).font(.subheadline.weight(.semibold)).foregroundStyle(reminder.completed ? CampusColors.muted : CampusColors.ink).strikethrough(reminder.completed)
                    Text("\(reminder.date.formatted(.dateTime.month().day().hour().minute())) · \(reminder.detail)").font(.caption).foregroundStyle(CampusColors.muted)
                }
                Spacer()
            }.padding(.vertical, 6).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

struct AcademicRow: View {
    let item: AcademicItem
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.kind == "考试" ? "pencil.and.outline" : "calendar.badge.clock").foregroundStyle(item.kind == "考试" ? CampusColors.coral : CampusColors.amber).frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 4) {
                HStack { Text(item.title).font(.subheadline.weight(.semibold)).foregroundStyle(CampusColors.ink); Spacer(); CampusChip(title: item.kind, tint: item.kind == "考试" ? CampusColors.coral : CampusColors.amber) }
                Text("\(item.date.shortDateText) · \(item.course)").font(.caption).foregroundStyle(CampusColors.teal)
                Text(item.detail).font(.caption).foregroundStyle(CampusColors.muted)
            }
        }.padding(.vertical, 5)
    }
}

struct SectionHeading: View {
    let title: String
    let detail: String
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.headline.weight(.bold)).foregroundStyle(CampusColors.ink)
            Spacer()
            Text(detail).font(.caption).foregroundStyle(CampusColors.muted)
        }
    }
}

struct EmptyState: View {
    let symbol: String
    let title: String
    let detail: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.title3).foregroundStyle(CampusColors.teal).frame(width: 34, height: 34)
            VStack(alignment: .leading, spacing: 3) { Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(CampusColors.ink); Text(detail).font(.caption).foregroundStyle(CampusColors.muted) }
        }.padding(.vertical, 8)
    }
}

struct CourseImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: CampusStore
    @State private var text = "name,teacher,room,weekday,startHour,startMinute,durationMinutes,colorHex\n高等数学,李老师,A-302,1,8,0,90,167D78"
    @State private var resultText = ""
    @State private var showingFileImporter = false

    var body: some View {
        NavigationStack {
            Form {
                Section("粘贴课程数据") {
                    TextEditor(text: $text).frame(minHeight: 190)
                    Text("支持 JSON 数组，或 CSV：课程名,教师,教室,周几,开始时,开始分,时长分,颜色Hex").font(.caption).foregroundStyle(CampusColors.muted)
                    Button { showingFileImporter = true } label: {
                        Label("从文件选择", systemImage: "doc.badge.arrow.up")
                    }
                }
                if !resultText.isEmpty { Section { Text(resultText).foregroundStyle(CampusColors.teal) } }
            }
            .navigationTitle("导入课表")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("导入") { let count = store.importCourses(from: text); resultText = count > 0 ? "已导入 \(count) 门课程" : "没有识别到有效课程" } }
            }
        }
        .presentationDetents([.medium, .large])
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.json, .commaSeparatedText, .plainText]) { result in
            do {
                let url = try result.get()
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                text = String(decoding: try Data(contentsOf: url), as: UTF8.self)
                resultText = "已读取文件，可以确认导入"
            } catch {
                resultText = "读取文件失败，请检查格式"
            }
        }
    }
}

struct AddTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: CampusStore
    @State private var title = ""
    @State private var category = "学习"
    @State private var priority: TaskPriority = .normal
    @State private var hasDueDate = true
    @State private var dueDate = Date.now

    var body: some View {
        NavigationStack {
            Form {
                TextField("任务名称", text: $title)
                TextField("分类", text: $category)
                Picker("优先级", selection: $priority) { ForEach(TaskPriority.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                Toggle("设置截止时间", isOn: $hasDueDate)
                if hasDueDate { DatePicker("截止日期", selection: $dueDate, displayedComponents: [.date, .hourAndMinute]) }
            }
            .navigationTitle("新增任务")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("添加") { guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }; store.addTask(title: title, dueDate: hasDueDate ? dueDate : nil, priority: priority, category: category); dismiss() } }
            }
        }
        .presentationDetents([.medium])
    }
}

struct AddReminderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: CampusStore
    @State private var title = ""
    @State private var detail = ""
    @State private var date = Date.now

    var body: some View {
        NavigationStack {
            Form {
                TextField("提醒名称", text: $title)
                TextField("补充说明", text: $detail)
                DatePicker("提醒时间", selection: $date)
            }
            .navigationTitle("新增提醒")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("添加") { guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }; store.addReminder(title: title, date: date, detail: detail); dismiss() } }
            }
        }
        .presentationDetents([.medium])
    }
}

private extension Course {
    var startMinutes: Int { startHour * 60 + startMinute }
}

private extension Date {
    var shortDateText: String { formatted(.dateTime.month(.defaultDigits).day(.defaultDigits)) }
    var weekdayText: String { formatted(.dateTime.weekday(.wide)) }
    var weekdayShortText: String { formatted(.dateTime.weekday(.abbreviated)).replacingOccurrences(of: "星期", with: "").replacingOccurrences(of: "周", with: "") }
    var mondayBasedWeekday: Int { (Calendar.current.component(.weekday, from: self) + 5) % 7 + 1 }
    var isToday: Bool { Calendar.current.isDateInToday(self) }
}

private extension Calendar {
    static var campus: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    func mondayStart(for date: Date) -> Date {
        let start = startOfDay(for: date)
        let weekday = component(.weekday, from: start)
        let distance = (weekday + 5) % 7
        return self.date(byAdding: .day, value: -distance, to: start) ?? start
    }
}

