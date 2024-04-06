//
//  OBTPApp.swift
//  OBTP
//
//  Created by Jason T Alborough on 6/25/23.
//

import SwiftUI
import ServiceManagement
//import EventKit
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
        }.menuStyle(BorderlessButtonMenuStyle())
            .padding(10)
        Divider()
        Menu("Settings") {
            Form {
                LaunchAtLogin.Toggle()
            }
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
           /*
            Button(action: {
                // Open the Calendar app at today's date
                let url = URL(string: "calshow:")!
                openURL(url)
            }) {
            */
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
            //}
            .buttonStyle(PlainButtonStyle()) // This makes the button look like regular text
            Text("\(event.StartTime) - \(event.EndTime)")
                .font(.caption)
        }
        .padding(10)
        .background(Color.secondary.opacity(0.1)) // Optional: Add a background color to each row
        .cornerRadius(5) // Optional: Add corner radius to the row
        .padding(.vertical, 5) // Optional: Adjust vertical padding between rows
    }
}



