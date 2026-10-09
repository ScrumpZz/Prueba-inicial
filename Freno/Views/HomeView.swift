import SwiftUI
import FamilyControls

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showPicker = false
    @State private var pickerSelection = FamilyActivitySelection()
    @State private var confirmDisable = false

    var body: some View {
        NavigationStack {
            List {
                Section { statusCard }

                Section("Hoy") {
                    HStack {
                        stat(value: "\(model.todaySessions.count)", label: "veces entraste")
                        Divider()
                        stat(value: "\(model.todayMinutes)", label: "min permitidos")
                        Divider()
                        stat(value: "\(model.todayResisted)", label: "veces resististe")
                    }
                    .padding(.vertical, 6)
                }

                Section("Últimos motivos") {
                    if model.sessions.isEmpty {
                        Text("Aquí verás por qué entraste cada vez.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(model.sessions.suffix(5).reversed())) { SessionRow(session: $0) }
                        NavigationLink("Ver todo el historial") { HistoryView() }
                    }
                }

                Section("Configuración") {
                    Button {
                        pickerSelection = model.selection
                        showPicker = true
                    } label: {
                        LabeledContent("Apps frenadas", value: "\(model.blockedCount)")
                    }
                    Toggle("Freno activado", isOn: Binding(
                        get: { model.isProtectionEnabled },
                        set: { newValue in
                            if newValue { model.setProtection(enabled: true) } else { confirmDisable = true }
                        }
                    ))
                }
            }
            .navigationTitle("Freno")
            .familyActivityPicker(isPresented: $showPicker, selection: $pickerSelection)
            .onChange(of: pickerSelection) { _, newValue in model.updateSelection(newValue) }
            .confirmationDialog("¿Desactivar Freno?", isPresented: $confirmDisable, titleVisibility: .visible) {
                Button("Desactivar", role: .destructive) { model.setProtection(enabled: false) }
                Button("Mantener activado", role: .cancel) {}
            } message: {
                Text("Tus apps quedarán sin límite. ¿Seguro que es lo que quieres?")
            }
        }
    }

    @ViewBuilder
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let session = model.activeSession {
                Label("Sesión en curso", systemImage: "timer")
                    .font(.headline)
                    .foregroundStyle(Color.frenoAccent)
                Text("\(session.minutes) min de uso para: \"\(session.reason)\"")
                HStack(spacing: 4) {
                    Text("Se bloquea a más tardar en")
                    Text(session.expiresAt, style: .timer).monospacedDigit()
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                Button("Terminar ahora y bloquear", role: .destructive) { model.endSessionNow() }
                    .buttonStyle(.bordered)
            } else if model.isProtectionEnabled {
                Label("Protegido", systemImage: "lock.shield.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                Text("Tus apps están en pausa. Al abrirlas, Freno te preguntará por qué.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Necesito entrar a una app") { model.openUnlockManually() }
                    .buttonStyle(.bordered)
            } else {
                Label("Freno desactivado", systemImage: "lock.open")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Tus apps no tienen límite ahora mismo.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title2.bold())
            Text(label).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SessionRow: View {
    let session: SessionRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(session.reason)
            Text("\(session.date.formatted(date: .abbreviated, time: .shortened)) · \(session.minutes) min")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
