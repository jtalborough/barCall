import SwiftUI
import ServiceManagement
import LaunchAtLogin

@main
struct OBTPApp: App {
    @StateObject var calendar = ObtpCalendar()

    let timeFormat = DateFormatter()

    var body: some Scene {
        MenuBarExtra(calendar.NextEvent, content: {
            EventListView(calendar: calendar)
        })
        .menuBarExtraStyle(.window)
    }
}

struct EventListView: View {
    @Environment(\.openURL) var openURL
    @ObservedObject var calendar: ObtpCalendar
    @State private var showingSettings = false
    @State private var startBusinessHour: Date
    @State private var endBusinessHour: Date

    init(calendar: ObtpCalendar) {
        _startBusinessHour = State(initialValue: UserDefaults.standard.object(forKey: "startBusinessHour") as? Date ?? Date())
        _endBusinessHour = State(initialValue: UserDefaults.standard.object(forKey: "endBusinessHour") as? Date ?? Date())
        self.calendar = calendar
    }

    var body: some View {
        VStack(spacing: 5) {
            // Display current date
            Text(currentDate())
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(currentWeek())
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.bottom, 5)

            ForEach(calendar.MyEvents, id: \.Uuid) { event in
                EventRowView(event: event)
            }

        }
        .padding(10)
        //.border(Color.white).padding(5)
        Menu("Availability") {
            Button("Today") {
                let availability = calendar.getAvailability(for: .today)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(availability, forType: .string)
            }
            Button("Next 3 Days") {
                let availability = calendar.getAvailability(for: .nextThreeDays)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(availability, forType: .string)
            }
            Button("Next 5 Days") {
                let availability = calendar.getAvailability(for: .nextFiveDays)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(availability, forType: .string)
            }
            Button("Next 10 Days") {
                let availability = calendar.getAvailability(for: .nextTenDays)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(availability, forType: .string)
            }
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .padding(10)
        Divider()
        Menu("Settings") {
            LaunchAtLogin.Toggle()
            Divider()
            Button("Business Hours") {
                showingSettings = true
            }
            Divider()
            Button(action: {
                NSApplication.shared.terminate(self)
            }) {
                Text("Quit")
                Image(systemName: "xmark.circle")
            }
            Divider()
            if !calendar.availableCalendars.isEmpty {
                Text("Calendars")
                    .font(.headline)
                ForEach(calendar.availableCalendars.keys.sorted(), id: \.self) { calendarName in
                    Toggle(isOn: Binding(
                        get: { self.calendar.availableCalendars[calendarName, default: false] },
                        set: { self.calendar.availableCalendars[calendarName] = $0 }
                    )) {
                        Text(calendarName)
                    }
                }
            }
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .padding(10)
        .sheet(isPresented: $showingSettings) {
            SettingsView(startBusinessHour: $startBusinessHour, endBusinessHour: $endBusinessHour)
        }
    }

    func currentDate() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return "\(formatter.string(from: date))"
    }

    func currentWeek() -> String {
        let date = Date()

        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: date)

        return "Week \(weekOfYear)"
    }
}

struct EventRowView: View {
    let event: Events
    @Environment(\.openURL) var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(event.Title)
                Spacer()
                if let url = event.Url {
                    Button("Join") { openURL(url) }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.yellow).colorMultiply(.yellow)
                        .preferredColorScheme(.dark)
                }
            }
            Text("\(event.StartTime) - \(event.EndTime)")
                .font(.caption)
        }
        .padding(10)
        .background(Color.secondary.opacity(0.1)) // Optional: Add a background color to each row
        .cornerRadius(5) // Optional: Add corner radius to the row
        .padding(.vertical, 5) // Optional: Adjust vertical padding between rows
    }
}


import SwiftUI

struct SettingsView: View {
    @Binding var startBusinessHour: Date
    @Binding var endBusinessHour: Date
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Business Hours")
                .font(.headline)
                .padding()

            Divider()

            HStack {
                Text("Start Time")
                Spacer()
                DatePicker("", selection: $startBusinessHour, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .onChange(of: startBusinessHour) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "startBusinessHour")
                    }
            }
            .padding()

            HStack {
                Text("End Time")
                Spacer()
                DatePicker("", selection: $endBusinessHour, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .onChange(of: endBusinessHour) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "endBusinessHour")
                    }
            }
            .padding()

            Spacer()

            Button("Close") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
        .frame(width: 300, height: 200)
        .padding()
    }
}

struct SettingsView_Previews: PreviewProvider {
    @State static var startBusinessHour = Date()
    @State static var endBusinessHour = Date()

    static var previews: some View {
        SettingsView(startBusinessHour: $startBusinessHour, endBusinessHour: $endBusinessHour)
    }
}
