#!/usr/bin/env bash
#
# muonato/check_cert.sh @ GitHub (23-JUL-2024)
#
# Reports SSL certificate(s) expiration date or revocation list,
# compatible with Nagios monitoring as host plugin
#
# Usage:
#       bash check_cert.sh </path/to/file> [</path/to/file>] ...
#
#       Nagios nrpe configuration on host :
#       command[check_cert]=/path/to/plugins/check_cert.sh $ARG1$
#
# Options:
#       None
#
# Examples:
#       $ bash check_cert.sh /path/to/cert.pem
#       (Certificate expiry or revocation list date)
#
#       check_nrpe -H $HOSTADDRESS$ -c check_cert -a '/path/to/cert.pem /path/to/ssl.crt'
#       (Nagios monitor expression for two certificates)
#
# Notes:
#       GNU bash, version 4.2.46(2)-release (x86_64-redhat-linux-gnu)
#       CentOS Linux release 7.9.2009 (Core)
#       OpenSSL 1.0.2k-fips 26 Jan 2017
#       Opsview Core 3.20140409.0
#
function cert_query () {
    # Certificate path as function argument
    CPATH=$1

    # Inspect CRL occurrence on first line
    ISCRL=$(sed -n '1p' $CPATH|grep -o "CRL")

    if [[ -z "$ISCRL" ]]; then
        PARAM="x509 -enddate"
        CFUNC="expiry"
    else
        PARAM="crl -nextupdate"
        CFUNC="revocation"
    fi

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
    `basename $0` [-r] </path/to/cert> [</path/to/cert> ...>]\n"

# Validate arguments
if [[ -z "$1" ]]; then
    echo -e $USAGE
    exit 3
fi

# Status message
CSTAT=""

# Status ordinal
CNUMR=1

# Loop args to append status message
for (( i=1; i<=$#; i++ )); do
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
