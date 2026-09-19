import SwiftUI

struct ScheduleItem: Identifiable, Hashable {
    let id: String
    let time: String
    let title: String
    let owner: FamilyMember
}
