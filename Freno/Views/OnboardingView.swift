import SwiftUI
import FamilyControls

struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showPicker = false
    @State private var selection = FamilyActivitySelection()
    @State private var notificationsAsked = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.frenoAccent)
                    Text("Freno")
                        .font(.largeTitle.bold())
                    Text("Cada vez que abras Instagram, TikTok o la app que elijas, Freno te preguntará por qué entras y te dará de 5 a 10 minutos. Después, se vuelve a bloquear sola.")
                        .foregroundStyle(.secondary)
                }

                step(number: 1,
                     title: "Permitir Tiempo de uso",
                     detail: "Freno usa la función Tiempo de uso de Apple para bloquear apps. Tus datos no salen de tu teléfono.",
                     done: model.isAuthorized) {
                    Button("Dar permiso") { Task { await model.requestAuthorization() } }
                }

                step(number: 2,
                     title: "Elegir apps a frenar",
                     detail: "Selecciona Instagram, TikTok, YouTube, etc. También puedes elegir la categoría \"Redes sociales\" completa.",
                     done: model.blockedCount > 0) {
                    Button(model.blockedCount > 0 ? "Cambiar (\(model.blockedCount) elegidas)" : "Elegir apps") {
                        selection = model.selection
                        showPicker = true
                    }
                    .disabled(!model.isAuthorized)
                }

                step(number: 3,
                     title: "Activar notificaciones",
                     detail: "Las usamos para avisarte cuando te queda 1 minuto y para llevarte a Freno desde la pantalla de bloqueo.",
                     done: notificationsAsked) {
                    Button("Activar") {
                        Task {
                            _ = await Notifier.requestAuthorization()
                            notificationsAsked = true
                        }
                    }
                }

                Button {
                    model.finishOnboarding()
                } label: {
                    Text("Activar Freno")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!model.isAuthorized || model.blockedCount == 0)
            }
            .padding(24)
        }
        .familyActivityPicker(isPresented: $showPicker, selection: $selection)
        .onChange(of: selection) { _, newValue in model.updateSelection(newValue) }
    }

    @ViewBuilder
    private func step<Action: View>(number: Int, title: String, detail: String, done: Bool,
                                    @ViewBuilder action: () -> Action) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle().fill(done ? Color.green : Color.frenoAccent.opacity(0.15))
                if done {
                    Image(systemName: "checkmark").font(.headline).foregroundStyle(.white)
                } else {
                    Text("\(number)").font(.headline).foregroundStyle(Color.frenoAccent)
                }
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
                if !done { action().buttonStyle(.bordered).padding(.top, 4) }
            }
        }
    }
}
