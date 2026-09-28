import SwiftUI

struct FamilyMember: Identifiable, Hashable {
    let id: String
    let initial: String
    let name: String
    let color: Color
    var isMe = false

    init(id: String, initial: String, name: String, color: Color, isMe: Bool = false) {
        self.id = id
        self.initial = initial
        self.name = name
        self.color = color
        self.isMe = isMe
    }

    init(remote: MoilRemoteMember) {
        id = remote.id
        name = remote.nickname
        initial = String(remote.nickname.prefix(1))
        color = MemberColorPalette.color(for: remote.colorId)
        isMe = remote.isMe
    }
}

/// 서버 연동 전까지 화면을 채우는 표본 데이터입니다.
enum MoilWatchSampleData {
    static let members: [FamilyMember] = [
        FamilyMember(id: "mom", initial: "엄", name: "엄마", color: Color("MemberRed")),
        FamilyMember(id: "dad", initial: "아", name: "아빠", color: Color("MemberBlue")),
        FamilyMember(id: "me", initial: "나", name: "나", color: Color("MemberGreen"), isMe: true),
        FamilyMember(id: "sibling", initial: "동", name: "동생", color: Color("MemberOrange")),
    ]
}
