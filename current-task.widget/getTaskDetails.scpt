tell application "System Events" to (name of processes) contains "Things3"

if result is true then
	tell application "Things3"
		set OList to to dos of list "Today"
		set theTodo to missing value
		repeat with aTodo in OList
			if status of aTodo is open then
				set theTodo to aTodo
				exit repeat
			end if
		end repeat
		
		if theTodo is missing value then
			return ""
		end if
		
		set theAreaName to ""
		set theNotesText to ""
		
		set theTaskName to name of the theTodo
		set theId to id of the theTodo

		try
			set theProject to the project of the theTodo
			set theProjectName to the name of theProject
			set theArea to the area of theProject
			set theAreaName to the name of theArea
		on error errStr number errorNumber
			#Uma vez que o primeiro iteam do Today não pertence a um projecto vamos assumir que o item é um projecto
			set theProjectName to name of theTodo
			try
				#tentamos agora obter a lista de to dos
				set projectTodos to to dos of the theTodo
				#se foi possível é porque é mesmo um projecto e logo não tem tarefa
				set theTaskName to ""
			on error errStr number errorNumber
				#se falhou é porque era mesmo só uma tarefa
				set theProjectName to ""
			end try
			try
				set theArea to the area of the theTodo
				set theAreaName to the name of theArea
			end try
		end try
		
		set theTagsList to the tag names of the theTodo
		
		
		if notes of theTodo is not "" then
			set theNotesText to notes of theTodo
			set AppleScript's text item delimiters to {return & linefeed, return, linefeed, character id 8233, character id 8232}
			set newText to text items of theNotesText
			set AppleScript's text item delimiters to {"§"}
			set newText to newText as text
			set theNotesText to newText
		end if
		
		set message to theAreaName & "~" & theProjectName & "~" & theTaskName & "~" & theTagsList & "~" & theNotesText & "~" & theId
		
		set AppleScript's text item delimiters to {"\""}
		set message to text items of message
		set AppleScript's text item delimiters to {"'"}
		set message to message as text
	end tell
else
	return "No focus (Things closed)!"
end if
