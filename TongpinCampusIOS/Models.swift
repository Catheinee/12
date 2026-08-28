import Foundation

enum CampusModule: String, CaseIterable, Identifiable {
    case today = "今日"
    case plan = "计划"
    case schedule = "课表"
    case reminders = "提醒"
    case academic = "学业"
    case tasks = "任务"
    case campus = "校园"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .today: return "sun.max"
        case .plan: return "calendar"
        case .schedule: return "tablecells"
        case .reminders: return "bell"
        case .academic: return "graduationcap"
        case .tasks: return "checklist"
        case .campus: return "building.2"
        }
    }
}

enum TaskPriority: String, Codable, CaseIterable {
    case low = "低"
    case normal = "普通"
    case high = "重要"
}

enum ScheduleDisplayMode: String, CaseIterable, Identifiable {
    case timeline = "时间轴"
    case grid = "周网格"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .timeline: return "list.bullet.rectangle"
        case .grid: return "square.grid.2x2"
        }
    }
}

struct Course: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var teacher: String
    var room: String
    var weekday: Int
    var startHour: Int
    var startMinute: Int
    var durationMinutes: Int
    var colorHex: String

    var startDateComponents: DateComponents {
        DateComponents(hour: startHour, minute: startMinute)
    }

    var timeText: String {
        let start = String(format: "%02d:%02d", startHour, startMinute)
        let endMinutes = startHour * 60 + startMinute + durationMinutes
        let end = String(format: "%02d:%02d", endMinutes / 60, endMinutes % 60)
        return "\(start)-\(end)"
    }
}

struct CampusTask: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String
    var dueDate: Date?
    var priority: TaskPriority
    var completed: Bool
    var category: String
}

struct CampusReminder: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String
    var date: Date
    var detail: String
    var completed: Bool
}

struct AcademicItem: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String
    var date: Date
    var course: String
    var kind: String
    var detail: String
}

struct CampusEvent: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String
    var category: String
    var detail: String
    var dateText: String
}

struct CampusSnapshot: Codable {
    var tasks: [CampusTask]
    var reminders: [CampusReminder]
    var courses: [Course]
    var academicItems: [AcademicItem]
    var campusEvents: [CampusEvent]
}
