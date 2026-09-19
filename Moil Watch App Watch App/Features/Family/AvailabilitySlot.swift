import SwiftUI

/// 백엔드가 실제 "가족 모두 가능한 시간" API를 제공하면 그 결과로 채워질 모델입니다.
/// 지금은 화면 구조만 갖추고 데이터 연결은 하지 않습니다.
struct AvailabilitySlot: Identifiable, Hashable {
    let id: String
    let timeRange: String
    let summary: String
    let indicatorColor: Color
}
