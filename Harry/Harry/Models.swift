import Foundation

struct Hole: Identifiable, Hashable {
    let id = UUID()
    let number: Int
    var par: Int
    var handicap: Int
    var strokes: Int
}

struct Course: Identifiable, Hashable {
    let id: Int64
    var name: String
    var slope: Int
    var sss: Int
    var holes: [Hole]
}

struct PlayedRound: Identifiable, Hashable {
    let id: Int64
    let playerName: String
    let competitionName: String
    let courseId: Int64
    let courseName: String
    let handicap: Double
    let slope: Int
    let sss: Int
    let strokesReceived: Int
    let playedAt: Date
    let holes: [Hole]
}

extension Array where Element == Hole {
    static func defaultHoles() -> [Hole] {
        (1...18).map { holeNumber in
            Hole(
                number: holeNumber,
                par: holeNumber <= 2 ? 5 : 4,
                handicap: holeNumber,
                strokes: holeNumber <= 2 ? 5 : 4
            )
        }
    }
}
