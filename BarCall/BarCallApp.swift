//
//  OBTPApp.swift
//  OBTP
//
//  Created by Jason T Alborough on 6/25/23.
//

import SwiftUI
//import EventKit

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


import SwiftUI

struct EventListView: View {
    @Environment(\.openURL) var openURL
    @ObservedObject var calendar: ObtpCalendar
    
    var body: some View {
        VStack(spacing: 5) {
            // Display current date
            Text(currentDate())
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
            
            ForEach(calendar.MyEvents, id: \.Uuid) { event in
                EventRowView(event: event)
            }
        }
        .padding(10)
    }
    
    func currentDate() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        
        return "\(formatter.string(from: date)) | Week \(weekOfYear)"
    }
}




struct EventRowView: View {
    let event: Events
    @Environment(\.openURL) var openURL
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Button(action: {
                // Open the Calendar app at today's date
                let url = URL(string: "calshow:")!
                openURL(url)
            }) {
                HStack {
                    Text(event.Title)
                    Spacer()
                    if let url = event.Url {
                        Button("Join") { openURL(url) }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.green)
                    }

                }
            }
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



