import Foundation
import CoreLocation

struct SavedPlace: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var createdAt: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var coordinateText: String {
        String(format: "%.7f,%.7f", latitude, longitude)
    }
}

final class BookmarkStore: ObservableObject {
    @Published private(set) var places: [SavedPlace] = []
    private let storageKey = "LoTNG.savedPlaces.v1"

    init() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([SavedPlace].self, from: data) else { return }
        places = decoded
    }

    func add(name: String, coordinate: CLLocationCoordinate2D, altitude: Double) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, CLLocationCoordinate2DIsValid(coordinate),
              coordinate.latitude.isFinite, coordinate.longitude.isFinite, altitude.isFinite else { return }
        places.append(SavedPlace(id: UUID(), name: trimmed, latitude: coordinate.latitude,
                                 longitude: coordinate.longitude, altitude: altitude, createdAt: Date()))
        persist()
    }

    func remove(_ id: UUID) {
        places.removeAll { $0.id == id }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(places) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
