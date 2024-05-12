//
//  File.swift
//  BarCall
//
//  Created by Jason T Alborough on 5/11/24.
//

import SwiftUI
import ServiceManagement
import LaunchAtLogin
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    var calendar = ObtpCalendar()
    private var cancellables = Set<AnyCancellable>()

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
        // Set default value for "ShowDate" key if it doesn't exist
        UserDefaults.standard.register(defaults: ["ShowDate": true])
        
        // Read the value of "ShowDate" from user defaults
        showDate = UserDefaults.standard.bool(forKey: "ShowDate")
        
        
        setupMenuBarItem()

        

        calendar.objectWillChange
                    .receive(on: RunLoop.main)
                    .sink { _ in
                        self.updateStatusBarIcon()
                    }
                    .store(in: &cancellables)
        // Observe changes in showDate and update the status bar icon immediately
        $showDate
            .receive(on: RunLoop.main)
            .sink { _ in
                self.updateStatusBarIcon()
            }
            .store(in: &cancellables)
            
    }
    
    func setupMenuBarItem() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        
        let contentView = EventListView(
            calendar: calendar,
            joinButtonColor: joinButtonColorBinding,
            showDate: showDateBinding,
            appDelegate: self
        )
        
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusBarItem.button {
            button.target = self
            button.action = #selector(togglePopover(_:))
            
            // Customize the button appearance
            button.image = nil
            button.title = ""
            button.imagePosition = .imageLeft
            
            // Disable button highlighting
            //button.highlight(false)
            
            updateStatusBarIcon()
        }
    }
    

    
    func updateStatusBarIcon() {
        guard let button = statusBarItem.button else { return }
        
        let dayNumber = Calendar.current.component(.day, from: Date())
        let symbolName = "\(dayNumber).square"
        
        // Get the thickness of the menu bar
        let menuBarThickness = NSStatusBar.system.thickness
        
        // Get the backing scale factor of the screen where the menu bar is located
        let screenBackingScaleFactor = button.window?.screen?.backingScaleFactor ?? 1
        
        // Calculate the point size based on the menu bar thickness and screen scale factor
        let symbolPointSize = menuBarThickness * 0.5 * screenBackingScaleFactor
        
        let symbolConfiguration = NSImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .regular)
//        symbolConfiguration.applying(.preferringMulticolor())
//        symbolConfiguration.applying(.init(hierarchicalColor: .red))
        // Check if the next event is within 10 minutes
        let isNextEventWithin10Minutes = calendar.MyEvents.first?.Event.startDate?.timeIntervalSinceNow ?? Double.infinity <= 600
        
        let iconImage = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Calendar")?
            .withSymbolConfiguration(symbolConfiguration)
        
        
        if calendar.active {
            button.image = iconImage?.tint(color: .red)
            statusBarItem.button?.contentTintColor = .red
        }
        else
        {
            button.image = iconImage?.tint(color: .clear)
            button.image = iconImage
            
        }
        
        if showDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E, MMM d"
            let dateString = dateFormatter.string(from: Date())
            button.title = calendar.NextEvent
            button.imagePosition = .imageLeft
            button.contentTintColor = .red
        } else {
            button.title = calendar.NextEvent
            button.imagePosition = .noImage
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
//class CustomStatusBarButton: NSStatusBarButton {
//    override func highlight(_ flag: Bool) {
//        // Do nothing to prevent highlighting
//    }
//}
extension NSImage {
    func tint(color: NSColor) -> NSImage {
        NSImage(size: size, flipped: false) { rect in
            color.set()
            rect.fill()
            self.draw(in: rect, from: NSRect(origin: .zero, size: self.size), operation: .destinationIn, fraction: 1.0)
            return true
        }
    }
}
