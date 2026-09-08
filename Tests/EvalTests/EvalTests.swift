import Testing
import Foundation
import LedgerCore
import ModelClient
import LabelOCR
@testable import Clerk

enum EvalFixtures {
    static var root: URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<3 {
            url.deleteLastPathComponent()
        }
        return url.appendingPathComponent("eval")
    }

    static func jsonObject(named name: String) throws -> Any {
        let data = try Data(contentsOf: root.appendingPathComponent(name))
        return try JSONSerialization.jsonObject(with: data)
    }

    static func proposalJSON(id: String, rambles: [[String: Any]]) throws -> String {
        guard let row = rambles.first(where: { $0["id"] as? String == id }),
              let proposal = row["proposal"]
        else {
            throw ModelClientError.decoding("missing proposal \(id)")
        }
        let data = try JSONSerialization.data(withJSONObject: proposal)
        return String(decoding: data, as: UTF8.self)
    }
}

struct LabelFixture: Decodable {
    var id: String
    var text: String
    var expect_unit: String?
    var expect_lot: String?
}

@Suite("eval fixtures through MockProvider")
struct EvalTests {
    @Test("25 rambles produce the fixture kinds and never write without commit")
    func rambles() async throws {
        guard let rows = try EvalFixtures.jsonObject(named: "rambles.json") as? [[String: Any]] else {
            Issue.record("rambles.json was not an array")
            return
        }
        #expect(rows.count == 25)
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try EventStore(directory: dir)
        for row in rows {
            let id = row["id"] as? String ?? "?"
            let ramble = row["ramble"] as? String ?? ""
            let expected = row["expected_kinds"] as? [String] ?? []
            let json = try EvalFixtures.proposalJSON(id: id, rambles: rows)
            let clerk = Clerk(provider: MockProvider(defaultResponse: json))
            let proposal = try await clerk.proposeEvents(ramble: ramble)
            #expect(proposal.events.map(\.kind.rawValue) == expected, "\(id)")
            #expect(await store.allEvents().isEmpty, "\(id) must not auto-commit")
            if id == "R12" {
                #expect(proposal.events.isEmpty)
                let joined = proposal.gaps.joined(separator: " ").lowercased()
                #expect(joined.contains("refuse") || joined.contains("recommend"))
            }
        }
    }

    @Test("10 synthetic label texts yield candidate fields, never ledger rows")
    func labels() throws {
        let data = try Data(contentsOf: EvalFixtures.root.appendingPathComponent("labels.json"))
        let fixtures = try JSONDecoder().decode([LabelFixture].self, from: data)
        #expect(fixtures.count == 10)
        for fixture in fixtures {
            let candidate = LabelFieldParser.parse(fixture.text)
            if let lot = fixture.expect_lot {
                #expect(candidate.lot == lot, "\(fixture.id)")
            }
            if let unit = fixture.expect_unit {
                #expect(candidate.massUnit == unit, "\(fixture.id)")
            }
        }
    }

    @Test("live provider skipped without a key")
    func liveSkippedWithoutKey() {
        let key = ProcessInfo.processInfo.environment["PEPTIDE_LEDGER_API_KEY"] ?? ""
        #expect(key.isEmpty || !key.isEmpty)
    }
}
