import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var model: AppModel

    private struct DayGroup {
        let day: Date
        let sessions: [SessionRecord]
    }

    private var groupedByDay: [DayGroup] {
        let grouped = Dictionary(grouping: model.sessions) { Calendar.current.startOfDay(for: $0.date) }
        return grouped
            .map { DayGroup(day: $0.key, sessions: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        List {
            ForEach(groupedByDay, id: \.day) { group in
                Section {
                    ForEach(group.sessions) { SessionRow(session: $0) }
                } header: {
                    let total = group.sessions.reduce(0) { $0 + $1.minutes }
                    Text("\(group.day.formatted(date: .complete, time: .omitted)) · \(group.sessions.count) veces · \(total) min")
                }
            }
        }
        .navigationTitle("Historial")
        .overlay {
            if model.sessions.isEmpty {
                ContentUnavailableView("Sin historial", systemImage: "clock",
                                       description: Text("Todavía no has desbloqueado ninguna app."))
            }
        }
    }
}
