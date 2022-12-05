@testable import App
import Fluent

extension User {
    static func create(
        name: String = "Luke",
        username: String = "Lukes",
        database: Database
    ) throws -> User {
        let user = User(name: name, username: username)
        try user.save(on: database).wait()
        return user
    }
}

extension Acronym {
    static func create(
        short: String = "TIL",
        long: String = "Today I Learned",
        user: User? = nil,
        database: Database
    ) throws -> Acronym {
        var acronymsUser = user
        if acronymsUser == nil {
            acronymsUser = try User.create(database: database)
        }

        let acronym = Acronym(short: short, long: long, userID: acronymsUser!.id!)
        try acronym.save(on: database).wait()
        return acronym
    }
}

extension App.Category {
    static func create(
        name: String = "Random",
        database: Database
    ) throws -> App.Category {
        let category = App.Category(name: name)
        try category.save(on: database).wait()
        return category
    }
}
