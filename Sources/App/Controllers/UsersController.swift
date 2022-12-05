import Fluent
import Vapor

struct UsersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let userRoutes = routes.grouped("api", "users")
        userRoutes.post(use: create)
        userRoutes.get(use: index)
        userRoutes.get(":userID", use: show)
        userRoutes.get(":userID", "acronyms", use: getAcronyms)
    }

    func create(_ req: Request) async throws -> User {
        let user = try req.content.decode(User.self)
        try await user.save(on: req.db)
        return user
    }

    func index(_ req: Request) async throws -> [User] {
        try await User.query(on: req.db).all()
    }

    func show(_ req: Request) async throws -> User {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return user
    }

    func getAcronyms(_ req: Request) async throws -> [Acronym] {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return try await user.$acronyms.get(on: req.db)
    }
}