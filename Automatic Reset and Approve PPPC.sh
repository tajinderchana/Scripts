#!/bin/bash

# This script will reset the camera and microphone permissions for a specific application.
# this will add apps such as Zoom and Teams with pre approved permissions for the application declared
# Alernative services can be found here: https://github.com/tajinderchana/Jamf-Scripts/blob/main/TCC%20Service%20List.txt
# 

############################################
###				 variables				 ###
############################################

# If using this script in JamfPro $4 needs to be the name of the app i.e zoom.us or Microsoft Teams.
# If using this script standalone chnage from $4 to the application name i.e zoom.us
appName="Microsoft Teams"

# From the app name passed in the variable above
appBundleIdentifier=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' /Applications/"${appName}".app/Contents/Info.plist)

# Get current logged in usser
userName=$(/usr/bin/stat -f "%Su" "/dev/console")

# Get current time in epoch seconds
current_time="$(/bin/date +"%s")"

# Get current logged in user's home directory
[[ "$userName" ]] && logged_in_user_home="$(/usr/bin/dscl /Local/Default read /Users/"$userName" NFSHomeDirectory | /usr/bin/awk '{print $2}')"

app_path="/Applications/"${appName}".app"

############################################
###				 Functions				 ###
############################################

# Function to get csreq blob
getCSREQBlob(){
	# Get the requirement string from codesign
	req_str=$(/usr/bin/codesign -d -r- "$app_path" 2>&1 | /usr/bin/awk -F ' => ' '/designated/{print $2}')
	
	# Convert the requirements string into it's binary representation
	# csreq requires the output to be a file so we just throw it in /tmp
	echo "$req_str" | /usr/bin/csreq -r- -b /tmp/csreq.bin
	
	# Convert the binary form to hex, and print it nicely for use in sqlite
	req_hex="X'$(xxd -p /tmp/csreq.bin  | /usr/bin/tr -d '\n')'"
	
	echo "$req_hex"
	
	# Remove csqeq.bin
	/bin/rm -f "/tmp/csreq.bin"
}

req_hex="$(getCSREQBlob)"

function is_app_running()
{
	#If app is running call on AppleScript
	/usr/bin/pgrep -q "$appName"
	if [[ "$?" == "0" ]]; then
		echo "$appName is running. Will prompt user for permission to close"
		show_close_alert
		wasOpen="Yes"
	fi
}

function close_app()
{
	echo "Closing $appName"
	/usr/bin/pkill -HUP "$appName"
}

function show_close_alert()
{
	/usr/bin/osascript <<-EOD
	tell application "Finder"
		activate
		set DialogTitle to "$appName"
		set DialogText to "$appName needs to close to repair your Camera and Mic permission. Please select Reset Now to complete the process, $appName will quit to start this process. The app will automaticly reopen once this process has completed."
		set DialogButton to "Reset Now"
		set DialogIcon to ":System:Library:CoreServices:CoreTypes.bundle:Contents:Resources:Sync.icns"
		display dialog DialogText buttons {DialogButton} with title DialogTitle with icon file DialogIcon giving up after 900
	end tell
	EOD
	close_app
}

function show_confirm_alert()
{
	/usr/bin/osascript <<-EOD
	tell application "Finder"
		activate
		set DialogTitle to "$appName"
		set DialogText to "Camera and Mic permissions have been reset, if $appName was open it will start again "
		set DialogButton to "Done"
		set DialogIcon to ":System:Library:CoreServices:CoreTypes.bundle:Contents:Resources:Sync.icns"
		display dialog DialogText buttons {DialogButton} with title DialogTitle with icon file DialogIcon giving up after 900
	end tell
	EOD
}

function reopenApp(){
	if [ "$wasOpen" == "Yes" ];
	then
		echo "Re-opening $appName"
		sudo -u $(ls -l /dev/console | awk '{print $3}') open "/Applications/$appName.app"
	else
		exit 0
	fi
}

function resetMicrophone(){
	su - $(stat -f%Su /dev/console) -c "/usr/bin/tccutil reset Microphone $appBundleIdentifier"

}

function resetCamera(){
	su - $(stat -f%Su /dev/console) -c "/usr/bin/tccutil reset Camera $appBundleIdentifier"
}

function addMicrophone(){
	/usr/bin/sqlite3 "$logged_in_user_home/Library/Application Support/com.apple.TCC/TCC.db" "INSERT or REPLACE INTO access (service,client,client_type,allowed,prompt_count,csreq,last_modified)
			VALUES('kTCCServiceMicrophone','$appBundleIdentifier','0','1','1',$req_hex,'$current_time')"
}
function addCamera(){
	/usr/bin/sqlite3 "$logged_in_user_home/Library/Application Support/com.apple.TCC/TCC.db" "INSERT or REPLACE INTO access (service,client,client_type,allowed,prompt_count,csreq,last_modified)
			VALUES('kTCCServiceCamera','$appBundleIdentifier','0','1','1',$req_hex,'$current_time')"
	
}

############################################
###				 Working 				 ###
############################################

# Checking if the App is running
is_app_running

# Removing the Apps Microphone and Camera Approval
resetMicrophone
resetCamera

# Taking a rest
sleep 10

# Adding and approving the Camera and Microphone for the app
addCamera
addMicrophone

# Showing Confirmation
#show_confirm_alert

# Open the app again if it was open
reopenApp

exit 0