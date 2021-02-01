#!/bin/bash

arch=$(/usr/bin/arch)
dmgfile="googlechrome.dmg"
volname="Google Chrome"
logfile="/Library/Logs/GoogleChromeInstallScript.log"
intelUrl='https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg'
appleSiliconUrl='https://dl.google.com/chrome/mac/universal/stable/GGRO/googlechrome.dmg'

# Check if file exists, if it goes kill chrome and delete.
chrome="/Applications/Google Chrome.app"
if [ -d "$chrome" ]; then
    pkill -f Chrome
	rm -rf "$chrome"
fi

/bin/echo "--" >> ${logfile}
/bin/echo "`date`: Check Architecture and Download latest version." >> ${logfile}
	if [ "$arch" == "arm64" ]; then
		echo "arm64 - Downloading Apple Silicon Version" >> ${logfile}
		/usr/bin/curl -s -o /tmp/${dmgfile} ${appleSiliconUrl} >> ${logfile}
	elif [ "$arch" == "i386" ]; then
		echo "Intel - Downloading Intel Version" >> ${logfile}
		/usr/bin/curl -s -o /tmp/${dmgfile} ${intelUrl} >> ${logfile}
	else
		echo "Unknown Architecture" >> ${logfile}
	fi
/bin/echo "'date': Mounting installer disk image." >> ${logfile}
/usr/bin/hdiutil attach /tmp/${dmgfile} -nobrowse -quiet >> ${logfile}
/bin/echo "`date`: Installing..." >> ${logfile}
/bin/cp -pPR "/Volumes/${volname}/Google Chrome.app" "/Applications/Google Chrome.app" >> ${logfile}
/bin/sleep 5
/bin/echo "`date`: Unmounting installer disk image." >> ${logfile}
/usr/bin/hdiutil detach $(/bin/df | /usr/bin/grep "${volname}" | awk '{print $1}') -quiet >> ${logfile}
/bin/sleep 5
/bin/echo "`date`: Deleting disk image." >> ${logfile}
/bin/rm /tmp/"${dmgfile}" >> ${logfile}

exit 0