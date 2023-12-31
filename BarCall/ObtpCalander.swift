
import EventKit
import SwiftUI

class ObtpCalendar : ObservableObject {
    
    init(){
        checkCalendarAuthorizationStatus()
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { timer in
            self.getEvents()
        }
        loadCalendarSelections()
    }
    
    var timer = Timer()
    let eventCalendar = EKEventStore()
    @Published var MyEvents = [Events]()
    @Published var NextEvent: String = ""
    @Published var tryList = [Events]()
    @Published var active: Bool = true
    @Published var availableCalendars: [String: Bool] = [:] {
        didSet {
            saveCalendarSelections()
        }
    }
    
    private func loadCalendarSelections() {
        // Fetch available calendars from UserDefaults and update availableCalendars
        var savedCalendars = [String: Bool]()
        if let savedSelections = UserDefaults.standard.dictionary(forKey: "calendarSelections") as? [String: Bool] {
            savedCalendars = savedSelections
        }

        // Fetch all calendars from the event calendar
        let newCalendars = eventCalendar.calendars(for: .event)
        for calendar in newCalendars {
            // Add the new calendar to savedCalendars if it's not already present
            if savedCalendars[calendar.title] == nil {
                savedCalendars[calendar.title] = true
            }
        }

        // Update the availableCalendars with the merged data
        availableCalendars = savedCalendars
    }

    
    func getNextEventTitle() -> String {
        var title: String
        let now = Date()

        // Find the current event, if any
        let currentEvent = MyEvents.first { event in
            let eventStartTime = event.Event.startDate!
            let eventEndTime = event.Event.endDate!
            return now >= eventStartTime && now <= eventEndTime
        }

        // Find the next event, if any
        let nextEvent = MyEvents.first { event in
            return event.Event.startDate! > now
        }

        // Calculate time difference for the next event
        let nextEventTimeDifference = nextEvent != nil ? Calendar.current.dateComponents([.minute], from: now, to: nextEvent!.Event.startDate!).minute ?? 0 : nil

        if let currentEvent = currentEvent {
            title = currentEvent.Title

            // Check if there's a next event starting within 10 minutes
            if let nextEvent = nextEvent, nextEventTimeDifference! <= 10 {
                title = "🔔 " + nextEvent.Title + " • " + nextEvent.RelativeStartTime
            }
        } else if let nextEvent = nextEvent {
            // Prepend a bell icon if the next event starts within 10 minutes
            title = nextEventTimeDifference! <= 10 ? "🔔 " : ""
            title += nextEvent.Title + " • " + nextEvent.RelativeStartTime
        } else {
            title = "No more events for today"
        }

        return title
    }




    func getEvents() {
        // Create a predicate
        guard let interval = Calendar.current.dateInterval(of: .day, for: Date()) else { return }
       
        let allCalendars = eventCalendar.calendars(for: .event)
        // Filter out the enabled calendars based on their titles
        let enabledCalendars = allCalendars.filter { calendar in
            self.availableCalendars[calendar.title] ?? false
        }
        
        let predicate = eventCalendar.predicateForEvents(withStart: interval.start, end: interval.end, calendars: enabledCalendars)

        // Fetch the events
        let events = eventCalendar.events(matching: predicate)
        let sortedEvents = events.sorted { a, b in a.startDate < b.startDate }

        MyEvents.removeAll()
        for tempevent in sortedEvents {
            
            if tempevent.endDate.timeIntervalSinceNow > 0 && !tempevent.isAllDay {
                
                print("Debug: tempEvent.title = \(String(describing: tempevent.title))")
                
                let newEvent = Events(title: tempevent.title, startTime: formatRelativeTime(to: tempevent.startDate), event: tempevent)
                
                let location = tempevent.location
                print("Debug: location = \(String(describing: tempevent.location))") //

                if let location = location, location.contains("http") {
                    if let httpIndex = location.range(of: "http")?.lowerBound {
                        let substringFromHttp = String(location[httpIndex...])
                        if let endIndex = substringFromHttp.rangeOfCharacter(from: CharacterSet(charactersIn: " ;\n"))?.lowerBound {
                            let firstUrl = String(substringFromHttp[..<endIndex])
                            newEvent.Url = URL(string: firstUrl)
                        } else {
                            newEvent.Url = URL(string: substringFromHttp)
                        }
                    }
                }  else {
                    // print("Debug: tempEvent.notes = \(String(describing: tempevent.notes))") // Debugging line
                    let extractedURL = extractMeetingURL(from: tempevent.notes ?? "") ?? ""
                    print("Debug: extractedURL = \(extractedURL)") // Debugging line
                    newEvent.Url = URL(string: extractedURL)
                }

                print("Debug: extractedURL = \(String(describing: newEvent.Url))") //

                MyEvents.append(newEvent)

            }
        }
        NextEvent = getNextEventTitle()
    }

    enum TimeFormat {
        case exact
        case fuzzy
    }

    func formatRelativeTime(to eventDate: Date, format: TimeFormat = .fuzzy) -> String {
        let currentDate = Date() // Get the current date directly within the function
        
        // Calculate the difference between the two dates
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: currentDate, to: eventDate)

        var hours = components.hour ?? 0
        var minutes = components.minute ?? 0

        if format == .fuzzy {
            // Round minutes to the nearest 5
            minutes = (minutes + 2) / 5 * 5
            if minutes == 60 {
                hours += 1
                minutes = 0
            }
        }

        // Format the difference using DateComponentsFormatter
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 2 // Display at most 2 units (e.g., 1 hour, 45 minutes)

        if let formattedString = formatter.string(from: DateComponents(hour: hours, minute: minutes)) {
            if eventDate < currentDate {
                // If the eventDate is in the past
                return format == .fuzzy ? "about \(formattedString.replacingOccurrences(of: "-", with: "")) ago" : "\(formattedString.replacingOccurrences(of: "-", with: "")) ago"
            } else {
                // If the eventDate is in the future
                return format == .fuzzy ? "about \(formattedString)" : "in \(formattedString)"
            }
        }
        return ""
    }
    
    func extractMeetingURL(from text: String) -> String? {
        let pattern = "(https://(?:teams\\.microsoft\\.com|zoom\\.us|meet\\.google\\.com|goto\\.webex\\.com)/[^\\s>]+)"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: text.utf16.count)
        if let match = regex?.firstMatch(in: text, options: [], range: range),
           let urlRange = Range(match.range(at: 1), in: text) {
            let url = String(text[urlRange])
            return url
        }
        return nil
    }

    
    func checkCalendarAuthorizationStatus() {
        if #available(macOS 14, *)
        {
            if(EKEventStore.authorizationStatus(for: EKEntityType.event) != EKAuthorizationStatus.fullAccess)
            {
                eventCalendar.requestFullAccessToEvents(completion: )
                {
                    granted, error in
                    if (granted)
                    {
                        self.eventCalendar.reset()
                        self.getEvents()
                    }
                }
            }
        }
        else
        {
            if(EKEventStore.authorizationStatus(for: EKEntityType.event) != EKAuthorizationStatus.authorized)
            {
                eventCalendar.requestAccess(to: .event)
                {
                    granted, error in
                    if (granted)
                    {
                        self.eventCalendar.reset()
                        self.getEvents()
                    }
                }
            }
            
        }
    }
    private func saveCalendarSelections() {
        UserDefaults.standard.set(availableCalendars, forKey: "calendarSelections")
    }
}

class Events: ObservableObject, Equatable {
    static func == (lhs: Events, rhs: Events) -> Bool {
        return lhs.Uuid == rhs.Uuid
    }

    init(title: String, startTime: String, event: EKEvent){
        Title = title
        RelativeStartTime = startTime
        Event = event
        timeFormat.dateFormat = "h:mm a"
        StartTime = timeFormat.string(from: event.startDate)
        EndTime = timeFormat.string(from: event.endDate)
    }
    private let timeFormat = DateFormatter()
    @Published var Title: String = ""
    @Published var RelativeStartTime: String = ""
    @Published var Url: URL?
    @Published var Event: EKEvent
    @Published var StartTime: String
    @Published var EndTime: String
    @Published var Uuid: UUID = UUID()
}


