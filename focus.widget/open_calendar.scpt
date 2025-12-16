tell application "Calendar"
	activate
	switch view to week view
	tell application "System Events"
		keystroke "0" using {command down}
		# centrado
		keystroke "c" using {option down, control down}
	end tell
end tell

