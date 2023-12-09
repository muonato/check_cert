#!/usr/bin/env bash
#
# muonato/check_cert.sh @ GitHub (DEC-2023)
#
# Reports ssl certificate(s) expiration date using openssl,
# compatible with Nagios monitoring as host plugin
#
# Usage:
#       bash check_cert.sh <path-to-cert> [<path-to-cert>...<path-to-cert>]
#
#       Nagios nrpe configuration on host :
#       command[check_cert]=/path/to/plugins/check_cert.sh $ARG1$
#
# Parameters:
#       1: Path to ssl certificate file
#
# Examples:
#       $ bash check_cert.sh /etc/pki/tls/cert.pem
#       (basic usage for single certificate on host)
#
#       check_nrpe -H $HOSTADDRESS$ -c check_cert -a '/etc/pki/tls/ca/ca.crt /etc/pki/tls/ga.crt'
#       (two certificates in nagios monitoring)
#
function cert_expiry () {
    # Certificate path as function argument
    CPATH=$1

    # Get certificate expiration date ignoring errors
    CDATE=$(openssl x509 -noout -enddate -in $CPATH 2>/dev/null|grep -Po '=\K[^"]*')

    # Show as full date; same as %Y-%m-%d
    CSHOW=$(date -d "$CDATE" "+%F")

    # Expiration date to unix epoch
    CEXPR=$(date -d "$CDATE" "+%s")

    # Today as unix epoch
    TODAY=$(date '+%s')

    # Count certification valid days left
    CLEFT=$(( ( CEXPR - TODAY )/(60*60*24) ))

    if (($CLEFT>60)); then
        echo "OK - Certificate '$CPATH' expires $CSHOW (in $(( $CLEFT / 30 )) months)"
    elif (($CLEFT>30)); then
        echo "WARNING - Certificate '$CPATH' expires $CSHOW (in $CLEFT days)"
    elif (($CLEFT>0)); then
        echo "CRITICAL - Certificate '$CPATH' expires $CSHOW (in $CLEFT days)"
    else
        echo "UNKNOWN - Certificate '$CPATH' is not valid"
    fi
}

# BEGIN __main__
if [[ -z "$1" ]]; then
    echo -e "check ssl certificate expiry\n\tUsage:\
    `basename $0` </path/to/cert> [</path/to/cert>...</path/to/cert]>]\n
    \tmissing path to certificate
            "
    exit 3
else
     CSTAT=""
fi

# Loop thru arguments
for arg in "$@"; do
    CSTAT="${CSTAT}$(cert_expiry $arg)\n"
done

# Status excl. line feed
echo -e ${CSTAT%??}

# Apply exit code corresponding to expiry status message
if [[ -n $(echo -e $CSTAT|grep -om 1 "UNKNOWN") ]]; then
    exit 3
elif [[ -n $(echo -e $CSTAT|grep -om 1 "CRITICAL") ]]; then
    exit 2
elif [[ -n $(echo -e $CSTAT|grep -om 1 "WARNING") ]]; then
    exit 1
else
    exit 0
fi
