#! /usr/bin/env bats
#
# Acceptance test for the configuration defined in test.yml.
#
# Variable ${ns_ip} should be set outside of this script, e.g.
#
# ns_ip=192.168.56.53 bats dns.bats

domain=example.com


#{{{ Helper functions

# Perform a forward lookup
# Usage: forward_lookup HOSTNAME EXPECTED_IP
forward_lookup() {
  local result="$(dig @${ns_ip} $1.${domain} +short)"
  local expected_ip="${2}"
  echo "${result}" | grep "${expected_ip}"
}

# Perform a lookup on the domain name, assuming it
# actually points to an IP
# Usage: domain_lookup EXPECTED_IP
domain_lookup() {
  local result="$(dig @${ns_ip} ${domain} +short)"
  local expected_ip="${1}"
  echo "${result}" | grep "${expected_ip}"
}

# Perform an IPv6 (AAAA) lookup
# Usage: ipv6_lookup HOSTNAME EXPECTED_IPV6
ipv6_lookup() {
  local result="$(dig @${ns_ip} $1.${domain} AAAA +short)"
  local expected_ip="${2}"
  echo "${result}" | grep "${expected_ip}"
}

# Perform an IPv6 (AAAA) lookup on the domain name
# Usage: ipv6_lookup EXPECTED_IPV6
ipv6_domain_lookup() {
  local result="$(dig @${ns_ip} ${domain} AAAA +short)"
  local expected_ip="${1}"
  echo "${result}" | grep "${expected_ip}"
}

# Perform a forward lookup with aliases
# Usage: alias_lookup ALIAS EXPECTED_HOSTNAME EXPECTED_IP
alias_lookup() {
  local result="$(dig @${ns_ip} $1.${domain} +short)"
  local expected_hostname="${2}.${domain}."
  local expected_ip=$3
  echo ${result} | grep ${expected_ip}
  echo ${result} | grep ${expected_hostname}
}

# Perform a forward lookup with aliases
# Usage: domain_alias_lookup ALIAS EXPECTED_IP
domain_alias_lookup() {
  local result="$(dig @${ns_ip} $1.${domain} +short)"
  local expected_hostname="${domain}."
  local expected_ip=$2
  echo ${result} | grep ${expected_ip}
  echo ${result} | grep ${expected_hostname}
}

# Perform a SRV record lookup
# usage: service_lookup SERVICE TARGET PORT [PRI [WEIGHT]]
service_lookup() {
  local service="$1"
  local target="$2"
  local port="$3"
  if [ "$#" -ge "4" ]; then
    local priority="$4"
  else
    local priority="0"
  fi
  if [ "$#" -ge "5" ]; then
    local weight="$5"
  else
    local weight="0"
  fi
  local expected="${priority} ${weight} ${port} ${target}.${domain}."
  local result=$(dig @${ns_ip} srv ${service}.${domain} +short)

  echo "exp: ${expected}"
  echo "res: ${result}"
  [ "${expected}" = "${result}" ]
}

# Perform a TXT record lookup
# Usage: text_lookup NAME TEXT
text_lookup() {
  local name="$1"
  local text="$2"

  local expected="\"${text}\""
  local result=$(dig @${ns_ip} txt ${name}.${domain} +short)

  echo "exp: ${expected}"
  echo "res: ${result}"
  [ "${expected}" = "${result}" ]
}

# Perform a reverse lookup
# Usage: reverse_lookup IP EXPECTED_HOSTNAME
reverse_lookup() {
  local result="$(dig @${ns_ip} -x ${1} +short)"
  local expected="${2}.${domain}."

  echo "exp: ${expected}"
  echo "res: ${result}"
  [ "${expected}" = "${result}" ]
}

# Perform a reverse lookup where the expected result is
# the domain name.
# Usage: reverse_domain_lookup IP
reverse_domain_lookup() {
  local result="$(dig @${ns_ip} -x ${1} +short)"
  local expected="${domain}."

  echo "exp: ${expected}"
  echo "res: ${result}"
  [ "${expected}" = "${result}" ]
}

#}}}

@test 'The `dig` command should be installed' {
  which dig
}

@test 'It should return the NS record(s)' {
  result="$(dig @${ns_ip} ${domain} NS +short)"
  [ -n "${result}" ] # The result should not be empty
}

@test 'It should be able to resolve host names' {
  forward_lookup testbindmaster 192.168.56.53
  forward_lookup testbindslave  192.168.56.54

  domain_lookup                 192.168.56.20

  forward_lookup mail           192.168.56.30
  forward_lookup priv0001       172.16.0.10
  forward_lookup priv0002       172.16.0.11
}

@test 'It should be able to resolve IPv6 addresses' {
  ipv6_domain_lookup 2001:db8::20
  ipv6_lookup mail   2001:db8::30
}

@test 'It should be able to do reverse lookups' {
  reverse_domain_lookup 192.168.56.20

  reverse_lookup 192.168.56.53 testbindmaster
  reverse_lookup 192.168.56.54 testbindslave
  reverse_lookup 192.168.56.30 mail

  reverse_lookup 172.16.0.10   priv0001
  reverse_lookup 172.16.0.11   priv0002
}

@test 'It should be able to resolve aliases' {
  domain_alias_lookup www            192.168.56.20

  alias_lookup ns1    testbindmaster 192.168.56.53
  alias_lookup ns2    testbindslave  192.168.56.54

  alias_lookup smtp   mail           192.168.56.30
  alias_lookup imap   mail           192.168.56.30
}

@test 'It should return the MX record(s)' {
  result="$(dig @${ns_ip} ${domain} MX +short)"
  expected="10 mail.${domain}."

  [ "${expected}" = "${result}" ]
}

@test 'It should return the SRV record(s)' {
  service_lookup _ldap._tcp            dc001 88  0 100
  service_lookup _kerberos._tcp        dc001 88  0 100
  service_lookup _kerberos._udp        dc001 88  0 100
  service_lookup _kerberos-master._tcp dc001 88  0 100
  service_lookup _kerberos-master._udp dc001 88  0 100
  service_lookup _kpasswd._tcp         dc001 464 0 100
  service_lookup _kpasswd._udp         dc001 464 0 100
}

@test 'It should return the TXT record(s)' {
  text_lookup _kerberos KERBEROS.EXAMPLE.COM
}
