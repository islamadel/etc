#!/bin/bash
# Islam Adel
# Compare Versions
# Install Check Script

# 2022-01-21

#######################

latest_version="70"
app="Thunderbird.app"

version_plist="/Applications/${app}/Contents/Info.plist"
if [ -f "${version_plist}" ]; then
	installed_version="$(defaults read "${version_plist}" CFBundleShortVersionString | awk '{print $1}')"
else
	installed_version="0"
fi

#######################

#compare versions
version_compare() {
	if [[ $1 == $2 ]]; then
		return 0
	fi
	local IFS=.
	local i ver1=($1) ver2=($2)
	
	# if second parameter is empty, return 3
	[[ -z "${2}" ]] && return 3
	
	# fill empty fields in ver1 with zeros
	for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
	do
		ver1[i]=0
	done
	for ((i=0; i<${#ver1[@]}; i++))
	do
		if [[ -z "${ver2[i]}" ]]
		then
			# fill empty fields in ver2 with zeros
			ver2[i]=0
		fi
	declare -i a
	a=10${ver1[i]}
	declare -i b
	b=10${ver2[i]}
	
	if (( ${a} > ${b} ))
	then
		return 1
	fi
	if (( ${a} < ${b} ))
	then
		return 2
	fi
	done
	return 0
}

echo "### Installed Version is: ${installed_version}"
echo "### Latest Version is: ${latest_version}"
# Check if Installed Version number is smaller than latest version number
# Condition for Setup
version_compare ${installed_version} ${latest_version}
case $? in
	0) op='=';;
	1) op='higher';;
	2) op='lower';;
	3) op='missing parameters';;
esac
echo "### op : $op"
if [[ "$op" == "lower" ]] || [[ "$op" == "missing parameters" ]]; then
	echo "installed version: ${installed_version} is older than latest version: ${latest_version} !"
	exit 0
elif [[ "$op" == "higher" ]]; then
	echo "installed version: ${installed_version} is newer than latest version: ${latest_version} !"
	exit 1
else
	echo "### up-to-date."
	exit 1
fi

exit 1
