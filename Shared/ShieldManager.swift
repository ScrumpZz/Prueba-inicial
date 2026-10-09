import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

extension ManagedSettingsStore.Name {
    static let freno = Self("freno")
}

extension DeviceActivityName {
    static let session = Self("freno.session")
}

extension DeviceActivityEvent.Name {
    static let timeUp = Self("freno.timeUp")
}

/// Aplica/quita los bloqueos y programa el fin de cada sesión.
enum ShieldManager {
    private static var store: ManagedSettingsStore { ManagedSettingsStore(named: .freno) }

    /// iOS exige que un intervalo de DeviceActivity dure al menos 15 minutos.
    private static let minimumIntervalMinutes = 15

    /// Bloquea todas las apps elegidas (si la protección está activa).
    static func applyShield() {
        let data = SharedStore.shared
        guard data.isProtectionEnabled else {
            store.clearAllSettings()
            return
        }
        let selection = data.selection
        let store = self.store
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        store.shield.webDomainCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
    }

    /// Desbloquea durante `minutes` minutos de uso. Si `app` no es nil, solo se
    /// desbloquea esa app; si es nil, se desbloquean todas las elegidas.
    static func startSession(minutes: Int, reason: String, app: ApplicationToken?) throws {
        let data = SharedStore.shared
        let selection = data.selection
        let center = DeviceActivityCenter()
        center.stopMonitoring([.session])

        // 1. Programar el nuevo bloqueo ANTES de quitar el actual.
        let now = Date()
        let expiresAt = now.addingTimeInterval(TimeInterval(max(minimumIntervalMinutes, minutes) * 60))
        let calendar = Calendar.current
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents(components, from: now),
            intervalEnd: calendar.dateComponents(components, from: expiresAt),
            repeats: false,
            warningTime: DateComponents(minute: 1)
        )

        let apps: Set<ApplicationToken> = app.map { [$0] } ?? selection.applicationTokens
        let categories: Set<ActivityCategoryToken> = app == nil ? selection.categoryTokens : []
        let domains: Set<WebDomainToken> = app == nil ? selection.webDomainTokens : []
        let threshold = DateComponents(minute: minutes)

        let event: DeviceActivityEvent
        if #available(iOS 17.4, *) {
            event = DeviceActivityEvent(applications: apps, categories: categories, webDomains: domains,
                                        threshold: threshold, includesPastActivity: false)
        } else {
            event = DeviceActivityEvent(applications: apps, categories: categories, webDomains: domains,
                                        threshold: threshold)
        }

        try center.startMonitoring(.session, during: schedule, events: [.timeUp: event])

        // 2. Quitar el bloqueo.
        let store = self.store
        if let app {
            var remaining = selection.applicationTokens
            remaining.remove(app)
            store.shield.applications = remaining.isEmpty ? nil : remaining
            if !selection.categoryTokens.isEmpty {
                store.shield.applicationCategories = .specific(selection.categoryTokens, except: [app])
            }
        } else {
            store.clearAllSettings()
        }

        // 3. Guardar el registro.
        data.activeSession = ActiveSession(start: now, minutes: minutes, reason: reason, expiresAt: expiresAt)
        data.unlockRequest = nil
        data.sessions.append(SessionRecord(date: now, reason: reason, minutes: minutes))
    }

    /// Termina la sesión actual y vuelve a bloquear todo.
    static func endSession() {
        SharedStore.shared.activeSession = nil
        DeviceActivityCenter().stopMonitoring([.session])
        applyShield()
    }

    /// Activa o desactiva Freno por completo.
    static func setProtection(enabled: Bool) {
        SharedStore.shared.isProtectionEnabled = enabled
        if enabled {
            endSession()
        } else {
            SharedStore.shared.activeSession = nil
            DeviceActivityCenter().stopMonitoring()
            store.clearAllSettings()
        }
    }
}
