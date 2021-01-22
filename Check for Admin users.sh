#!/bin/bash

sudo su

# Script to detect if a computer has a local admin account on it with a UID
# above 500

# Don't list these admin accounts
except=('admin1' 'tajinderchana' 'localadmin3')

# Initialize array
list=()

# generate user list of users with UID greater than 500
for username in $(dscl . list /Users UniqueID | awk '$2 > 500 { print $1 }'); do
	# Checks to see which usernames are reported as being admins. The
	# check is running dsmemberutil's check membership and listing the
	# accounts that are being reported as admin users. Actual check is
	# for accounts that are NOT not an admin (i.e. not standard users.)
	if [[ $(dsmemberutil checkmembership -U "${username}" -G admin) != *not* ]] &&
		grep -qvFf <(printf '%s\n' "${except[@]}") <(echo "${username}")
	then
		# Any reported accounts are added to the array list
		list+=("${username}")
	fi
done

# Prints the array's list contents
echo ${list[@]}
