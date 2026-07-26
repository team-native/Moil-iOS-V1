import SwiftUI

struct MoilGroup: Identifiable {
    let id: UUID
    var name: String
    var color: Color

    init(id: UUID = UUID(), name: String, color: Color) {
        self.id = id
        self.name = name
        self.color = color
    }
}

final class MoilGroupStore: ObservableObject {
    @Published private(set) var groups: [MoilGroup] = [
        MoilGroup(name: "우리 가족", color: MoilAvatarColor.blue),
        MoilGroup(name: "대학 동기", color: MoilAvatarColor.green),
        MoilGroup(name: "회사 팀", color: MoilAvatarColor.green)
    ]
    @Published var selectedGroupName = "우리 가족"

    func createGroup(name: String, color: Color) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let group = MoilGroup(name: trimmedName, color: color)
        groups.append(group)
        selectedGroupName = group.name
    }

    func joinGroup(name: String, color: Color) {
        if !groups.contains(where: { $0.name == name }) {
            groups.append(MoilGroup(name: name, color: color))
        }
        selectedGroupName = name
    }

    func selectGroup(_ name: String) {
        guard groups.contains(where: { $0.name == name }) else { return }
        selectedGroupName = name
    }
}
