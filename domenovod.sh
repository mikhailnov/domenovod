#!/usr/bin/env bash
########################################################################
# Script for configuring GNU/Linux workstations to work in domain.     #
# Currently for ROSA Linux + AD Samba/Windows domain.                  #
# Can be used as a helper for GUIs, e.g. drakxtools, or other scripts. #
# Can be sourced from other scripts to use its functions.              #
# Contributions and feedback are welcomed at                           #
# https://github.com/mikhailnov/domenovod                              #
# Authors:                                                             #
# - Mikhail Novosyolov <m.novosyolov@rosalinux.ru>                     #
########################################################################

set -ef

check_reachability(){
	if ping -c2 "$*" >/dev/null 2>/dev/null
		then return 0
		else return 1
	fi
}

get_hostname(){
	# Full hostname (e.g. kde4.samba-dc1.loc)
	hostfqdn="$(hostname --fqdn)"
	# Short hostname (e.g. kde4)
	hostname="$(hostname --short)"
	# Extracts domain name from FQDN hostname (e.g. samba-dc1.loc)
	hostdomain="$(hostname --domain)"
}

check_hostname_is_fqdn(){
	get_hostname
	temp_hostfqdn="${hostname}.${hostdomain}"
	if [ "$temp_hostfqdn" = "$hostfqdn" ]
		then return 0
		else return 1
	fi
}

get_domain_controller_address(){
	# Try to guess domain controller address assuming that it is usually a nameserver
	# First for the case when "nameserver = DNS_name",
	# where DNS_name may be resolved via e.g. /etc/hosts
	temp_nameserver="$(grep ^nameserver /etc/resolv.conf | awk '{print $2}' | grep -v '^#' | grep "\.${hostdomain}\$" | head -n 1)"
	if [ -n "$temp_nameserver" ] && check_reachability "$temp_nameserver"; then
		DC_server="$temp_nameserver"
		echo "$DC_server"
		return
	fi
	
	# TODO: don't do this if joining not AD domain
	# Try to guess DC address by IP address (assume that DC is normally a DNS server)
	while read -r nameserver_line
	do
		# timeout 2 because nmblookup is fast when address is correct and is too slow otherwise
		AD_server="$(timeout 2 nmblookup -A "$nameserver_line" | head -n 2 | tail -n 1 | cut -f2 | cut -d ' ' -f1)"
		if [ -n "$AD_server" ]; then
			if check_reachability "$AD_server"
				then DC_server="$AD_server"
				else
					if check_reachability "${AD_server}.${hostdomain}"; then
						DC_server="${AD_server}.${hostdomain}"
					fi
			fi
			echo "$DC_server"
			return
		fi
	done < <(grep ^nameserver /etc/resolv.conf | awk '{print $2}')
	
}

