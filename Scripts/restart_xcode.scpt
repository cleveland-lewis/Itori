#!/usr/bin/osascript

# AppleScript to properly restart Xcode with Itori project

tell application "Xcode"
	if it is running then
		quit
		delay 2
	end if
end tell

tell application "Finder"
	open POSIX file "/Users/clevelandlewis/Desktop/Itori/ItoriApp.xcodeproj"
end tell

delay 3

tell application "Xcode"
	activate
end tell

display notification "Xcode opened with Itori project" with title "Ready to Build"
