
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

            if abs(timeDifference) <= 10 {
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
                // Ask for the full relative date
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .full
                formatter.dateTimeStyle = .named

                // Get tempevent.startDate relative to the current date
                let relativeDate = formatter.localizedString(for: tempevent.startDate, relativeTo: Date())

                let newEvent = Events(title: tempevent.title, startTime: relativeDate, event: tempevent)
                let location = tempevent.location

                if location != nil && location!.contains("http") {
                    newEvent.Url = URL(string: location!)
                }
                else {
                    newEvent.Url = URL(string: extractTeamsURL(from: tempevent.notes ?? "") ?? "")

                    
                }

                MyEvents.append(newEvent)
                print(tempevent.title!, "at", relativeDate)
            }
        }
        NextEvent = getNextEventTitle()
    }

    func extractTeamsURL(from text: String) -> String? {
        let pattern = "<(https://teams\\.microsoft\\.com/l/meetup-join/[^\n]+)>"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: text.utf16.count)
        if let match = regex?.firstMatch(in: text, options: [], range: range) {
            let urlRange = match.range(at: 1)
            let startIndex = text.index(text.startIndex, offsetBy: urlRange.location - 4)
            let endIndex = text.index(startIndex, offsetBy: urlRange.length)
            let url = String(text[startIndex..<endIndex])
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


