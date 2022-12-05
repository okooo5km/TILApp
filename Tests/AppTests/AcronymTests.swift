@testable import App
import XCTVapor

final class AcronymTests: XCTestCase {
    let acronymsShort = "OMG"
    let acronymsLong = "Oh My God"
    let acronymsURI = "/api/acronyms/"
    var app: Application!
    
    override func setUpWithError() throws {
        app = try Application.testable()
    }
    
    override func tearDownWithError() throws {
        app.shutdown()
    }
    
    func testAcronymsCanBeRetrievedFromAPI() throws {
        let user = try User.create(database: app.db)
        let acronym = try Acronym.create(short: acronymsShort, long: acronymsLong, user: user, database: app.db)
        let _ = try Acronym.create(database: app.db)
        
        try app.test(.GET, acronymsURI) { resposne throws in
            XCTAssertEqual(resposne.status, .ok)
            let acronyms = try resposne.content.decode([Acronym].self)
            XCTAssertEqual(acronyms.count, 2)
            XCTAssertEqual(acronyms[0].short, acronymsShort)
            XCTAssertEqual(acronyms[0].long, acronymsLong)
            XCTAssertEqual(acronyms[0].id, acronym.id)
            XCTAssertEqual(acronyms[0].$user.id, user.id)
        }
    }
    
    func testAcronymCanBeSavedWithAPI() throws {
        let user = try User.create(database: app.db)
        let createAcronym = CreateAcronymData(short: acronymsShort, long: acronymsLong, userID: user.id!)
        
        try app.test(.POST, acronymsURI, beforeRequest: { request throws in
            try request.content.encode(createAcronym)
        }, afterResponse: { response throws in
            XCTAssertEqual(response.status, .ok)
            let acronym = try response.content.decode(Acronym.self)
            XCTAssertEqual(acronym.short, acronymsShort)
            XCTAssertEqual(acronym.long, acronymsLong)
            XCTAssertEqual(acronym.$user.id, user.id)
            XCTAssertNotNil(acronym.id)
        })
    }
    
    func testGettingASingleAcronymFromAPI() throws {
        let user = try User.create(database: app.db)
        let acronym = try Acronym.create(short: acronymsShort, long: acronymsLong, user: user, database: app.db)
        
        try app.test(.GET, "\(acronymsURI)\(acronym.id!)") { response throws in
            XCTAssertEqual(response.status, .ok)
            let retrievedAcronym = try response.content.decode(Acronym.self)
            XCTAssertEqual(retrievedAcronym.short, acronymsShort)
            XCTAssertEqual(retrievedAcronym.long, acronymsLong)
            XCTAssertEqual(retrievedAcronym.id, acronym.id)
            XCTAssertEqual(retrievedAcronym.$user.id, user.id)
        }
    }
    
    func testUpdatingAnAcronymWithAPI() throws {
        let user = try User.create(database: app.db)
        let acronym = try Acronym.create(user: user, database: app.db)
        
        let updatedAcronym = CreateAcronymData(short: acronymsShort, long: acronymsLong, userID: user.id!)
        
        try app.test(.PUT, "\(acronymsURI)\(acronym.id!)", beforeRequest: { request throws in
            try request.content.encode(updatedAcronym)
        }, afterResponse: { response throws in
            XCTAssertEqual(response.status, .ok)
            let retrievedAcronym = try response.content.decode(Acronym.self)
            XCTAssertEqual(retrievedAcronym.short, acronymsShort)
            XCTAssertEqual(retrievedAcronym.long, acronymsLong)
            XCTAssertEqual(retrievedAcronym.id, acronym.id)
            XCTAssertEqual(retrievedAcronym.$user.id, user.id)
        })
    }
    
    func testDeletingAnAcronymWithAPI() throws {
        let acronym = try Acronym.create(database: app.db)
        
        try app.test(.DELETE, "\(acronymsURI)\(acronym.id!)") {response throws in
            XCTAssertEqual(response.status, .noContent)
            let count = try Acronym.query(on: app.db).count().wait()
            XCTAssertEqual(count, 0)
        }
    }
    
    func testSearchAcronym() throws {
        let acronym = try Acronym.create(short: acronymsShort, long: acronymsLong, database: app.db)
        _ = try Acronym.create(database: app.db)
        
        try app.test(.GET, "\(acronymsURI)search?term=\(acronymsShort)") { response throws in
            XCTAssertEqual(response.status, .ok)
            let acronyms = try response.content.decode([Acronym].self)
            XCTAssertEqual(acronyms.count, 1)
            XCTAssertEqual(acronyms[0].short, acronymsShort)
            XCTAssertEqual(acronyms[0].long, acronymsLong)
            XCTAssertEqual(acronyms[0].id, acronym.id!)
        }
    }
    
    func testGettingFirstAcronym() throws {
        let acronym = try Acronym.create(short: acronymsShort, long: acronymsLong, database: app.db)
        _ = try Acronym.create(database: app.db)
        
        try app.test(.GET, "\(acronymsURI)first") { response throws in
            XCTAssertEqual(response.status, .ok)
            let retrievedAcronym = try response.content.decode(Acronym.self)
            XCTAssertEqual(retrievedAcronym.short, acronymsShort)
            XCTAssertEqual(retrievedAcronym.long, acronymsLong)
            XCTAssertEqual(retrievedAcronym.id, acronym.id)
        }
    }
    
    func testSortingAcronyms() throws {
        _ = try Acronym.create(database: app.db)
        let acronym = try Acronym.create(short: acronymsShort, long: acronymsLong, database: app.db)
        
        try app.test(.GET, "\(acronymsURI)sorted") { response throws in
            XCTAssertEqual(response.status, .ok)
            let acronyms = try response.content.decode([Acronym].self)
            XCTAssertEqual(acronyms.count, 2)
            XCTAssertEqual(acronyms[0].short, acronymsShort)
            XCTAssertEqual(acronyms[0].long, acronymsLong)
            XCTAssertEqual(acronyms[0].id, acronym.id)
        }
    }
    
    func testGettingAnAcronymUser() throws {
        let user = try User.create(database: app.db)
        let acronym = try Acronym.create(short: acronymsShort, long: acronymsLong, user: user, database: app.db)
        
        try app.test(.GET, "\(acronymsURI)\(acronym.id!)/user") { response throws in
            XCTAssertEqual(response.status, .ok)
            let retrievedUser = try response.content.decode(User.self)
            XCTAssertEqual(retrievedUser.id, user.id)
            XCTAssertEqual(retrievedUser.name, user.name)
            XCTAssertEqual(retrievedUser.username, user.username)
        }
    }
    
    func testAttachingACategoryToAnAcronym() throws {
        let category = try Category.create(database: app.db)
        let acronym = try Acronym.create(database: app.db)
        
        try app.test(.POST, "\(acronymsURI)\(acronym.id!)/categories/\(category.id!)") { response throws in
            XCTAssertEqual(response.status, .created)
            let categories = try acronym.$categories.get(on: app.db).wait()
            XCTAssertEqual(categories[0].id, category.id)
        }
    }
    
    func testGettingAnAcronymCategories() throws {
        let category = try Category.create(name: "test", database: app.db)
        let annotherCategory = try Category.create(database: app.db)
        
        let acronym = try Acronym.create(database: app.db)
        
        try acronym.$categories.attach(category, on: app.db).wait()
        try acronym.$categories.attach(annotherCategory, on: app.db).wait()
        
        try app.test(.GET, "\(acronymsURI)\(acronym.id!)/categories") { response throws in
            XCTAssertEqual(response.status, .ok)
            let categories = try response.content.decode([App.Category].self)
            XCTAssertEqual(categories[0].id, category.id)
            XCTAssertEqual(categories[1].id, annotherCategory.id)
        }
    }
    
    func testDetachingACategoryFromAnAcronym() throws {
        let category = try Category.create(name: "test", database: app.db)
        let acronym = try Acronym.create(database: app.db)
        try acronym.$categories.attach(category, on: app.db).wait()
        
        try app.test(.DELETE, "\(acronymsURI)\(acronym.id!)/categories/\(category.id!)") { response throws in
            XCTAssertEqual(response.status, .noContent)
            let categories = try acronym.$categories.get(on: app.db).wait()
            XCTAssertEqual(categories.count, 0)
        }
    }
}
