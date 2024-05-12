//
//  File.swift
//  BarCall
//
//  Created by Jason T Alborough on 5/11/24.
//

import SwiftUI
import ServiceManagement
import LaunchAtLogin

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    var calendar = ObtpCalendar()
    @Published var joinButtonColor: Color = .yellow
    @Published var showDate: Bool = UserDefaults.standard.bool(forKey: "ShowDate")
   
    var joinButtonColorBinding: Binding<Color> {
        Binding(
            get: { self.joinButtonColor },
            set: { self.joinButtonColor = $0 }
        )
    }
    
    var showDateBinding: Binding<Bool> {
        Binding(
            get: { self.showDate },
            set: { self.showDate = $0 }
        )
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let colorHex = UserDefaults.standard.string(forKey: "JoinButtonColor") {
            joinButtonColor = Color(hex: colorHex) ?? .yellow
        }
        showDate = UserDefaults.standard.bool(forKey: "ShowDate")
        
        setupMenuBarItem()
    }
    
    func setupMenuBarItem() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        
        let contentView = EventListView(
            calendar: calendar,
            joinButtonColor: joinButtonColorBinding, // Pass the joinButtonColor binding
            showDate: showDateBinding, // Pass the showDate binding
            appDelegate: self
        )
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem.button {
            let symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 32, weight: .regular)
            let iconImage = NSImage(systemSymbolName: "11.square", accessibilityDescription: "Calendar")?.withSymbolConfiguration(symbolConfiguration)
            button.image = iconImage
            
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusBarItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                let contentView = EventListView(
                    calendar: calendar,
                    joinButtonColor: joinButtonColorBinding, // Pass the joinButtonColor binding
                    showDate: showDateBinding, // Pass the showDate binding
                    appDelegate: self
                )
                popover.contentViewController = NSHostingController(rootView: contentView)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}
