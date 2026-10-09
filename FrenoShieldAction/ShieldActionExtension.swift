import ManagedSettings
import Foundation

/// Maneja los botones de la pantalla de bloqueo.
/// - Botón principal ("Mejor no entro"): cuenta una victoria y cierra la app.
/// - Botón secundario ("Necesito entrar"): deja una petición pendiente y manda una
///   notificación que abre Freno, donde escribes el motivo y eliges el tiempo.
///   (iOS no permite abrir otra app directamente desde esta pantalla.)
class ShieldActionExtension: ShieldActionDelegate {

    override func handle(action: ShieldAction, for application: ApplicationToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(respond(to: action, app: application))
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(respond(to: action, app: nil))
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(respond(to: action, app: nil))
    }

    private func respond(to action: ShieldAction, app: ApplicationToken?) -> ShieldActionResponse {
        switch action {
        case .primaryButtonPressed:
            SharedStore.shared.registerResisted()
            Notifier.send(id: "freno.resisted", title: "Bien hecho 💪", body: "Un scroll menos. Tu tiempo es tuyo.")
            return .close
        case .secondaryButtonPressed:
            SharedStore.shared.unlockRequest = UnlockRequest(date: Date(), appToken: app)
            Notifier.send(id: "freno.unlock",
                          title: "Toca aquí para continuar",
                          body: "Cuéntale a Freno por qué quieres entrar y elige cuántos minutos.")
            return .close
        @unknown default:
            return .close
        }
    }
}
