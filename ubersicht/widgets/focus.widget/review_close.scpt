tell application "Things3"
	activate
	
	set window_count to count windows
	if window_count is greater than 0 then
		-- O comando 'close' no Things fecha todas as janelas de uma só vez
		close every window
	end if
end tell
