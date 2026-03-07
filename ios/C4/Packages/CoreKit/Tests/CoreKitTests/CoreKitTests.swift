import Testing
import Foundation
@testable import CoreKit

@Suite("CoreKit Model Tests")
struct CoreKitModelTests {
    @Test func projectCodable() throws {
        let project = Project(title: "Test Project", description: "A test")
        let data = try JSONEncoder().encode(project)
        let decoded = try JSONDecoder().decode(Project.self, from: data)
        #expect(decoded == project)
    }

    @Test func assetCodable() throws {
        let asset = Asset(
            projectId: UUID(),
            type: .image,
            prompt: "A sunset",
            provider: "openai",
            creditCost: 5
        )
        let data = try JSONEncoder().encode(asset)
        let decoded = try JSONDecoder().decode(Asset.self, from: data)
        #expect(decoded == asset)
    }

    @Test func creditAccountCodable() throws {
        let tx = CreditTransaction(type: .deduction, amount: 5, description: "Image generation")
        let account = CreditAccount(balance: 95, transactions: [tx])
        let data = try JSONEncoder().encode(account)
        let decoded = try JSONDecoder().decode(CreditAccount.self, from: data)
        #expect(decoded == account)
    }

    @Test func generationJobCodable() throws {
        let job = GenerationJob(provider: "openai", type: .image)
        let data = try JSONEncoder().encode(job)
        let decoded = try JSONDecoder().decode(GenerationJob.self, from: data)
        #expect(decoded == job)
    }

    @Test func noteCodable() throws {
        let note = Note(projectId: UUID(), content: "An idea for a video")
        let data = try JSONEncoder().encode(note)
        let decoded = try JSONDecoder().decode(Note.self, from: data)
        #expect(decoded == note)
    }
}
