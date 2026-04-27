import Foundation

struct Hole: Identifiable, Hashable, Codable {
    let id = UUID()
    let number: Int
    var par: Int
    var handicap: Int
    var strokes: Int
    var strokesGiven: Int
}

struct Course: Identifiable, Hashable {
    let id: Int64
    var name: String
    var slope: Int
    var sss: Double
    var par: Int
    var holes: [Hole]
}

struct PlayedRound: Identifiable, Hashable, Codable {
    let id: Int64
    let playerName: String
    let competitionName: String
    let courseId: Int64
    let courseName: String
    let handicap: Double
    let slope: Int
    let sss: Double
    let par: Int
    let strokesReceived: Int
    let playedAt: Date
    var updatedAt: Date
    var holes: [Hole]
}

extension Array where Element == Hole {
    static func defaultHoles() -> [Hole] {
        (1...18).map { holeNumber in
            Hole(
                number: holeNumber,
                par: holeNumber <= 2 ? 5 : 4,
                handicap: holeNumber,
                strokes: holeNumber <= 2 ? 5 : 4,
                strokesGiven: 0
            )
        }
    }
}
