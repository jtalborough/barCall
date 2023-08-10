
import EventKit
import SwiftUI

class ObtpCalendar : ObservableObject {
    
    init(){
        checkCalendarAuthorizationStatus()
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { timer in
            self.getEvents()
        }
    }
    var timer = Timer()
    let eventCalander = EKEventStore()
    @Published var MyEvents = [Events]()
    @Published var NextEvent: String = ""
    @Published var tryList = [Events]()
    @Published var active: Bool = true

    func getNextEventTitle() -> String {
        var title: String
        if MyEvents.isEmpty {
            title = "No more events for today"
        } else {
            let now = Date()
            let eventStartTime = MyEvents[0].Event.startDate
            let timeDifference = Calendar.current.dateComponents([.minute], from: now, to: eventStartTime!).minute ?? 0

            if timeDifference <= 10 {
                // Prepend a bell icon if the event starts within 10 minutes
                title = "🔔 " + MyEvents[0].Title + " • " + MyEvents[0].RelativeStartTime
            } else {
                title = MyEvents[0].Title + " • " + MyEvents[0].RelativeStartTime
            }
        }
        return title
    }

    func getEvents() {
        // Create a predicate
        guard let interval = Calendar.current.dateInterval(of: .day, for: Date()) else { return }
        let predicate = eventCalander.predicateForEvents(withStart: interval.start, end: interval.end, calendars: nil)

        // Fetch the events
        let events = eventCalander.events(matching: predicate)
        let sortedEvents = events.sorted { a, b in a.startDate < b.startDate }

        MyEvents.removeAll()
        for tempevent in sortedEvents {
            if tempevent.endDate.timeIntervalSinceNow > 0 && !tempevent.isAllDay {

                /*
                let currentDate = Date()
                let eventDate = tempevent.startDate!

                // Calculate the difference between the two dates
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: currentDate, to: eventDate)

                // Format the difference using DateComponentsFormatter
                let formatter = DateComponentsFormatter()
                formatter.allowedUnits = [.hour, .minute]
                formatter.unitsStyle = .full
                formatter.maximumUnitCount = 2 // Display at most 2 units (e.g., 1 hour, 45 minutes)
                let relativeDate = formatter.string(from: components) ?? ""
                */
                
                let newEvent = Events(title: tempevent.title, startTime: formatRelativeTime(to: tempevent.startDate), event: tempevent)
                
                let location = tempevent.location

                if location != nil && location!.contains("http") {
                    newEvent.Url = URL(string: location!)
                }
                else {
                    newEvent.Url = URL(string: extractTeamsURL(from: tempevent.notes ?? "") ?? "")
                }

                MyEvents.append(newEvent)
                //print(tempevent.title!, "at", relativeDate)
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
    
    func extractTeamsURL(from text: String) -> String? {
        let pattern = "<(https://teams\\.microsoft\\.com/l/meetup-join/[^>]+)>"
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
                eventCalander.requestFullAccessToEvents(completion: )
                {
                    granted, error in
                    if (granted)
                    {
                        self.eventCalander.reset()
                        self.getEvents()
                    }
                }
            }
        }
        else
        {
            if(EKEventStore.authorizationStatus(for: EKEntityType.event) != EKAuthorizationStatus.authorized)
            {
                eventCalander.requestAccess(to: .event)
                {
                    granted, error in
                    if (granted)
                    {
                        self.eventCalander.reset()
                        self.getEvents()
                    }
                }
            }
            
        }
    }
        
}

class Events : ObservableObject
{
    
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


