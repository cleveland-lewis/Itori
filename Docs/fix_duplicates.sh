#!/bin/bash

# Remove duplicate settings view files from macOSApp directory
echo "Removing duplicate files from macOSApp directory..."

rm -f "macOSApp/Views/CalendarSettingsView.swift"
rm -f "macOSApp/Views/GeneralSettingsView.swift"
rm -f "macOSApp/Views/InterfaceSettingsView.swift"
rm -f "macOSApp/Views/Settings/NotificationsSettingsView.swift"
rm -f "macOSApp/Views/StorageSettingsView.swift"
rm -f "macOSApp/Views/TimerSettingsView.swift"
rm -f "macOSApp/Scenes/SettingsRootView.swift"

echo "Duplicate files removed."
echo "Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ItoriApp-*

echo "Done. Ready to rebuild."
