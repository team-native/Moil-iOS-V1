import SwiftUI
import Combine

/// Keeps loaded month events around so re-entering the calendar tab paints immediately
/// instead of showing an empty grid until the request comes back.
@MainActor
final class MoilEventStore: ObservableObject {
    @Published private(set) var monthlyEvents: [String: [MoilRemoteEvent]] = [:]

    func events(groupId: String?, month: String) -> [MoilRemoteEvent] {
        guard let groupId else { return [] }
        return monthlyEvents[key(groupId, month)] ?? []
    }

    func hasLoaded(groupId: String?, month: String) -> Bool {
        guard let groupId else { return false }
        return monthlyEvents[key(groupId, month)] != nil
    }

    func load(groupId: String, month: String, using service: MoilAPIService) async throws {
        let monthNumber = Int(month.split(separator: "-").last ?? "") ?? 0
        monthlyEvents[key(groupId, month)] = try await service.events(groupId: groupId, month: monthNumber)
    }

    func invalidate(groupId: String) {
        monthlyEvents = monthlyEvents.filter { !$0.key.hasPrefix("\(groupId)|") }
    }

    func reset() {
        monthlyEvents = [:]
    }

    private func key(_ groupId: String, _ month: String) -> String { "\(groupId)|\(month)" }
}
