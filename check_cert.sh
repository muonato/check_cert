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
#       check_nrpe -H $HOSTADDRESS$ -c check_cert -a '/etc/pki/tls/ca/ca.crt'
#       (one certificate in nagios monitoring)
#
#       check_nrpe -H $HOSTADDRESS$ -c check_cert -a '/etc/pki/tls/ca/ca.crt /etc/pki/tls/ga.crt'
#       (two certificates in nagios monitoring)
#
function cert_expiry () {
    # Certificate path as function argument
    CPATH=$1

    # Get certificate expiration date
    CDATE=$(openssl x509 -noout -enddate -in $CPATH|grep -Po '=\K[^"]*')

    # Show as full date; same as %Y-%m-%d
    CSHOW=$(date -d "$CDATE" "+%F")

    # Expiration date to unix epoch
    CEXPR=$(date -d "$CDATE" "+%s")

    # Calculate certificate valid days left
    CLEFT=$(( ( CEXPR - TODAY )/(60*60*24) ))

    if (($CLEFT>62)); then
        echo "OK - Certificate '$CPATH' expiry '$CSHOW'"
    elif (($CLEFT>30)); then
        echo "WARNING - Certificate '$CPATH' expiry '$CSHOW'"
    elif (($CLEFT>0)); then
        echo "CRITICAL - Certificate '$CPATH' expiry '$CSHOW'"
    else
        echo "UNKNOWN - Certificate '$CPATH' is not valid"
    fi
}

# BEGIN __main__
if [[ -z "$1" ]]; then
    echo -e "Usage: \
            \n\t`basename $0` </path/to/cert> [</path/to/cert>...</path/to/cert]>]
            Accepting any number of certificates as parameters"
    exit 3
else
     CSTAT="Check expiration for ($#) certificate(s)"
fi

# Loop thru arguments
for arg in "$@"; do
     CSTAT="${CSTAT}\n$(cert_expiry $arg)"
done

# Print status
echo -e $CSTAT

# Define result conditions
WARN=$(echo -e $CSTAT|grep -om 1 "WARNING")
UNKN=$(echo -e $CSTAT|grep -om 1 "UNKNOWN")
CRIT=$(echo -e $CSTAT|grep -om 1 "CRITICAL")

# Apply result exit codes
if [[ -n $UNKN ]]; then
    exit 3
elif [[ -n $CRIT ]]; then
    exit 2
elif [[ -n $WARN ]]; then
    exit 1
else
    exit 0
fi
