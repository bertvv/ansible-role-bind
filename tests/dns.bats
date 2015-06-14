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
  result="$(dig @${ns_ip} $1.${domain} +short)"
  expected=$2
  [ "${expected}" = "${result}" ]
}

# Perform a forward lookup with aliases
# Usage: alias_lookup ALIAS EXPECTED_HOSTNAME EXPECTED_IP
alias_lookup() {
  result="$(dig @${ns_ip} $1.${domain} +short)"
  expected_hostname="${2}.${domain}."
  expected_ip=$3
  echo ${result} | grep ${expected_ip}
  echo ${result} | grep ${expected_hostname}
}

# Perform a reverse lookup
# Usage: reverse_lookup IP EXPECTED_HOSTNAME
reverse_lookup() {
  result="$(dig @${ns_ip} -x ${1} +short)"
  expected="${2}.${domain}."
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
  forward_lookup web            192.168.56.20
  forward_lookup mail           192.168.56.21

  forward_lookup priv0001       172.16.0.10
  forward_lookup priv0002       172.16.0.11
}

@test 'It should be able to do reverse lookups' {
  reverse_lookup 192.168.56.53 testbindmaster
  reverse_lookup 192.168.56.54 testbindslave
  reverse_lookup 192.168.56.20 web
  reverse_lookup 192.168.56.21 mail

  reverse_lookup 172.16.0.10   priv0001
  reverse_lookup 172.16.0.11   priv0002
}

@test 'It should be able to resolve aliases' {
  alias_lookup ns1  testbindmaster 192.168.56.53
  alias_lookup ns2  testbindslave  192.168.56.54
  alias_lookup www  web            192.168.56.20
  alias_lookup smtp mail           192.168.56.21
  alias_lookup imap mail           192.168.56.21
}

@test 'It should return the MX record(s)' {
  result="$(dig @${ns_ip} ${domain} MX +short)"
  expected="10 mail.${domain}."

  [ "${expected}" = "${result}" ]
}
