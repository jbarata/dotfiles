// To compile (Universal Binary):
// swiftc next-event.widget/GetNextEvent.swift -o next-event.widget/GetNextEvent_x86_64 -target x86_64-apple-macosx12.0 && swiftc next-event.widget/GetNextEvent.swift -o next-event.widget/GetNextEvent_arm64 -target arm64-apple-macosx12.0 && lipo -create -output next-event.widget/GetNextEvent next-event.widget/GetNextEvent_x86_64 next-event.widget/GetNextEvent_arm64 && rm next-event.widget/GetNextEvent_x86_64 next-event.widget/GetNextEvent_arm64

import Foundation
import EventKit

let store = EKEventStore()
let sema = DispatchSemaphore(value: 0)

func fetchEvents() {
    let now = Date()
    // Look back 10 minutes to catch recently started events
    let searchStart = now.addingTimeInterval(-5 * 60)
    
    // Look until end of today
    let startOfDay = Calendar.current.startOfDay(for: now)
    guard let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else {
        print("None")
        sema.signal()
        return
    }

    let allowedCalendarTitles: Set<String> = ["MM@CoB", "MM@Home"]
    let calendars = store.calendars(for: .event).filter { allowedCalendarTitles.contains($0.title) }
    if calendars.isEmpty {
        print("None")
        sema.signal()
        return
    }
    let predicate = store.predicateForEvents(withStart: searchStart, end: endDate, calendars: calendars)
    
    let events = store.events(matching: predicate)
    
    // Filter: start date >= searchStart
    // This allows events that started recently to appear
    let candidateEvents = events.filter { $0.startDate >= searchStart }
    
    let sortedEvents = candidateEvents.sorted { $0.startDate < $1.startDate }
    
    if let nextEvent = sortedEvents.first {
        let title = nextEvent.title ?? "No Title"
        let safeTitle = title.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "~", with: "-")
        
        let location = nextEvent.location ?? ""
        let safeLocation = location.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "~", with: "-")
        
        let isAllDay = nextEvent.isAllDay
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let startStr = df.string(from: nextEvent.startDate)
        
        print("\(safeTitle)~\(startStr)~\(safeLocation)~\(isAllDay)")
    } else {
        print("None")
    }
    sema.signal()
}

if #available(macOS 14.0, *) {
    store.requestFullAccessToEvents { (granted, error) in
        if granted {
            fetchEvents()
        } else {
            print("Access denied")
            sema.signal()
        }
    }
} else {
    store.requestAccess(to: .event) { (granted, error) in
        if granted {
            fetchEvents()
        } else {
            print("Access denied")
            sema.signal()
        }
    }
}

sema.wait()
