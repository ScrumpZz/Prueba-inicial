import Foundation
import FamilyControls
import ManagedSettings

/// Identificador del App Group compartido entre la app y sus extensiones.
/// Debe coincidir con el de project.yml.
enum AppGroup {
    static let id = "group.com.tunombre.freno"
    static var defaults: UserDefaults { UserDefaults(suiteName: id) ?? .standard }
}

/// Una vez que diste un motivo y desbloqueaste una app.
struct SessionRecord: Codable, Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var reason: String
    var minutes: Int
}

/// Sesión de desbloqueo en curso.
struct ActiveSession: Codable {
    var start: Date
    var minutes: Int
    var reason: String
    /// Límite de reloj: aunque no uses la app, a esta hora se vuelve a bloquear.
    var expiresAt: Date
}

/// Petición de desbloqueo creada desde la pantalla de bloqueo.
struct UnlockRequest: Codable {
    var date: Date
    var appToken: ApplicationToken?
}

/// Almacenamiento compartido (UserDefaults del App Group).
final class SharedStore {
    static let shared = SharedStore()

    private let defaults = AppGroup.defaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Key {
        static let selection = "selection"
        static let sessions = "sessions"
        static let resisted = "resisted"
        static let unlockRequest = "unlockRequest"
        static let activeSession = "activeSession"
        static let protectionEnabled = "protectionEnabled"
        static let onboarded = "onboarded"
    }

    // MARK: - Configuración

    var selection: FamilyActivitySelection {
        get { load(Key.selection) ?? FamilyActivitySelection() }
        set { save(newValue, Key.selection) }
    }

    var isProtectionEnabled: Bool {
        get { defaults.bool(forKey: Key.protectionEnabled) }
        set { defaults.set(newValue, forKey: Key.protectionEnabled) }
    }

    var hasOnboarded: Bool {
        get { defaults.bool(forKey: Key.onboarded) }
        set { defaults.set(newValue, forKey: Key.onboarded) }
    }

    // MARK: - Estado

    var activeSession: ActiveSession? {
        get { load(Key.activeSession) }
        set { save(newValue, Key.activeSession) }
    }

    var unlockRequest: UnlockRequest? {
        get { load(Key.unlockRequest) }
        set { save(newValue, Key.unlockRequest) }
    }

    // MARK: - Historial

    var sessions: [SessionRecord] {
        get { load(Key.sessions) ?? [] }
        set { save(Array(newValue.suffix(500)), Key.sessions) }
    }

    /// Fechas en las que tocaste "Mejor no entro".
    var resisted: [Date] {
        get { load(Key.resisted) ?? [] }
        set { save(Array(newValue.suffix(500)), Key.resisted) }
    }

    func registerResisted() {
        resisted.append(Date())
    }

    // MARK: - Helpers

    private func load<T: Decodable>(_ key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    private func save<T: Encodable>(_ value: T?, _ key: String) {
        guard let value, let data = try? encoder.encode(value) else {
            defaults.removeObject(forKey: key)
            return
        }
        defaults.set(data, forKey: key)
    }
}
