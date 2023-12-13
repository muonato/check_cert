# check_cert
Nagios monitoring compatible SSL certificate expiry check

## Usage
```
check_cert.sh </path/to/certificate> [</path/to/certificate>] ...
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
1: CRITICAL - Certificate '/etc/pki/tls/server.pem' expires 2023-12-31 (in 22 days)
```

Check expiry of three certificates

```
$ ./check_cert.sh /etc/pki/tls/ca/server.pem /etc/pki/tls/cert.pem /etc/pki/tls/ssl.crt
1: CRITICAL - Certificate '/etc/pki/tls/server.pem' expires 2023-12-31 (in 22 days)
2: OK - Certificate '/etc/pki/tls/cert.pem' expires 2030-12-31 (in 85 months)
3: CRITICAL - Certificate '/etc/pki/tls/ssl.crt' is invalid
```
Check non-existent certificate

```$ ./check_cert.sh /foo/bar/file
1: UNKNOWN - Certificate '/foo/bar/file' openssl failed
```
