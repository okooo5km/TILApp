import Fluent

struct CreateAcronym: AsyncMigration {

    func prepare(on database: Database) async throws {
        try await database.schema("acronyms")
            .id()
            .field("short", .string, .required)
            .field("long", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("acronyms").delete()
    }
    
}