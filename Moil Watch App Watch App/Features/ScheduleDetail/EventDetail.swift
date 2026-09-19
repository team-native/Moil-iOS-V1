import SwiftUI

struct EventDetail: Identifiable, Hashable {
    let id: String
    let owner: FamilyMember
    let title: String
    let dateLabel: String
    let timeLocationLabel: String
    let attendeeCountLabel: String
    let attendees: [FamilyMember]
    let attendingSummary: String
}
