//
//  SQLiteManager.swift
//  Harry
//
//  Created by Nigel Smith on 14/04/2026.
//

import Foundation
import SQLite3
import Combine

final class SQLiteManager: ObservableObject {
    static let shared = SQLiteManager()

    private var db: OpaquePointer?

    private init() {
        openDatabase()
        migrate()
        seedIfNeeded()
    }

    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }

    private func databaseURL() -> URL {
        let fm = FileManager.default
        let appSupport = try! fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let bundleID = Bundle.main.bundleIdentifier ?? "HarryApp"
        let folder = appSupport.appendingPathComponent(bundleID, isDirectory: true)

        if !fm.fileExists(atPath: folder.path) {
            try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        }

        return folder.appendingPathComponent("harry.sqlite")
    }

    private func openDatabase() {
        let url = databaseURL()
        if sqlite3_open(url.path, &db) != SQLITE_OK {
            print("Unable to open database at \(url.path)")
        }
    }

    private func migrate() {
        let version = userVersion()

        if version < 1 {
            execute("""
            CREATE TABLE IF NOT EXISTS course (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE,
                slope INTEGER NOT NULL,
                sss INTEGER NOT NULL
            );
            """)

            execute("""
            CREATE TABLE IF NOT EXISTS course_hole (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                course_id INTEGER NOT NULL,
                hole_number INTEGER NOT NULL,
                par INTEGER NOT NULL,
                handicap INTEGER NOT NULL,
                FOREIGN KEY(course_id) REFERENCES course(id)
            );
            """)

            setUserVersion(1)
        }

        if version < 2 {
            execute("""
            CREATE TABLE IF NOT EXISTS played_round (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                player_name TEXT NOT NULL,
                competition_name TEXT NOT NULL,
                course_id INTEGER NOT NULL,
                course_name TEXT NOT NULL,
                handicap REAL NOT NULL,
                slope INTEGER NOT NULL,
                sss INTEGER NOT NULL,
                strokes_received INTEGER NOT NULL,
                played_at REAL NOT NULL,
                FOREIGN KEY(course_id) REFERENCES course(id)
            );
            """)

            execute("""
            CREATE TABLE IF NOT EXISTS played_round_hole (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                round_id INTEGER NOT NULL,
                hole_number INTEGER NOT NULL,
                par INTEGER NOT NULL,
                handicap INTEGER NOT NULL,
                strokes INTEGER NOT NULL,
                FOREIGN KEY(round_id) REFERENCES played_round(id)
            );
            """)

            setUserVersion(2)
        }
    }

    private func userVersion() -> Int {
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, "PRAGMA user_version;", -1, &stmt, nil) == SQLITE_OK else {
            return 0
        }

        if sqlite3_step(stmt) == SQLITE_ROW {
            return Int(sqlite3_column_int(stmt, 0))
        }

        return 0
    }

    private func setUserVersion(_ version: Int) {
        execute("PRAGMA user_version = \(version);")
    }

    private func execute(_ sql: String) {
        var errorMessage: UnsafeMutablePointer<Int8>?

        if sqlite3_exec(db, sql, nil, nil, &errorMessage) != SQLITE_OK {
            if let errorMessage {
                print("SQLite error: \(String(cString: errorMessage))")
            }
        }
    }

    func fetchCourses() -> [Course] {
        let sql = "SELECT id, name, slope, sss FROM course ORDER BY name;"
        var stmt: OpaquePointer?
        var courses: [Course] = []

        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            return []
        }

        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let name = String(cString: sqlite3_column_text(stmt, 1))
            let slope = Int(sqlite3_column_int(stmt, 2))
            let sss = Int(sqlite3_column_int(stmt, 3))
            let holes = fetchHoles(for: id)

            courses.append(Course(id: id, name: name, slope: slope, sss: sss, holes: holes))
        }

        return courses
    }

    func fetchHoles(for courseId: Int64) -> [Hole] {
        let sql = """
        SELECT hole_number, par, handicap
        FROM course_hole
        WHERE course_id = ?
        ORDER BY hole_number;
        """

        var stmt: OpaquePointer?
        var holes: [Hole] = []

        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            return []
        }

        sqlite3_bind_int64(stmt, 1, courseId)

        while sqlite3_step(stmt) == SQLITE_ROW {
            let number = Int(sqlite3_column_int(stmt, 0))
            let par = Int(sqlite3_column_int(stmt, 1))
            let handicap = Int(sqlite3_column_int(stmt, 2))
            holes.append(Hole(number: number, par: par, handicap: handicap, strokes: par))
        }

        return holes
    }

    @discardableResult
    func insertCourse(name: String, slope: Int, sss: Int, holes: [Hole]) -> Bool {
        let insertSQL = "INSERT INTO course (name, slope, sss) VALUES (?, ?, ?);"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) == SQLITE_OK else {
            return false
        }

        sqlite3_bind_text(stmt, 1, (name as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 2, Int32(slope))
        sqlite3_bind_int(stmt, 3, Int32(sss))

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            sqlite3_finalize(stmt)
            return false
        }

        sqlite3_finalize(stmt)
        let courseId = sqlite3_last_insert_rowid(db)

        let holeSQL = """
        INSERT INTO course_hole (course_id, hole_number, par, handicap)
        VALUES (?, ?, ?, ?);
        """

        for hole in holes {
            var holeStmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, holeSQL, -1, &holeStmt, nil) == SQLITE_OK else {
                return false
            }

            sqlite3_bind_int64(holeStmt, 1, courseId)
            sqlite3_bind_int(holeStmt, 2, Int32(hole.number))
            sqlite3_bind_int(holeStmt, 3, Int32(hole.par))
            sqlite3_bind_int(holeStmt, 4, Int32(hole.handicap))

            guard sqlite3_step(holeStmt) == SQLITE_DONE else {
                sqlite3_finalize(holeStmt)
                return false
            }

            sqlite3_finalize(holeStmt)
        }

        return true
    }

    @discardableResult
    func insertPlayedRound(
        playerName: String,
        competitionName: String,
        courseId: Int64,
        courseName: String,
        handicap: Double,
        slope: Int,
        sss: Int,
        strokesReceived: Int,
        holes: [Hole]
    ) -> Bool {
        let roundSQL = """
        INSERT INTO played_round (
            player_name, competition_name, course_id, course_name,
            handicap, slope, sss, strokes_received, played_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, roundSQL, -1, &stmt, nil) == SQLITE_OK else {
            return false
        }

        sqlite3_bind_text(stmt, 1, (playerName as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (competitionName as NSString).utf8String, -1, nil)
        sqlite3_bind_int64(stmt, 3, courseId)
        sqlite3_bind_text(stmt, 4, (courseName as NSString).utf8String, -1, nil)
        sqlite3_bind_double(stmt, 5, handicap)
        sqlite3_bind_int(stmt, 6, Int32(slope))
        sqlite3_bind_int(stmt, 7, Int32(sss))
        sqlite3_bind_int(stmt, 8, Int32(strokesReceived))
        sqlite3_bind_double(stmt, 9, Date().timeIntervalSince1970)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            sqlite3_finalize(stmt)
            return false
        }

        sqlite3_finalize(stmt)
        let roundId = sqlite3_last_insert_rowid(db)

        let holeSQL = """
        INSERT INTO played_round_hole (
            round_id, hole_number, par, handicap, strokes
        )
        VALUES (?, ?, ?, ?, ?);
        """

        for hole in holes {
            var holeStmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, holeSQL, -1, &holeStmt, nil) == SQLITE_OK else {
                return false
            }

            sqlite3_bind_int64(holeStmt, 1, roundId)
            sqlite3_bind_int(holeStmt, 2, Int32(hole.number))
            sqlite3_bind_int(holeStmt, 3, Int32(hole.par))
            sqlite3_bind_int(holeStmt, 4, Int32(hole.handicap))
            sqlite3_bind_int(holeStmt, 5, Int32(hole.strokes))

            guard sqlite3_step(holeStmt) == SQLITE_DONE else {
                sqlite3_finalize(holeStmt)
                return false
            }

            sqlite3_finalize(holeStmt)
        }

        return true
    }

    func fetchPlayedRounds(limit: Int = 50) -> [PlayedRound] {
        let sql = """
        SELECT id, player_name, competition_name, course_id, course_name,
               handicap, slope, sss, strokes_received, played_at
        FROM played_round
        ORDER BY played_at DESC
        LIMIT ?;
        """

        var stmt: OpaquePointer?
        var rounds: [PlayedRound] = []

        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            return []
        }

        sqlite3_bind_int(stmt, 1, Int32(limit))

        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let playerName = String(cString: sqlite3_column_text(stmt, 1))
            let competitionName = String(cString: sqlite3_column_text(stmt, 2))
            let courseId = sqlite3_column_int64(stmt, 3)
            let courseName = String(cString: sqlite3_column_text(stmt, 4))
            let handicap = sqlite3_column_double(stmt, 5)
            let slope = Int(sqlite3_column_int(stmt, 6))
            let sss = Int(sqlite3_column_int(stmt, 7))
            let strokesReceived = Int(sqlite3_column_int(stmt, 8))
            let playedAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 9))
            let holes = fetchPlayedRoundHoles(roundId: id)

            rounds.append(
                PlayedRound(
                    id: id,
                    playerName: playerName,
                    competitionName: competitionName,
                    courseId: courseId,
                    courseName: courseName,
                    handicap: handicap,
                    slope: slope,
                    sss: sss,
                    strokesReceived: strokesReceived,
                    playedAt: playedAt,
                    holes: holes
                )
            )
        }

        return rounds
    }

    private func fetchPlayedRoundHoles(roundId: Int64) -> [Hole] {
        let sql = """
        SELECT hole_number, par, handicap, strokes
        FROM played_round_hole
        WHERE round_id = ?
        ORDER BY hole_number;
        """

        var stmt: OpaquePointer?
        var holes: [Hole] = []

        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            return []
        }

        sqlite3_bind_int64(stmt, 1, roundId)

        while sqlite3_step(stmt) == SQLITE_ROW {
            holes.append(
                Hole(
                    number: Int(sqlite3_column_int(stmt, 0)),
                    par: Int(sqlite3_column_int(stmt, 1)),
                    handicap: Int(sqlite3_column_int(stmt, 2)),
                    strokes: Int(sqlite3_column_int(stmt, 3))
                )
            )
        }

        return holes
    }

    private func seedIfNeeded() {
        guard fetchCourses().isEmpty else { return }
        _ = insertCourse(name: "Default Course", slope: 113, sss: 72, holes: [Hole].defaultHoles())
    }
}
