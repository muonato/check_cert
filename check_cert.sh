#!/usr/bin/env bash
#
# muonato/check_cert.sh @ GitHub (2023-12-10)
#
# Reports ssl certificate(s) expiration date using openssl,
# compatible with Nagios monitoring as host plugin
#
# Usage:
#       bash check_cert.sh <path-to-cert> [<path-to-cert>] ...
#
#       Nagios nrpe configuration on host :
#       command[check_cert]=/path/to/plugins/check_cert.sh $ARG1$
#
# Parameters:
#       1: Path to ssl certificate file
#
# Examples:
#       $ bash check_cert.sh /path/to/cert.pem
#       (single certificate on host)
#
#       check_nrpe -H $HOSTADDRESS$ -c check_cert -a '/path/to/cert.pem /path/to/ssl.crt'
#       (nagios monitoring for two certificates)
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

    # Count certificate valid days left
    CLEFT=$(( ( CEXPR - TODAY )/(60*60*24) ))

    # Return status message
    if [[ -z "$CDATE" ]]; then
        echo "UNKNOWN - Certificate '$CPATH' openssl error"
    elif [[ $CLEFT -ge 60 ]]; then
        echo "OK - Certificate '$CPATH' expires '$CSHOW' (in $(( $CLEFT / 30 )) months)"
    elif [[ $CLEFT -ge 30 ]]; then
        echo "WARNING - Certificate '$CPATH' expires '$CSHOW' (in $CLEFT days)"
    elif [[ $CLEFT -ge 0 ]]; then
        echo "CRITICAL - Certificate '$CPATH' expires '$CSHOW' (in $CLEFT days)"
    else
        echo "UNKNOWN - Certificate '$CPATH'"
    fi
}

# BEGIN __main__
if [[ -z "$1" ]]; then
    echo -e "check ssl certificate expiry\n\tUsage:\
    `basename $0` </path/to/cert> [</path/to/cert>...</path/to/cert]>]\n
    \tERROR: missing path to certificate
            "
    exit 3
else
     CSTAT=""
fi

# Loop args for status message
for (( i=1; i<=$#; i++ )); do
    CSTAT="${CSTAT}${i}: $(cert_expiry ${@:i:1})\n"
done

# Print status excl. newline
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
