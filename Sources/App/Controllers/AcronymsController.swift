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
        acronymRoutes.get(":acronymID", "user", use: getUser)
        acronymRoutes.post(":acronymID", "categories", ":categoryID", use: attach)
        acronymRoutes.delete(":acronymID", "categories", ":categoryID", use: detach)
        acronymRoutes.get(":acronymID", "categories", use: getCategories)
    }

    func index(_ req: Request) async throws -> [Acronym] {
        try await Acronym.query(on: req.db).all()
    }

    func create(_ req: Request) async throws -> Acronym {
        let data = try req.content.decode(CreateAcronymData.self)
        let acronym = Acronym(short: data.short, long: data.long, userID: data.userID)
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
        let updatedAcronym = try req.content.decode(CreateAcronymData.self)

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

    func getUser(_ req: Request) async throws -> User {
        guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return try await acronym.$user.get(on: req.db)
    }
    
    func attach(_ req: Request) async throws -> HTTPStatus {
        guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else {
            throw Abort(.notFound)
        }
        guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await acronym.$categories.attach(category, on: req.db)
        return .created
    }
    
    func detach(_ req: Request) async throws -> HTTPStatus {
        guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else {
            throw Abort(.notFound)
        }
        guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await acronym.$categories.detach(category, on: req.db)
        return .noContent
    }
    
    func getCategories(_ req: Request) async throws -> [Category] {
        guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return try await acronym.$categories.get(on: req.db)
    }
}

struct CreateAcronymData: Content {
    let short: String
    let long: String
    let userID: UUID
}
