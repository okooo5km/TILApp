import Vapor

struct CategoriesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let categoriesRoutes = routes.grouped("api", "categories")

        categoriesRoutes.get(use: index)
        categoriesRoutes.post(use: create)
        categoriesRoutes.get(":categoryID", use: show)
        categoriesRoutes.get(":categoryID", "acronyms", use: getAcronyms)
    }

    func index(_ req: Request) async throws -> [Category] {
        try await Category.query(on: req.db).all()
    }

    func create(_ req: Request) async throws -> Category {
        let category = try req.content.decode(Category.self)
        try await category.save(on: req.db)
        return category
    }

    func show(_ req: Request) async throws -> Category {
        guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return category
    }
    
    func getAcronyms(_ req: Request) async throws -> [Acronym] {
        guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return try await category.$acronyms.get(on: req.db)
    }
}
