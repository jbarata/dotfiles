set totalUnread to 0
tell application "Mail"
  set allAccounts to every account
  repeat with eachAccount in allAccounts
    set unreadInAccount to unread count of (every mailbox of eachAccount whose name is not "Spam" and name is not "Junk" and name is not "Inbox")
    repeat with unreadCount in unreadInAccount
      set totalUnread to totalUnread + unreadCount
    end repeat
  end repeat
end tell
return totalUnread
