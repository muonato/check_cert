#!/usr/bin/env bash
#
# muonato/check_cert.sh @ GitHub (13-DEC-2023)
#
# Reports ssl certificate(s) revocation list or expiration date,
# compatible with Nagios monitoring as host plugin
#
# Usage:
#       bash check_cert.sh [OPTIONS] <path-to-cert> [<path-to-cert>] ...
#
#       Nagios nrpe configuration on host :
#       command[check_cert]=/path/to/plugins/check_cert.sh $ARG1$
#
# Options:
#       -r  revocation list date
#
# Examples:
#       $ bash check_cert.sh /path/to/cert.pem
#       (certificate expiry date)
#
#       $ bash chech_cert.sh -r /path/to/cert.crl.pem
#       (certificate revocation list date)
#
#       check_nrpe -H $HOSTADDRESS$ -c check_cert -a '/path/to/cert.pem /path/to/ssl.crt'
#       (nagios monitor expression for two certificates)
#
function cert_query () {
    # Certificate path as function argument
    CPATH=$1

    # Get certificate due date - ignoring errors
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
    elif [[ $CLEFT -ge 30 ]]; then
        echo "OK - Certificate '$CPATH' $CFUNC '$CSHOW' (in $(( $CLEFT / 30 )) months)"
    elif [[ $CLEFT -ge 15 ]]; then
        echo "WARNING - Certificate '$CPATH' $CFUNC '$CSHOW' (in $CLEFT days)"
    elif [[ $CLEFT -ge 0 ]]; then
        echo "CRITICAL - Certificate '$CPATH' $CFUNC '$CSHOW' (in $CLEFT days)"
    else
        echo "CRITICAL - Certificate '$CPATH' $CFUNC is due"
    fi
}

# BEGIN __main__
USAGE="check ssl certificate\n\tUsage:\
    `basename $0` [-r] </path/to/cert> [</path/to/cert> ...>]\n
    \tERROR: missing path to certificate"

# Validate arguments
if [[ -z "$1" ]]; then
    echo -e $USAGE
    exit 3
elif [[ $1 == "-r" ]]; then
    PARAM="crl -nextupdate"
    CFUNC="revocation"
    INDEX=2
else
    PARAM="x509 -enddate"
    CFUNC="expiry"
    INDEX=1
fi

# Status message
CSTAT=""

# Status ordinal
CNUMR=1

# Loop args to append status message
for (( i=$INDEX; i<=$#; i++ )); do
    CSTAT="${CSTAT}${CNUMR}: $(cert_query ${@:i:1})\n"
    ((CNUMR++))
done

# Print status excl. newline
echo -e ${CSTAT%??}

# Apply exit code corresponding to status message
if [[ -n $(echo -e $CSTAT|grep -om 1 "CRITICAL") ]]; then
    exit 2
elif [[ -n $(echo -e $CSTAT|grep -om 1 "WARNING") ]]; then
    exit 1
elif [[ -n $(echo -e $CSTAT|grep -om 1 "UNKNOWN") ]]; then
    exit 3
elif [[ -n $(echo -e $CSTAT|grep -om 1 "OK") ]]; then
    exit 0
else
    echo -e $USAGE
    exit 3
fi
