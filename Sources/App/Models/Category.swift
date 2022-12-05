import Vapor
import Fluent

final class Category: Model, Content {
    static let schema = "categories"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String
    
    @Siblings(through: AcronymCategoryPivot.self,
              from: \AcronymCategoryPivot.$category,
              to: \AcronymCategoryPivot.$acronym)
    var acronyms: [Acronym]

    init() {}

    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
