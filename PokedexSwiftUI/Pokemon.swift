import Foundation

struct Pokemon: Identifiable, Codable {
    let id: Int
    let name: String
    let imageUrl: String
    let types: [String]
    let stats: [String: Int]
}
