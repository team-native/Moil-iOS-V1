import SwiftUI

struct AvailabilitySlot: Identifiable, Hashable {
    let id: String
    let timeRange: String
    let summary: String
    let indicatorColor: Color
}
