import SwiftUI
import FamilyControls
import ManagedSettings

/// "¿Por qué quieres entrar?" + elegir de 5 a 10 minutos.
struct UnlockView: View {
    @EnvironmentObject private var model: AppModel

    @State private var reason = ""
    @State private var minutes = 5
    @State private var pauseRemaining = 10
    @State private var errorMessage: String?
    @State private var unlocked = false
    @FocusState private var reasonFocused: Bool

    private let suggestions = [
        "Responder un mensaje",
        "Publicar algo",
        "Ver algo que me enviaron",
        "Buscar algo puntual",
        "Estoy aburrido/a",
    ]

    private var trimmedReason: String { reason.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canUnlock: Bool { trimmedReason.count >= 3 && pauseRemaining == 0 }

    var body: some View {
        NavigationStack {
            Group {
                if unlocked { successView } else { formView }
            }
            .navigationTitle(unlocked ? "" : "Un momento")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            // Pausa obligatoria: rompe el impulso automático.
            while pauseRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                pauseRemaining -= 1
            }
        }
    }

    private var formView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let app = model.pendingApp {
                    Label(app)
                        .labelStyle(.titleAndIcon)
                        .font(.headline)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("¿Por qué quieres entrar?")
                        .font(.title2.bold())
                    TextField("Ej: responderle a mi hermana", text: $reason, axis: .vertical)
                        .lineLimit(2...4)
                        .padding(12)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                        .focused($reasonFocused)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button(suggestion) { reason = suggestion }
                                    .buttonStyle(.bordered)
                                    .font(.footnote)
                            }
                        }
                    }
                    if trimmedReason == "Estoy aburrido/a" {
                        Text("Gracias por la honestidad. ¿Y si das una vuelta, tomas agua o le escribes a alguien en vez de hacer scroll?")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("¿Cuánto tiempo?")
                        .font(.title3.bold())
                    Picker("Minutos", selection: $minutes) {
                        ForEach(5...10, id: \.self) { Text("\($0)").tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Text("Tendrás \(minutes) minutos de uso. Al cumplirse, la app se bloquea sola.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage {
                    Text(errorMessage).font(.footnote).foregroundStyle(.red)
                }

                VStack(spacing: 12) {
                    Button {
                        unlock()
                    } label: {
                        Text(pauseRemaining > 0 ? "Respira… \(pauseRemaining)" : "Desbloquear \(minutes) min")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!canUnlock)

                    Button("Mejor no entro") { model.resist() }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "timer")
                .font(.system(size: 56))
                .foregroundStyle(Color.frenoAccent)
            Text("Tienes \(minutes) minutos")
                .font(.title.bold())
            Text("Objetivo: \(trimmedReason)")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Text("Vuelve a la app y cúmplelo. Te avisaremos cuando quede 1 minuto.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            HStack {
                openButton("Instagram", url: "instagram://app")
                openButton("TikTok", url: "snssdk1233://")
            }
            Spacer()
            Button("Listo") { model.cancelUnlock() }
                .buttonStyle(.bordered)
        }
        .padding(24)
    }

    private func openButton(_ title: String, url: String) -> some View {
        Button("Abrir \(title)") {
            if let url = URL(string: url) { UIApplication.shared.open(url) }
        }
        .buttonStyle(.borderedProminent)
    }

    private func unlock() {
        reasonFocused = false
        do {
            try model.startSession(reason: trimmedReason, minutes: minutes)
            errorMessage = nil
            unlocked = true
        } catch {
            errorMessage = "No se pudo iniciar la sesión: \(error.localizedDescription)"
        }
    }
}
