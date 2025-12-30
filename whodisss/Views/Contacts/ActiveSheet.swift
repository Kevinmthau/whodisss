import Foundation

enum ActiveSheet: Identifiable {
    case imageSearch
    case camera
    case photoEditor

    var id: Int {
        switch self {
        case .imageSearch: return 0
        case .camera: return 1
        case .photoEditor: return 2
        }
    }
}
