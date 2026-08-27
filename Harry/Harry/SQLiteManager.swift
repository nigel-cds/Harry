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
                sss REAL NOT NULL
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
        
        if version < 3 {
            execute("""
            ALTER TABLE played_round
            ADD COLUMN updated_at REAL;
            """)
            
            execute("""
            UPDATE played_round
            SET updated_at = played_at
            WHERE updated_at IS NULL;
            """)
            
            setUserVersion(3)
        }
        
        if version < 4 {
            
            execute("""
            ALTER TABLE course
            ADD COLUMN par INTEGER NOT NULL DEFAULT 72;
            """)
            
            setUserVersion(4)
            
        }
        
        if version < 5 {
            // 1. Rename old table
            execute("""
            ALTER TABLE course RENAME TO course_old;
            """)
            
            // 2. Create new table with correct schema
            execute("""
            CREATE TABLE course (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE,
                slope INTEGER NOT NULL,
                sss REAL NOT NULL,
                par INTEGER NOT NULL
            );
            """)
            
            // 3. Copy data (INTEGER → REAL is automatic in SQLite)
            execute("""
            INSERT INTO course (id, name, slope, sss, par)
            SELECT id, name, slope, CAST(sss AS REAL), par
            FROM course_old;
            """)
            
            // 4. Drop old table
            execute("""
            DROP TABLE course_old;
            """)
            
            setUserVersion(5)
        }
        
        if version < 6 {
            execute("""
            ALTER TABLE played_round
            ADD COLUMN par INTEGER NOT NULL DEFAULT 72;
            """)
            
            setUserVersion(6)
        }
        
        if version < 7 {
            execute("""
            ALTER TABLE played_round_hole
            ADD COLUMN strokes_given INTEGER NOT NULL DEFAULT 0;
            """)
            
            execute("""
            UPDATE played_round_hole
            SET strokes_given = (
                SELECT
                    (pr.strokes_received / 18) +
                    CASE
                        WHEN played_round_hole.handicap <= (pr.strokes_received % 18) THEN 1
                        ELSE 0
                    END
                FROM played_round pr
                WHERE pr.id = played_round_hole.round_id
            );
            """)
            
            setUserVersion(7)
        }
        
        if version < 9 {
            execute("""
            ALTER TABLE played_round_hole
            ADD COLUMN is_played INTEGER NOT NULL DEFAULT 1;
            """)
            
            setUserVersion(9)
        }
        
        if version < 10 {
            execute("""
            ALTER TABLE played_round_hole
            DROP COLUMN is_played;
            """)
            
            execute("""
            ALTER TABLE played_round_hole
            ADD COLUMN is_played INTEGER NOT NULL DEFAULT 0;
            """)
            
            setUserVersion(10)
        }

        if version < 11 {
            execute("""
            UPDATE played_round_hole
            SET is_played = 1;
            """)
            
            setUserVersion(11)
        }
        
        if version < 12 {
            
            execute("""
            delete from played_round_hole where round_id IN (
                select id from played_round where course_name not in ('Le Home'));
            delete from played_round where course_name not in ('Le Home');
            delete from course_hole where course_id IN (
                select id from course where name not in ('Le Home'));
            delete from course where name not in ('Le Home');
            """)

            execute("""
            INSERT INTO course
            (name, slope, sss, par)
            VALUES('Sancti Petri B', 123, 69.3, 72);

            INSERT INTO course
            (name, slope, sss, par)
            VALUES('Golf Campano', 123, 69.3, 72);

            INSERT INTO course
            (name, slope, sss, par)
            VALUES('Golf Montenmedio', 132, 71.2, 72);

            INSERT INTO course
            (name, slope, sss, par)
            VALUES('Sancti Petri A', 123, 69.3, 72);
            """)
            
            execute("""
            INSERT INTO course_hole
            (course_id, hole_number, par, handicap)
            VALUES
            (14, 1, 4, 2),
            (14, 2, 4, 4),
            (14, 3, 5, 10),
            (14, 4, 3, 14),
            (14, 5, 5, 6),
            (14, 6, 3, 16),
            (14, 7, 4, 12),
            (14, 8, 3, 18),
            (14, 9, 5, 8),
            (14, 10, 3, 17),
            (14, 11, 5, 3),
            (14, 12, 3, 15),
            (14, 13, 5, 7),
            (14, 14, 4, 1),
            (14, 15, 4, 5),
            (14, 16, 3, 11),
            (14, 17, 5, 13),
            (14, 18, 4, 9);

            INSERT INTO course_hole
            (course_id, hole_number, par, handicap)
            VALUES
            (15, 1, 4, 5),
            (15, 2, 5, 11),
            (15, 3, 3, 7),
            (15, 4, 4, 15),
            (15, 5, 4, 3),
            (15, 6, 5, 13),
            (15, 7, 4, 9),
            (15, 8, 3, 17),
            (15, 9, 4, 1),
            (15, 10, 4, 4),
            (15, 11, 4, 14),
            (15, 12, 5, 6),
            (15, 13, 3, 12),
            (15, 14, 5, 2),
            (15, 15, 4, 10),
            (15, 16, 4, 18),
            (15, 17, 3, 16),
            (15, 18, 4, 8);

            INSERT INTO course_hole
            (course_id, hole_number, par, handicap)
            VALUES
            (16, 1, 4, 16),
            (16, 2, 4, 12),
            (16, 3, 5, 7),
            (16, 4, 4, 10),
            (16, 5, 5, 2),
            (16, 6, 4, 15),
            (16, 7, 3, 18),
            (16, 8, 4, 14),
            (16, 9, 4, 11),
            (16, 10, 4, 4),
            (16, 11, 5, 5),
            (16, 12, 5, 3),
            (16, 13, 3, 8),
            (16, 14, 4, 1),
            (16, 15, 4, 17),
            (16, 16, 3, 9),
            (16, 17, 4, 6),
            (16, 18, 3, 13);

            INSERT INTO course_hole
            (course_id, hole_number, par, handicap)
            VALUES
            (17, 1, 4, 2),
            (17, 2, 5, 6),
            (17, 3, 4, 8),
            (17, 4, 4, 18),
            (17, 5, 4, 4),
            (17, 6, 4, 14),
            (17, 7, 3, 12),
            (17, 8, 5, 10),
            (17, 9, 3, 16),
            (17, 10, 4, 3),
            (17, 11, 5, 11),
            (17, 12, 4, 15),
            (17, 13, 5, 7),
            (17, 14, 4, 13),
            (17, 15, 3, 17),
            (17, 16, 4, 5),
            (17, 17, 4, 1),
            (17, 18, 3, 9);
            """)

            setUserVersion(12)
        }
        
        if version < 13 {
            
            execute("""
                UPDATE course_hole SET course_id = 21 WHERE course_id = 17;

                UPDATE course_hole SET course_id = 20 WHERE course_id = 16;

                UPDATE course_hole SET course_id = 19 WHERE course_id = 15;

                UPDATE course_hole SET course_id = 18 WHERE course_id = 14;

            """)

            setUserVersion(13)

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
        let sql = "SELECT id, name, slope, sss, par FROM course ORDER BY name;"
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
            let sss = Double(sqlite3_column_double(stmt, 3))
            let par = Int(sqlite3_column_int(stmt, 4))
            let holes = fetchHoles(for: id)

            courses.append(Course(id: id, name: name, slope: slope, sss: sss, par: par, holes: holes))
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
            holes.append(
                Hole(
                    number: number,
                    par: par,
                    handicap: handicap,
                    strokes: par,
                    strokesGiven: 0
                )
            )
        }

        return holes
    }

    @discardableResult
    func updateCourse(
        id: Int64,
        name: String,
        slope: Int,
        sss: Double,
        par: Int,
        holes: [Hole]
    ) -> Bool {
        let updateSQL = "UPDATE course SET name = ?, slope = ?, sss = ?, par = ? WHERE id = ? ;"
        
        var statementU: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, updateSQL, -1, &statementU, nil) == SQLITE_OK else {
            print("Prepare failed:", String(cString: sqlite3_errmsg(db)))
            return false
        }

        defer { sqlite3_finalize(statementU) }

        sqlite3_bind_text(statementU, 1, (name as NSString).utf8String, -1, nil)
        sqlite3_bind_int(statementU, 2, Int32(slope))
        sqlite3_bind_double(statementU, 3, sss)
        sqlite3_bind_int(statementU, 4, Int32(par))
        sqlite3_bind_int64(statementU, 5, Int64(id))

        guard sqlite3_step(statementU) == SQLITE_DONE else {
            print("Update failed:", String(cString: sqlite3_errmsg(db)))
            return false
        }

        // delete existing holes for course id
        let deleteSQL = "DELETE from course_hole WHERE course_id = ?;"
        
        var statementD: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, deleteSQL, -1, &statementD, nil) == SQLITE_OK else {
            print("Prepare failed:", String(cString: sqlite3_errmsg(db)))
            return false
        }

        defer { sqlite3_finalize(statementD) }

        sqlite3_bind_int64(statementD, 1, Int64(id))

        guard sqlite3_step(statementD) == SQLITE_DONE else {
            print("Delete failed:", String(cString: sqlite3_errmsg(db)))
            return false
        }

        // insert updated holes
        let holeSQL = """
        INSERT INTO course_hole (course_id, hole_number, par, handicap)
        VALUES (?, ?, ?, ?);
        """

        for hole in holes {
            var holeStmt: OpaquePointer?

            guard sqlite3_prepare_v2(db, holeSQL, -1, &holeStmt, nil) == SQLITE_OK else {
                print("Hole prepare failed:", String(cString: sqlite3_errmsg(db)))
                return false
            }

            defer { sqlite3_finalize(holeStmt) }

            sqlite3_bind_int64(holeStmt, 1, id)
            sqlite3_bind_int(holeStmt, 2, Int32(hole.number))
            sqlite3_bind_int(holeStmt, 3, Int32(hole.par))
            sqlite3_bind_int(holeStmt, 4, Int32(hole.handicap))

            guard sqlite3_step(holeStmt) == SQLITE_DONE else {
                print("Hole insert failed:", String(cString: sqlite3_errmsg(db)))
                return false
            }
        }
        return true
    }

    @discardableResult
    func insertCourse(name: String, slope: Int, sss: Double, par: Int, holes: [Hole]) -> Bool {
        let insertSQL = "INSERT INTO course (name, slope, sss, par) VALUES (?, ?, ?, ?);"

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK else {
            print("Prepare failed:", String(cString: sqlite3_errmsg(db)))
            return false
        }

        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, (name as NSString).utf8String, -1, nil)
        sqlite3_bind_int(statement, 2, Int32(slope))
        sqlite3_bind_double(statement, 3, sss)
        sqlite3_bind_int(statement, 4, Int32(par))
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            print("Insert failed:", String(cString: sqlite3_errmsg(db)))
            return false
        }

        let courseId = sqlite3_last_insert_rowid(db)

        let holeSQL = """
        INSERT INTO course_hole (course_id, hole_number, par, handicap)
        VALUES (?, ?, ?, ?);
        """

        for hole in holes {
            var holeStmt: OpaquePointer?

            guard sqlite3_prepare_v2(db, holeSQL, -1, &holeStmt, nil) == SQLITE_OK else {
                print("Hole prepare failed:", String(cString: sqlite3_errmsg(db)))
                return false
            }

            defer { sqlite3_finalize(holeStmt) }

            sqlite3_bind_int64(holeStmt, 1, courseId)
            sqlite3_bind_int(holeStmt, 2, Int32(hole.number))
            sqlite3_bind_int(holeStmt, 3, Int32(hole.par))
            sqlite3_bind_int(holeStmt, 4, Int32(hole.handicap))

            guard sqlite3_step(holeStmt) == SQLITE_DONE else {
                print("Hole insert failed:", String(cString: sqlite3_errmsg(db)))
                return false
            }
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
        sss: Double,
        par: Int,
        strokesReceived: Int,
        holes: [Hole]
    ) -> Int64? {
        let roundSQL = """
        INSERT INTO played_round (
            player_name, competition_name, course_id, course_name,
            handicap, slope, sss, par, strokes_received, played_at, updated_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, roundSQL, -1, &stmt, nil) == SQLITE_OK else {
            return nil
        }

        let now = Date().timeIntervalSince1970

        sqlite3_bind_text(stmt, 1, (playerName as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (competitionName as NSString).utf8String, -1, nil)
        sqlite3_bind_int64(stmt, 3, courseId)
        sqlite3_bind_text(stmt, 4, (courseName as NSString).utf8String, -1, nil)
        sqlite3_bind_double(stmt, 5, handicap)
        sqlite3_bind_int(stmt, 6, Int32(slope))
        sqlite3_bind_double(stmt, 7, sss)
        sqlite3_bind_int(stmt, 8, Int32(par))
        sqlite3_bind_int(stmt, 9, Int32(strokesReceived))
        sqlite3_bind_double(stmt, 10, now)
        sqlite3_bind_double(stmt, 11, now)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            sqlite3_finalize(stmt)
            return nil
        }

        sqlite3_finalize(stmt)
        let roundId = sqlite3_last_insert_rowid(db)

        let holeSQL = """
        INSERT INTO played_round_hole (
            round_id, hole_number, par, handicap, strokes, strokes_given, is_played
        )
        VALUES (?, ?, ?, ?, ?, ?, ?);
        """

        for hole in holes {
            var holeStmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, holeSQL, -1, &holeStmt, nil) == SQLITE_OK else {
                return nil
            }

            let strokesGiven = calculateStrokesGiven(
                strokesReceived: strokesReceived,
                holeHandicap: hole.handicap
            )

            sqlite3_bind_int64(holeStmt, 1, roundId)
            sqlite3_bind_int(holeStmt, 2, Int32(hole.number))
            sqlite3_bind_int(holeStmt, 3, Int32(hole.par))
            sqlite3_bind_int(holeStmt, 4, Int32(hole.handicap))
            sqlite3_bind_int(holeStmt, 5, Int32(hole.strokes))
            sqlite3_bind_int(holeStmt, 6, Int32(strokesGiven))
            sqlite3_bind_int(holeStmt, 7, 0)

            guard sqlite3_step(holeStmt) == SQLITE_DONE else {
                sqlite3_finalize(holeStmt)
                return nil
            }

            sqlite3_finalize(holeStmt)
        }

        return roundId
    }
    
    func fetchPlayedRounds(limit: Int = 50) -> [PlayedRound] {
        let sql = """
        SELECT id, player_name, competition_name, course_id, course_name,
               handicap, slope, sss, par, strokes_received, played_at, updated_at
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
            let sss = Double(sqlite3_column_int(stmt, 7))
            let par = Int(sqlite3_column_int(stmt, 8))
            let strokesReceived = Int(sqlite3_column_int(stmt, 9))
            let playedAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 10))

            let updatedAtValue = sqlite3_column_type(stmt, 10) == SQLITE_NULL
                ? sqlite3_column_double(stmt, 9)
                : sqlite3_column_double(stmt, 10)

            let updatedAt = Date(timeIntervalSince1970: updatedAtValue)
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
                    par: par,
                    strokesReceived: strokesReceived,
                    playedAt: playedAt,
                    updatedAt: updatedAt,
                    holes: holes
                )
            )
        }

        return rounds
    }
    
    func fetchPlayedRoundHoles(roundId: Int64) -> [Hole] {
        let sql = """
        SELECT hole_number, par, handicap, strokes, strokes_given, is_played
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
                    strokes: Int(sqlite3_column_int(stmt, 3)),
                    strokesGiven: Int(sqlite3_column_int(stmt, 4)),
                    isPlayed: Bool(sqlite3_column_int(stmt, 5) == 1 ? true : false)
                )
            )
        }

        return holes
    }
    
    func updatePlayedRoundHolePlayedStatus(
        roundId: Int64,
        holeNumber: Int,
        isPlayed: Bool
    ) {
        execute("""
        UPDATE played_round_hole
        SET is_played = \(isPlayed ? 1 : 0)
        WHERE round_id = \(roundId)
          AND hole_number = \(holeNumber);
        """)
    }
    
    @discardableResult
    func updatePlayedRoundHole(roundId: Int64, holeNumber: Int, strokes: Int) -> Bool {
        let holeSQL = """
        UPDATE played_round_hole
        SET strokes = ?
        WHERE round_id = ? AND hole_number = ?;
        """

        var holeStmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, holeSQL, -1, &holeStmt, nil) == SQLITE_OK else {
            return false
        }

        sqlite3_bind_int(holeStmt, 1, Int32(strokes))
        sqlite3_bind_int64(holeStmt, 2, roundId)
        sqlite3_bind_int(holeStmt, 3, Int32(holeNumber))

        guard sqlite3_step(holeStmt) == SQLITE_DONE else {
            sqlite3_finalize(holeStmt)
            return false
        }

        sqlite3_finalize(holeStmt)

        let roundSQL = """
        UPDATE played_round
        SET updated_at = ?
        WHERE id = ?;
        """

        var roundStmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, roundSQL, -1, &roundStmt, nil) == SQLITE_OK else {
            return false
        }

        sqlite3_bind_double(roundStmt, 1, Date().timeIntervalSince1970)
        sqlite3_bind_int64(roundStmt, 2, roundId)

        guard sqlite3_step(roundStmt) == SQLITE_DONE else {
            sqlite3_finalize(roundStmt)
            return false
        }

        sqlite3_finalize(roundStmt)
        return true
    }

    private func seedIfNeeded() {
        guard fetchCourses().isEmpty else { return }
        _ = insertCourse(name: "Default Course", slope: 113, sss: 72, par: 72, holes: [Hole].defaultHoles())
    }
    
    private func calculateStrokesGiven(strokesReceived: Int, holeHandicap: Int) -> Int {
        let base = strokesReceived / 18
        let remainder = strokesReceived % 18
        return base + (holeHandicap <= remainder ? 1 : 0)
    }
}

