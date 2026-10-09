import SwiftUI
import FamilyControls
import ManagedSettings

@MainActor
final class AppModel: ObservableObject {
    private let store = SharedStore.shared

    @Published var isAuthorized = false
    @Published var hasOnboarded = false
    @Published var isProtectionEnabled = false
    @Published var selection = FamilyActivitySelection()
    @Published var activeSession: ActiveSession?
    @Published var sessions: [SessionRecord] = []
    @Published var resisted: [Date] = []

    /// Hoja de "¿Por qué quieres entrar?". `pendingApp` es la app desde la que vienes.
    @Published var showUnlock = false
    @Published var pendingApp: ApplicationToken?

    /// Una petición creada desde la pantalla de bloqueo caduca a los 10 minutos.
    private let unlockRequestLifetime: TimeInterval = 10 * 60

    init() { refresh() }

    func refresh() {
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        hasOnboarded = store.hasOnboarded
        isProtectionEnabled = store.isProtectionEnabled
        selection = store.selection

        // Respaldo por si la extensión no alcanzó a cerrar la sesión.
        if let session = store.activeSession, session.expiresAt < Date() {
            ShieldManager.endSession()
        }
        activeSession = store.activeSession
        sessions = store.sessions
        resisted = store.resisted

        if let request = store.unlockRequest {
            if Date().timeIntervalSince(request.date) < unlockRequestLifetime, activeSession == nil, hasOnboarded {
                pendingApp = request.appToken
                showUnlock = true
            } else {
                store.unlockRequest = nil
            }
        }
    }

    // MARK: - Configuración

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            print("Autorización de Tiempo de uso rechazada: \(error)")
        }
        refresh()
    }

    func updateSelection(_ newSelection: FamilyActivitySelection) {
        store.selection = newSelection
        selection = newSelection
        if activeSession == nil { ShieldManager.applyShield() }
    }

    func finishOnboarding() {
        store.hasOnboarded = true
        ShieldManager.setProtection(enabled: true)
        refresh()
    }

    func setProtection(enabled: Bool) {
        ShieldManager.setProtection(enabled: enabled)
        refresh()
    }

    // MARK: - Sesiones

    func startSession(reason: String, minutes: Int) throws {
        try ShieldManager.startSession(minutes: minutes, reason: reason, app: pendingApp)
        refresh()
    }

    func endSessionNow() {
        ShieldManager.endSession()
        refresh()
    }

    func resist() {
        store.registerResisted()
        cancelUnlock()
    }

    func cancelUnlock() {
        store.unlockRequest = nil
        pendingApp = nil
        showUnlock = false
        refresh()
    }

    func openUnlockManually() {
        pendingApp = nil
        showUnlock = true
    }

    // MARK: - Estadísticas

    var todaySessions: [SessionRecord] {
        sessions.filter { Calendar.current.isDateInToday($0.date) }
    }

    var todayMinutes: Int { todaySessions.reduce(0) { $0 + $1.minutes } }

    var todayResisted: Int { resisted.filter { Calendar.current.isDateInToday($0) }.count }

    var blockedCount: Int {
        selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
    }
}
