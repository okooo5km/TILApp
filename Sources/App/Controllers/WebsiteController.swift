import Vapor
import Leaf

struct WebsiteController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: index)
        routes.get("acronyms", ":acronymID", use: acronym)
        routes.get("users", ":userID", use: user)
        routes.get("users", use: allUsers)
        routes.get("categories", use: allCategories)
        routes.get("categories", ":categoryID", use: category)
        routes.get("acronyms", "create", use: createAcronym)
        routes.post("acronyms", "create", use: createAcronymPost)
    }

    func index(_ req: Request) async throws -> View {
        let acronyms = try await Acronym.query(on: req.db).all()
        let context = IndexContext(title: "Home page", acronyms: acronyms)
        return try await req.view.render("index", context)
    }

    func acronym(_ req: Request) async throws -> View {
        guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let user = try await acronym.$user.get(on: req.db)
        let context = AcronymContext(title: acronym.short, acronym: acronym, user: user)
        return try await req.view.render("acronym", context)
    }

    func user(_ req: Request) async throws -> View {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let acronyms = try await user.$acronyms.get(on: req.db)
        let context = UserContext(title: user.name, user: user, acronyms: acronyms)
        return try await req.view.render("user", context)
    }

    func allUsers(_ req: Request) async throws -> View {
        let users = try await User.query(on: req.db).all()
        let context = AllUsersContext(title: "All Users", users: users)
        return try await req.view.render("allUsers", context)
    }

    func allCategories(_ req: Request) async throws -> View {
        let categories = try await Category.query(on: req.db).all()
        let context = AllCategoriesContext(title: "All Categories", categories: categories)
        return try await req.view.render("allCategories", context)
    }

    func category(_ req: Request) async throws -> View {
        guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db) else {
            throw Abort(.notFound)
        } 
        let acronyms = try await category.$acronyms.get(on: req.db)
        let context = CategoryContext(title: category.name, category: category, acronyms: acronyms)
        return try await req.view.render("category", context)
    }

    func createAcronym(_ req: Request) async throws -> View {
        let users = try await User.query(on: req.db).all()
        let context = CreateAcronymContext(users: users)
        return try await req.view.render("createAcronym", context)
    }

    func createAcronymPost(_ req: Request) async throws -> Response {
        let createData = try req.content.decode(CreateAcronymData.self)
        let acronym = Acronym(short: createData.short, long: createData.long, userID: createData.userID)
        try await acronym.save(on: req.db)
        guard let acronymID = acronym.id else {
            throw Abort(.internalServerError)
        }
        return req.redirect(to: "/acronyms/\(acronymID)")
    }
}

struct IndexContext: Encodable {
    let title: String
    let acronyms: [Acronym]
}

struct AcronymContext: Encodable {
    let title: String
    let acronym: Acronym
    let user: User
}

struct UserContext: Encodable {
    let title: String
    let user: User
    let acronyms: [Acronym]
}

struct AllUsersContext: Encodable {
    let title: String
    let users: [User]
}

struct AllCategoriesContext: Encodable {
    let title: String
    let categories: [Category]
}

struct CategoryContext: Encodable {
    let title: String
    let category: Category
    let acronyms: [Acronym]
}

struct CreateAcronymContext: Encodable {
    let title: String = "Create An acronym"
    let users: [User]
}