//
//  SettingsView.swift
//  BarCall
//
//  Created by Jason T Alborough on 5/11/24.
//

import SwiftUI
import LaunchAtLogin

struct SettingsView: View {
    @ObservedObject var calendar: ObtpCalendar
    @Binding var joinButtonColor: Color
    @Environment(\.presentationMode) var presentationMode
    
    let predefinedColors: [Color] = [.yellow, .blue, .green, .purple]
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                        .padding(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            
            Form {
                Section(header: Text("General")) {
                    LaunchAtLogin.Toggle()
                    Button(action: {
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            NSApplication.shared.terminate(nil)
                        }
                    }) {
                        Text("Quit")
                        Image(systemName: "xmark.circle")
                    }
                }
                
                Section(header: Text("Join Button Color")) {
                    HStack {
                        ForEach(predefinedColors, id: \.self) { color in
                            Button(action: {
                                joinButtonColor = color
                                saveJoinButtonColor(color)
                            }) {
                                Rectangle()
                                    .fill(color)
                                    .frame(width: 30, height: 15)
                            }
                        }
                        
                        ColorPicker("", selection: $joinButtonColor)
                            .labelsHidden()
                            .frame(width: 30, height: 30)
                            .onChange(of: joinButtonColor) { newColor in
                                saveJoinButtonColor(newColor)
                            }
                    }
                }
                
                if !calendar.availableCalendars.isEmpty {
                    Section(header: Text("Calendars")) {
                        ScrollView {
                            VStack(alignment: .leading) {
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
                    }
                }
            }
        }
        .padding()
        .frame(width: 400, height: 500)
    }
    
    private func saveJoinButtonColor(_ color: Color) {
        UserDefaults.standard.set(color., forKey: "JoinButtonColor")
    }
}
