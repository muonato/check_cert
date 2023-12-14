# check_cert
Nagios monitoring compatible SSL certificate expiry and revocation list check

## Usage
```
check_cert.sh [-r] </path/to/certificate> [</path/to/certificate>] ...

Options:
    -r   revocation list
```

## Nagios monitoring setup
Specify command in your nrpe configuration file on host

```
command[check_cert]=/path/to/plugins/check_cert.sh $ARG1$
```

Set command on your nagios monitoring server

```
check_nrpe -H $HOSTADDRESS$ -c check_cert -a '/path/to/certificate.pem'
```

## Examples
Check certificate expiry date

```
$ ./check_cert.sh /etc/pki/tls/ca/server.pem
1: CRITICAL - Certificate '/etc/pki/tls/server.pem' expiry '2023-12-31' (in 22 days)
```

Check expiry of three certificates

```
$ ./check_cert.sh /etc/pki/tls/ca/server.pem /etc/pki/tls/cert.pem /etc/pki/tls/ssl.crt
1: CRITICAL - Certificate '/etc/pki/tls/server.pem' expires 2023-12-31 (in 22 days)
2: OK - Certificate '/etc/pki/tls/cert.pem' expires 2030-12-31 (in 85 months)
3: CRITICAL - Certificate '/etc/pki/tls/ssl.crt' is due
```

Check non-existent certificate

```
$ ./check_cert.sh /foo/bar/file
1: UNKNOWN - Certificate '/foo/bar/file' expiry
```

Check revocation list due date

```
$ ./check_cert.sh -r /etc/pki/tls/crl/server.pem
1: OK - Certificate '/etc/pki/tls/crl/ripa.crl.pem' revocation '2025-10-26' (in 22 months)
```
##Platform
Script development and testing
```
GNU bash, version 4.2.46(2)-release (x86_64-redhat-linux-gnu)
CentOS Linux release 7.9.2009 (Core)
OpenSSL 1.0.2k-fips 26 Jan 2017
```
