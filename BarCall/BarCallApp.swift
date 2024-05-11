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
    @State private var joinButtonColor: Color = .yellow

    init() {
        if let colorHex = UserDefaults.standard.value(forKey: "JoinButtonColor") as? Color. {
            _joinButtonColor = State(initialValue: colorHex )
        }
    }

    var body: some Scene {
        MenuBarExtra(calendar.NextEvent, content: {
            EventListView(calendar: calendar, joinButtonColor: $joinButtonColor)
        })
        .menuBarExtraStyle(.window)
    }
}



struct EventListView: View {
    @Environment(\.openURL) var openURL
    @ObservedObject var calendar: ObtpCalendar
    @Binding var joinButtonColor: Color
    @State private var showingSettings = false
    @State private var dismissSettings = false
    
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
                EventRowView(event: event, joinButtonColor: $joinButtonColor)
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
        
        HStack {
            Button("Settings") {
                showingSettings = true
            }
            .buttonStyle(PlainButtonStyle()) // Text-only button style
            //.foregroundColor(.blue) // Optional: Change text color
            .padding(10)
            .popover(isPresented: $showingSettings) {
                SettingsView(calendar: calendar, joinButtonColor: $joinButtonColor)
            }
            Spacer() // Pushes the button to the left
        }

        // Your other content here
        Spacer()



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
    @Binding var joinButtonColor: Color
    @Environment(\.openURL) var openURL
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // ...
            
            HStack {
                Text(event.Title)
                Spacer()
                if let url = event.Url {
                    Button("Join") { openURL(url) }
                        .buttonStyle(.borderedProminent)
                        .tint(joinButtonColor)
                        .preferredColorScheme(.dark)
                }
            }
            
            // ...
        }
        // ...
    }
}



