# check_cert
Nagios monitoring compatible SSL certificate expiry date check
## Usage
`check_cert </path/to/certificate> [</path/to/certificate>] ...`
## Nagios monitoring setup
Specify command in your nrpe configuration file on host :
`command[check_cert]=/path/to/plugins/check_cert.sh $ARG1$`

Set command on your nagios monitoring server
`check_nrpe -H $HOSTADDRESS$ -c check_cert -a '/etc/pki/tls/ca/cert.pem'`
