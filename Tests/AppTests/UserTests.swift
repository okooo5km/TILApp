@testable import App
import XCTVapor

final class UserTests: XCTestCase {

    let usersName = "Alice"
    let usersUsername = "alice"
    let usersURI = "/api/users/"
    var app: Application!

    override func setUpWithError() throws {
        app = try Application.testable()
    }

    override func tearDownWithError() throws {
        app.shutdown()
    }

    func testUserCanBeRetrievedFromAPI() throws {
        let user = try User.create(name: usersName, username: usersUsername, database: app.db)
        _ = try User.create(database: app.db)

        try app.test(.GET, usersURI) { response throws in
            XCTAssertEqual(response.status, .ok)

            let users = try response.content.decode([User].self)

            XCTAssertEqual(users.count, 2)
            XCTAssertEqual(users[0].name, usersName)
            XCTAssertEqual(users[0].username, usersUsername)
            XCTAssertEqual(users[0].id, user.id)
        }
    }

    func testUserCanBeSavedWithAPI() throws {
        let user = User(name: usersName, username: usersUsername)

        try app.test(.POST, usersURI, beforeRequest: { req throws in
            try req.content.encode(user)
        }, afterResponse: { response throws in
            XCTAssertEqual(response.status, .ok)

            let retrievedUser = try response.content.decode(User.self)
            XCTAssertEqual(retrievedUser.name, usersName)
            XCTAssertEqual(retrievedUser.username, usersUsername)
            XCTAssertNotNil(retrievedUser.id)

            try app.test(.GET, usersURI) { secondResponse throws in
                XCTAssertEqual(response.status, .ok)

                let users = try secondResponse.content.decode([User].self)
                XCTAssertEqual(users.count, 1)
                XCTAssertEqual(users[0].name, usersName)
                XCTAssertEqual(users[0].username, usersUsername)
                XCTAssertEqual(users[0].id, retrievedUser.id)
            }
        })
    }

    func testGettingASingleUserFromAPI() throws {
        let user = try User.create(name: usersName, username: usersUsername, database: app.db)

        try app.test(.GET, "\(usersURI)\(user.id!)") { response throws in
            XCTAssertEqual(response.status, .ok)

            let retrievedUser = try response.content.decode(User.self)
            XCTAssertEqual(retrievedUser.name, usersName)
            XCTAssertEqual(retrievedUser.username, usersUsername)
            XCTAssertEqual(retrievedUser.id, user.id)
        }
    }

    func testGettingAUserAcronymsFromAPI() throws {
        let user = try User.create(database: app.db)
        let acronymShort = "OMG"
        let acronymLong = "Oh My God"

        let acronym = try Acronym.create(short: acronymShort, long: acronymLong, user: user, database: app.db)

        _ = try Acronym.create(short: "LOL", long: "Laugh Out Loud", user: user, database: app.db)

        try app.test(.GET, "\(usersURI)\(user.id!)/acronyms") { response throws in
            let acronyms = try response.content.decode([Acronym].self)
            
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(acronyms.count, 2)
            XCTAssertEqual(acronyms[0].short, acronymShort)
            XCTAssertEqual(acronyms[0].long, acronymLong)
            XCTAssertEqual(acronyms[0].id, acronym.id)
        }
    }    
}
