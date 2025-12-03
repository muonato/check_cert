# check_cert
Nagios monitoring compatible SSL certificate expiry and revocation list check

## Usage
```
check_cert.sh -f '</path/to/certificate> ... [</path/to/certificate>]'

Arguments:
    -f : String of certificate paths
Options:
    -h : Display help message
    -w : Warning alert in days, default: 60
    -c : Critical alert in days, default: 30
```

## Nagios monitoring setup
Specify command in your nrpe configuration file on host

```
command[check_cert]=/path/to/plugins/check_cert.sh $ARG1$
```

Set command on your nagios monitoring server

```
check_nrpe -H $HOSTADDRESS$ -c check_cert -a "-f '/path/to/certificate.pem'"
```

## Examples
Check certificate expiry date with warning alert 90 and critical in 60 days

```
$ ./check_cert.sh -f '/etc/pki/tls/ca/server.pem' -w 90 -c 60
1: CRITICAL - Certificate '/etc/pki/tls/server.pem' expiry '2023-12-31' (in 22 days)
```

Check expiry of three certificates

```
$ ./check_cert.sh -f '/etc/pki/tls/ca/server.pem /etc/pki/tls/cert.pem /etc/pki/tls/ssl.crt'
1: CRITICAL - Certificate '/etc/pki/tls/server.pem' expires 2023-12-31 (in 22 days)
2: OK - Certificate '/etc/pki/tls/cert.pem' expires 2030-12-31 (in 85 months)
3: CRITICAL - Certificate '/etc/pki/tls/ssl.crt' has expired
```

Check non-existent certificate

```
$ ./check_cert.sh /foo/bar/file
1: UNKNOWN - Certificate '/foo/bar/file' expiry
```

Check revocation list due date

```
$ ./check_cert.sh -f '/etc/pki/tls/crl/server.pem'
1: OK - Certificate '/etc/pki/tls/crl/foobar.crl.pem' revocation '2025-10-26' (in 22 months)
```
## Platform
Script development and testing
```
GNU bash, version 5.1.8(1)-release (x86_64-redhat-linux-gnu)
Red Hat Enterprise Linux 9.7 (Plow)
OpenSSL 3.5.1 1 Jul 2025
Opsview Core 3.20140409.0
```
