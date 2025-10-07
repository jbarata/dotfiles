set now to current date
set endOfDay to (current date)
set time of endOfDay to 86399 -- 23:59:59

tell application "Calendar"
	set eventCount to 0
	set allCalendars to every calendar
	repeat with aCalendar in allCalendars
		set todaysEvents to (every event of aCalendar where its start date is greater than or equal to now and its start date is less than or equal to endOfDay)
		set eventCount to eventCount + (count of todaysEvents)
	end repeat
	return eventCount
end tell