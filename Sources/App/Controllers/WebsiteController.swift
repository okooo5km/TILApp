import Vapor
import Leaf

struct WebsiteController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: index)
        routes.get("acronyms", ":acronymID", use: acronym)
        routes.get("users", ":userID", use: user)
        routes.get("users", use: allUsers)
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
