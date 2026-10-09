import DeviceActivity
import Foundation

/// iOS la despierta en segundo plano cuando se cumple el tiempo de una sesión.
/// Al volver a aplicar el bloqueo, si estás dentro de Instagram la pantalla de
/// Freno aparece encima de inmediato: la app "se cierra sola".
class FrenoMonitorExtension: DeviceActivityMonitor {

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        guard activity == .session, let session = SharedStore.shared.activeSession else { return }

        // Algunas versiones de iOS disparan el evento apenas empieza el monitoreo.
        // Es imposible haber usado N minutos antes de que pasen N minutos, así que lo ignoramos;
        // el fin del intervalo (15 min) sigue funcionando como respaldo.
        let minimumElapsed = TimeInterval(session.minutes * 60) - 5
        guard Date().timeIntervalSince(session.start) >= minimumElapsed else { return }

        ShieldManager.endSession()
        Notifier.send(id: "freno.timeUp",
                      title: "Se acabó el tiempo ⏰",
                      body: "Entraste para: \"\(session.reason)\". ¿Lo cumpliste? Freno volvió a bloquear.")
    }

    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        guard activity == .session, SharedStore.shared.activeSession != nil else { return }
        Notifier.send(id: "freno.warning", title: "Te queda 1 minuto", body: "Ve cerrando lo que estás haciendo.")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard activity == .session, SharedStore.shared.activeSession != nil else { return }
        ShieldManager.endSession()
    }
}
