import SwiftUI

struct MonthDay: Identifiable, Hashable {
    let id: Int
    let day: Int?
    let isToday: Bool
    let eventColor: Color?
}
