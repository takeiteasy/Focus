global frontAppName

tell application "System Events"
    set frontApp to first application process whose frontmost is true
    set frontAppName to name of frontApp
end tell

return frontAppName
