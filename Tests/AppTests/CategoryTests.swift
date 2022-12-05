@testable import App
import XCTVapor

final class CategoryTests: XCTestCase {
    
    let categoriesName = "test"
    let categoriesURI = "/api/categories/"
    var app: Application!
    
    override func setUpWithError() throws {
        app = try Application.testable()
    }
    
    override func tearDownWithError() throws {
        app.shutdown()
    }
    
    func testCategoriesCanBeRetrievedFromAPI() throws {
        let category = try Category.create(name: categoriesName, database: app.db)
        _ = try Category.create(database: app.db)
        
        try app.test(.GET, categoriesURI) { response throws in
            XCTAssertEqual(response.status, .ok)
            let categories = try response.content.decode([App.Category].self)
            XCTAssertEqual(categories.count, 2)
            XCTAssertEqual(categories[0].name, categoriesName)
            XCTAssertEqual(categories[0].id, category.id)
        }
    }
    
    func testCategoriesCanBeSavedWithAPI() throws {
        let category = Category(name: categoriesName)
        
        try app.test(.POST, categoriesURI, beforeRequest: { request throws in
            try request.content.encode(category)
        }, afterResponse: { response throws in
            XCTAssertEqual(response.status, .ok)
            
            let retrievedCategory = try response.content.decode(Category.self)
            XCTAssertEqual(retrievedCategory.name, categoriesName)
            XCTAssertNotNil(retrievedCategory.id)
            
            try app.test(.GET, categoriesURI) { secondResponse throws in
                XCTAssertEqual(secondResponse.status, .ok)
                let categories = try secondResponse.content.decode([App.Category].self)
                XCTAssertEqual(categories.count, 1)
                XCTAssertEqual(categories[0].name, categoriesName)
                XCTAssertEqual(categories[0].id, retrievedCategory.id)
            }
        })
    }
    
    func testGettingASingleCategoryFromAPI() throws {
        let category = try Category.create(name: categoriesName, database: app.db)
        
        try app.test(.GET, "\(categoriesURI)\(category.id!)") {response throws in
            XCTAssertEqual(response.status, .ok)
            let retrievedCategory = try response.content.decode(App.Category.self)
            XCTAssertEqual(retrievedCategory.name, categoriesName)
            XCTAssertEqual(retrievedCategory.id, category.id)
        }
    }
    
    func testGettingACategoryAcronymsFromAPI() throws {
        let category = try Category.create(name: categoriesName, database: app.db)
        let user = try User.create(database: app.db)
        
        let acronym = try Acronym.create(short: "OMG", long: "Oh My God", user: user, database: app.db)
        let annotherAcronym = try Acronym.create(database: app.db)
        
        try acronym.$categories.attach(category, on: app.db).wait()
        try annotherAcronym.$categories.attach(category, on: app.db).wait()
        
        try app.test(.GET, "\(categoriesURI)\(category.id!)/acronyms") { response throws in
            XCTAssertEqual(response.status, .ok)
            let acronyms = try response.content.decode([Acronym].self)
            XCTAssertEqual(acronyms.count, 2)
            XCTAssertEqual(acronyms[0].short, "OMG")
            XCTAssertEqual(acronyms[0].long, "Oh My God")
        }
    }
}
