import Combine
import Foundation

final class CampusStore: ObservableObject {
    @Published var tasks: [CampusTask]
    @Published var reminders: [CampusReminder]
    @Published var courses: [Course]
    @Published var academicItems: [AcademicItem]
    @Published var campusEvents: [CampusEvent]

    private let storageKey = "tongpin-campus-ios-snapshot-v1"
    private let calendar = Calendar.current

    private struct CourseImportRow: Decodable {
        var name: String
        var teacher: String = ""
        var room: String = ""
        var weekday: Int
        var startHour: Int
        var startMinute: Int = 0
        var durationMinutes: Int = 90
        var colorHex: String = "167D78"

        enum CodingKeys: String, CodingKey {
            case name, teacher, room, weekday, startHour, startMinute, durationMinutes, colorHex
        }

        init(name: String, teacher: String = "", room: String = "", weekday: Int, startHour: Int, startMinute: Int = 0, durationMinutes: Int = 90, colorHex: String = "167D78") {
            self.name = name
            self.teacher = teacher
            self.room = room
            self.weekday = weekday
            self.startHour = startHour
            self.startMinute = startMinute
            self.durationMinutes = durationMinutes
            self.colorHex = colorHex
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            teacher = try container.decodeIfPresent(String.self, forKey: .teacher) ?? ""
            room = try container.decodeIfPresent(String.self, forKey: .room) ?? ""
            weekday = try container.decode(Int.self, forKey: .weekday)
            startHour = try container.decode(Int.self, forKey: .startHour)
            startMinute = try container.decodeIfPresent(Int.self, forKey: .startMinute) ?? 0
            durationMinutes = try container.decodeIfPresent(Int.self, forKey: .durationMinutes) ?? 90
            colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex) ?? "167D78"
        }
    }

    private struct CourseImportEnvelope: Decodable {
        var courses: [CourseImportRow]
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let snapshot = try? JSONDecoder().decode(CampusSnapshot.self, from: data) {
            tasks = snapshot.tasks
            reminders = snapshot.reminders
            courses = snapshot.courses
            academicItems = snapshot.academicItems
            campusEvents = snapshot.campusEvents
        } else {
            tasks = []
            reminders = []
            courses = []
            academicItems = []
            campusEvents = []
            seed()
        }
    }

    var pendingTaskCount: Int { tasks.filter { !$0.completed }.count }
    var upcomingAcademicCount: Int {
        academicItems.filter { $0.date >= calendar.startOfDay(for: Date()) }.count
    }

    func toggleTask(_ task: CampusTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].completed.toggle()
        persist()
    }

    func toggleReminder(_ reminder: CampusReminder) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[index].completed.toggle()
        persist()
    }

    func addTask(title: String, dueDate: Date?, priority: TaskPriority, category: String) {
        tasks.insert(CampusTask(title: title, dueDate: dueDate, priority: priority, completed: false, category: category), at: 0)
        persist()
    }

    func addReminder(title: String, date: Date, detail: String) {
        reminders.insert(CampusReminder(title: title, date: date, detail: detail, completed: false), at: 0)
        persist()
    }

    func addCourse(name: String, teacher: String, room: String, weekday: Int, startHour: Int, startMinute: Int, durationMinutes: Int, colorHex: String) {
        courses.append(Course(name: name, teacher: teacher, room: room, weekday: weekday, startHour: startHour, startMinute: startMinute, durationMinutes: durationMinutes, colorHex: colorHex))
        persist()
    }

    @discardableResult
    func importCourses(from text: String) -> Int {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }

        var rows: [CourseImportRow] = []
        if let data = trimmed.data(using: .utf8) {
            let decoder = JSONDecoder()
            if let jsonRows = try? decoder.decode([CourseImportRow].self, from: data) {
                rows = jsonRows
            } else if let envelope = try? decoder.decode(CourseImportEnvelope.self, from: data) {
                rows = envelope.courses
            }
        }

        if rows.isEmpty {
            let lines = trimmed.split(whereSeparator: \.isNewline).map(String.init)
            let hasHeader = lines.first.map { line in
                let lower = line.lowercased()
                return lower.contains("name") && lower.contains("weekday")
            } ?? false
            let dataLines = hasHeader ? lines.dropFirst() : ArraySlice(lines)
            rows = dataLines.compactMap { line in
                let values = line.split(separator: ",", omittingEmptySubsequences: false).map { String($0).trimmingCharacters(in: .whitespaces) }
                guard values.count >= 5,
                      let weekday = Int(values[3]),
                      let startHour = Int(values[4]) else { return nil }
                return CourseImportRow(
                    name: values[0],
                    teacher: values[safe: 1] ?? "",
                    room: values[safe: 2] ?? "",
                    weekday: weekday,
                    startHour: startHour,
                    startMinute: Int(values[safe: 5] ?? "0") ?? 0,
                    durationMinutes: Int(values[safe: 6] ?? "90") ?? 90,
                    colorHex: values[safe: 7] ?? "167D78"
                )
            }
        }

        let validRows = rows.filter { (1...7).contains($0.weekday) && (0...23).contains($0.startHour) && (0...59).contains($0.startMinute) && $0.durationMinutes > 0 }
        courses.append(contentsOf: validRows.map {
            Course(name: $0.name, teacher: $0.teacher, room: $0.room, weekday: $0.weekday, startHour: $0.startHour, startMinute: $0.startMinute, durationMinutes: $0.durationMinutes, colorHex: $0.colorHex)
        })
        if !validRows.isEmpty { persist() }
        return validRows.count
    }

    func snapshotData() -> Data? {
        let snapshot = CampusSnapshot(tasks: tasks, reminders: reminders, courses: courses, academicItems: academicItems, campusEvents: campusEvents)
        return try? JSONEncoder().encode(snapshot)
    }

    private func persist() {
        guard let data = snapshotData() else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func seed() {
        let today = calendar.startOfDay(for: Date())
        let monday = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        courses = [
            Course(name: "高等数学", teacher: "李老师", room: "A-302", weekday: 1, startHour: 8, startMinute: 0, durationMinutes: 90, colorHex: "167D78"),
            Course(name: "大学英语", teacher: "王老师", room: "B-206", weekday: 2, startHour: 10, startMinute: 0, durationMinutes: 90, colorHex: "D97A54"),
            Course(name: "数据结构", teacher: "周老师", room: "实验楼 204", weekday: 3, startHour: 14, startMinute: 0, durationMinutes: 120, colorHex: "6D7FB3"),
            Course(name: "体育", teacher: "陈老师", room: "东操场", weekday: 4, startHour: 16, startMinute: 0, durationMinutes: 90, colorHex: "B3824D"),
            Course(name: "专业导论", teacher: "赵老师", room: "C-108", weekday: 5, startHour: 10, startMinute: 0, durationMinutes: 90, colorHex: "9C6E9A")
        ]
        tasks = [
            CampusTask(title: "整理高等数学课堂笔记", dueDate: calendar.date(byAdding: .day, value: 1, to: today), priority: .high, completed: false, category: "学习"),
            CampusTask(title: "提交英语口语作业", dueDate: calendar.date(byAdding: .day, value: 2, to: today), priority: .normal, completed: false, category: "课程"),
            CampusTask(title: "预约图书馆自习座位", dueDate: today, priority: .low, completed: true, category: "生活")
        ]
        reminders = [
            CampusReminder(title: "早八提醒", date: calendar.date(byAdding: .day, value: 1, to: monday) ?? today, detail: "高等数学 · A-302", completed: false),
            CampusReminder(title: "英语作业截止", date: calendar.date(byAdding: .day, value: 2, to: today) ?? today, detail: "大学英语", completed: false),
            CampusReminder(title: "校园卡充值", date: calendar.date(byAdding: .day, value: 4, to: today) ?? today, detail: "生活安排", completed: false)
        ]
        academicItems = [
            AcademicItem(title: "英语口语作业", date: calendar.date(byAdding: .day, value: 2, to: today) ?? today, course: "大学英语", kind: "作业", detail: "提交录音与文字稿"),
            AcademicItem(title: "数据结构阶段测验", date: calendar.date(byAdding: .day, value: 6, to: today) ?? today, course: "数据结构", kind: "测验", detail: "树与图基础"),
            AcademicItem(title: "期中考试周", date: calendar.date(byAdding: .day, value: 28, to: today) ?? today, course: "全学科", kind: "考试", detail: "请提前安排复习节奏")
        ]
        campusEvents = [
            CampusEvent(title: "图书馆开放时间", category: "学习空间", detail: "工作日 07:30-22:30 · 周末 09:00-22:00", dateText: "长期有效"),
            CampusEvent(title: "本周校园招聘宣讲", category: "校园活动", detail: "南区报告厅 · 关注现场签到安排", dateText: "周四 18:30"),
            CampusEvent(title: "食堂晚餐高峰", category: "生活服务", detail: "17:30-18:30 人流较多，可错峰用餐", dateText: "今日提示")
        ]
        persist()
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
