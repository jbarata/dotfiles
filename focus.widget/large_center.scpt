tell application "System Events"
	tell process "Things3"
		# fecha outras janelas
		keystroke "h" using {command down, option down}
		# dois terços 
		keystroke "t" using {option down, control down} 
		# centrado
		keystroke "c" using {option down, control down}
	end tell
end tell

