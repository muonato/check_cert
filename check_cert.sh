#!/usr/bin/env bash
#
# muonato/check_cert.sh @ GitHub (02-DEC-2025)
#
# Reports SSL certificate(s) expiration date or revocation
#
# Usage:
#       bash check_cert.sh -f '</path/to/file> [</path/to/file>]'
#
#       Nagios nrpe configuration on host :
#       command[check_cert]=/path/to/plugins/check_cert.sh $ARG1$
#
# Arguments:
#       -f : String of certificate paths
#
# Options:
#       -h : Display help
#       -w : Warning alert threshold in days, default: 60
#       -c : Critical alert threshold in days, default: 30
#
# Examples:
#       1. Expiry warning alert when 90 days remain
#
#           $ bash check_cert.sh -f "/path/to/cert.pem" -w 90
#
#       2. Nagios monitoring expression for two certificates
#
#           check_nrpe -H $HOSTADDRESS$ -c check_cert \
#               -a '-f "/path/to/cert.pem /path/to/ssl.crt" -w 90'
#

function help() {
        cat <<EOF
Usage: $(basename "$0") -f "</path/to/cert> ... [/path/to/cert]"> [OPTIONS]

OPTIONS
    -f string of file paths
    -h display this help menu
    -w warning alert in days
    -c critical alert in days

EOF
}

function cert_query () {
    # Certificate path as function argument
    CPATH=$1

    # Inspect CRL occurrence on first line
    ISCRL=$(sed -n '1p' $CPATH 2>/dev/null|grep -o "CRL")

    if [[ -z "$ISCRL" ]]; then
        PARAM="x509 -enddate"
        CFUNC="expiry"
    else
        PARAM="crl -nextupdate"
        CFUNC="revocation"
    fi

    # Get the status - suppress error messages
    CDATE=$(openssl $PARAM -noout -in $CPATH 2>/dev/null|grep -Po '=\K[^"]*')

    # Show as full date; same as %Y-%m-%d
    CSHOW=$(date -d "$CDATE" "+%F")

    # Expiration date to unix epoch
    CEXPR=$(date -d "$CDATE" "+%s")

    # Today as unix epoch
    TODAY=$(date '+%s')

    # Count days left to due date
    CLEFT=$(( ( CEXPR - TODAY )/(60*60*24) ))

    # Return status message
    if [[ -z "$CDATE" ]]; then
        echo "UNKNOWN - Certificate '$CPATH' $CFUNC"
    elif [[ $CLEFT -ge $WARN ]]; then
        echo "OK - Certificate '$CPATH' $CFUNC '$CSHOW' (in $(( $CLEFT / 30 )) months)"
    elif [[ $CLEFT -ge $CRIT ]]; then
        echo "WARNING - Certificate '$CPATH' $CFUNC '$CSHOW' (in $CLEFT days)"
    elif [[ $CLEFT -ge 0 ]]; then
        echo "CRITICAL - Certificate '$CPATH' $CFUNC '$CSHOW' (in $CLEFT days)"
    else
        echo "CRITICAL - Certificate '$CPATH' $CFUNC has expired"
    fi
}

# BEGIN __main__

# Alerts
WARN="60"
CRIT="30"

# Script arguments validation
while getopts "hf:w:c:" opt; do
    case "$opt" in
        h)  help; exit 0;;
        f)  CERT=$OPTARG;;
        w)  WARN=$OPTARG;;
        c)  CRIT=$OPTARG;;
    esac
done

# Path to file required
if [[ -z $CERT ]]; then
    echo "$0: certificate path missing"
    help
    exit 0
fi

# Status message
CSTAT=""

# Status ordinal
CNUMR=1

# Loop to append status message
for cer in ${CERT[@]}; do
    CSTAT="${CSTAT}${CNUMR}: $(cert_query ${cer})\n"
    ((CNUMR++))
done

# Print status excl. newline
echo -e ${CSTAT%??}

# Exit with code corresponding to status message
if [[ -n $(echo -e $CSTAT|grep -om 1 "CRITICAL") ]]; then
    exit 2
elif [[ -n $(echo -e $CSTAT|grep -om 1 "WARNING") ]]; then
    exit 1
elif [[ -n $(echo -e $CSTAT|grep -om 1 "UNKNOWN") ]]; then
    exit 3
elif [[ -n $(echo -e $CSTAT|grep -om 1 "OK") ]]; then
    exit 0
else
    echo -e "$USAGE\tERROR: unexpected failure"
    exit 3
fi
