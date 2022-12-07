import Fluent
import Vapor

func routes(_ app: Application) throws {
    let acronymsController = AcronymsController()
    try app.routes.register(collection: acronymsController)

    let usersController = UsersController()
    try app.routes.register(collection: usersController)
    
    let categoriesController = CategoriesController()
    try app.routes.register(collection: categoriesController)

    let websiteController = WebsiteController()
    try app.routes.register(collection: websiteController)
}
