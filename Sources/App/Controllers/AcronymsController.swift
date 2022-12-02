import Vapor
import Fluent

struct AcronymsController: RouteCollection {


    func boot(routes: RoutesBuilder) throws {
        let acronymRoutes = routes.grouped("api", "acronyms")
        acronymRoutes.get(use: index)
        acronymRoutes.post(use: create)
        acronymRoutes.get(":acronymID", use: show)
        acronymRoutes.put(":acronymID", use: update)
        acronymRoutes.delete(":acronymID", use: delete)
        acronymRoutes.get("search", use: search)
        acronymRoutes.get("first", use: first)
        acronymRoutes.get("sorted", use: sort)
    }

    func index(_ req: Request) async throws -> [Acronym] {
        try await Acronym.query(on: req.db).all()
    }

    func create(_ req: Request) async throws -> Acronym {
        let acronym = try req.content.decode(Acronym.self)
        try await acronym.save(on: req.db)
        return acronym
    }

    func show(_ req: Request) async throws -> Acronym {
        guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return acronym
    }

    func update(_ req: Request) async throws -> Acronym {
        let updatedAcronym = try req.content.decode(Acronym.self)

        guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else {
            throw Abort(.notFound)
        }

        acronym.short = updatedAcronym.short
        acronym.long = updatedAcronym.long

        try await acronym.save(on: req.db)

        return acronym
    }

    func delete(_ req: Request) async throws -> HTTPStatus {
        guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await acronym.delete(on: req.db)

        return .noContent
    }

    func search(_ req: Request) async throws -> [Acronym] {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }

        return try await Acronym.query(on: req.db).group(.or) { group in
            group.filter(\.$short ~~ searchTerm).filter(\.$long ~~ searchTerm)
        }.all()
    }

    func first(_ req: Request) async throws -> Acronym {
        guard let firstAcronym = try await Acronym.query(on: req.db).first() else {
            throw Abort(.notFound)
        }

        return firstAcronym
    }

    func sort(_ req: Request) async throws -> [Acronym] {
        try await Acronym.query(on: req.db).sort(\.$short, .ascending).all()
    }
}