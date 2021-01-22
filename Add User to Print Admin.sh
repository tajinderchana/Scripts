#!/bin/sh

loggedInUser=$(stat -f%Su /dev/console)

/usr/sbin/dseditgroup -o edit -n /Local/Default -a everyone -t group lpadmin

exit 0