import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    app.post("api", "acronyms") { req async throws -> Acronym in
        let acronym = try req.content.decode(Acronym.self)
        try await acronym.save(on: req.db)
        return acronym
    }
}
