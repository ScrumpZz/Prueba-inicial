import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Diseño de la pantalla que tapa Instagram/TikTok mientras están bloqueadas.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private let questions = [
        "¿Por qué quieres entrar?",
        "¿Qué vienes a buscar?",
        "¿Esto es intencional o es costumbre?",
        "¿Qué harías con estos minutos si no entras?",
    ]

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfiguration(name: application.localizedDisplayName)
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration(name: application.localizedDisplayName)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfiguration(name: webDomain.domain)
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration(name: webDomain.domain)
    }

    private func makeConfiguration(name: String?) -> ShieldConfiguration {
        let accent = UIColor(red: 0.98, green: 0.36, blue: 0.29, alpha: 1)
        let appName = name ?? "esta app"
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor.black.withAlphaComponent(0.6),
            icon: UIImage(systemName: "hand.raised.fill")?.withTintColor(accent, renderingMode: .alwaysOriginal),
            title: .init(text: questions.randomElement()!, color: .white),
            subtitle: .init(text: "\(appName) está en pausa. Si de verdad la necesitas, dinos para qué y te damos de 5 a 10 minutos.",
                            color: .lightGray),
            primaryButtonLabel: .init(text: "Mejor no entro", color: .white),
            primaryButtonBackgroundColor: accent,
            secondaryButtonLabel: .init(text: "Necesito entrar", color: .lightGray)
        )
    }
}
