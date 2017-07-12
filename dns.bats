#! /usr/bin/env bats
#
# Functional tests for a DNS server set up as a test case for Ansible role
# bertvv.bind
#
# The variable SUT_IP, the IP address of the System Under Test must be set
# outside of the script.

domain='acme-inc.com'

#{{{ Helper functions

# Usage: assert_forward_lookup NAME IP
# Exits with status 0 if NAME.DOMAIN resolves to IP, a nonzero
# status otherwise
assert_forward_lookup() {
  local name="$1"
  local ip="$2"

  local result="$(dig @${SUT_IP} ${name}.${domain} +short)"

  echo "Expected: ${ip}"
  echo "Actual  : ${result}"
  [ "${ip}" = "${result}" ]
}

# Usage: assert_forward_ipv6_lookup NAME IP
assert_forward_ipv6_lookup() {
  local name="${1}"
  local ip="${2}"

  local result="$(dig @${SUT_IP} AAAA ${name}.${domain} +short)"

  echo "Expected: ${ip}"
  echo "Actual  : ${result}"
  [ "${ip}" = "${result}" ]
}

# Usage: assert_reverse_lookup NAME IP
# Exits with status 0 if a reverse lookup on IP resolves to NAME,
# a nonzero status otherwise
assert_reverse_lookup() {
  local name="$1"
  local ip="$2"

  local expected="${name}.${domain}."
  local result="$(dig @${SUT_IP} -x ${ip} +short)"

  echo "Expected: ${expected}"
  echo "Actual  : ${result}"
  [ "${expected}" = "${result}" ]
}

# Usage: assert_alias_lookup ALIAS NAME IP
# Exits with status 0 if a forward lookup on NAME resolves to the
# host name NAME.DOMAIN and to IP, a nonzero status otherwise
assert_alias_lookup() {
  local alias="$1"
  local name="$2"
  local ip="$3"
  local result="$(dig @${SUT_IP} ${alias}.${domain} +short)"

  echo ${result} | grep "${name}\.${domain}\."
  echo ${result} | grep "${ip}"
}

# Usage: assert_ns_lookup NS_NAME...
# Exits with status 0 if all specified host names occur in the list of
# name servers for the domain.
assert_ns_lookup() {
  local result="$(dig @${SUT_IP} ${domain} NS +short)"

  [ -n "${result}" ] # the list of name servers should not be empty
  while (( "$#" )); do
    echo "${result}" | grep "$1\.${domain}\."
    shift
  done
}

# Usage: assert_mx_lookup PREF1 NAME1 PREF2 NAME2...
#   e.g. assert_mx_lookup 10 mailsrv1 20 mailsrv2
# Exits with status 0 if all specified host names occur in the list of
# mail servers for the domain.
assert_mx_lookup() {
  local result="$(dig @${SUT_IP} ${domain} MX +short)"

  [ -n "${result}" ] # the list of name servers should not be empty
  while (( "$#" )); do
    echo "${result}" | grep "$1 $2\.${domain}\."
    shift
    shift
  done
}

# Usage: assert_srv_lookup SERVICE WEIGHT PORT TARGET
#  e.g.  assert_srv_lookup _ldap._tcp 0 100 88 ldapsrv
assert_srv_lookup() {
  local service="${1}"
  shift
  local expected="${*}.${domain}."
  local result="$(dig @${SUT_IP} SRV ${service}.${domain} +short)"

  shift
  echo "expected: ${expected}"
  echo "actual  : ${result}"
  [ "${result}" = "${expected}" ]
}

# Perform a TXT record lookup
# Usage: assert_txt_lookup NAME TEXT...
assert_txt_lookup() {
  local name="$1"
  local result=$(dig @${SUT_IP} TXT ${name} +short)
  shift

  echo "expected: ${*}"
  echo "actual  : ${result}"
  while [ "$#" -ne "0" ]; do
    grep "${1}" <<< "${result}"
    shift
  done
}


#}}}

@test 'Forward lookups public servers' {
  #                     host name  IP
  assert_forward_lookup ns1        172.17.0.2
  assert_forward_lookup ns2        172.17.0.3
  assert_forward_lookup srv001     172.17.1.1
  assert_forward_lookup srv002     172.17.1.2
  assert_forward_lookup mail001    172.17.2.1
  assert_forward_lookup mail002    172.17.2.2
  assert_forward_lookup mail003    172.17.2.3
  assert_forward_lookup srv010     10.0.0.10
  assert_forward_lookup srv011     10.0.0.11
  assert_forward_lookup srv012     10.0.0.12
}

@test 'Reverse lookups' {
  #                     host name  IP
  assert_reverse_lookup ns1        172.17.0.2
  assert_reverse_lookup ns2        172.17.0.3
  assert_reverse_lookup srv001     172.17.1.1
  assert_reverse_lookup srv002     172.17.1.2
  assert_reverse_lookup mail001    172.17.2.1
  assert_reverse_lookup mail002    172.17.2.2
  assert_reverse_lookup mail003    172.17.2.3
  assert_reverse_lookup srv010     10.0.0.10
  assert_reverse_lookup srv011     10.0.0.11
  assert_reverse_lookup srv012     10.0.0.12
}

@test 'Alias lookups public servers' {
  #                   alias      hostname  IP
  assert_alias_lookup www        srv001    172.17.1.1
  assert_alias_lookup mysql      srv002    172.17.1.2
  assert_alias_lookup smtp       mail001   172.17.2.1
  assert_alias_lookup mail-in    mail001   172.17.2.1
  assert_alias_lookup imap       mail003   172.17.2.3
  assert_alias_lookup mail-out   mail003   172.17.2.3

}

@test 'IPv6 forward lookups' {
  assert_forward_ipv6_lookup srv001 2001:db8::1
  assert_forward_ipv6_lookup srv002 2001:db8::2
  assert_forward_ipv6_lookup mail001 2001:db8::d:1
  assert_forward_ipv6_lookup mail002 2001:db8::d:2
  assert_forward_ipv6_lookup mail003 2001:db8::d:3
}

@test 'IPv6 reverse lookups' {
  assert_reverse_lookup srv001 2001:db8::1
  assert_reverse_lookup srv002 2001:db8::2
  assert_reverse_lookup mail001 2001:db8::d:1
  assert_reverse_lookup mail002 2001:db8::d:2
  assert_reverse_lookup mail003 2001:db8::d:3
}

@test 'NS record lookup' {
  assert_ns_lookup ns1 ns2
}

@test 'Mail server lookup' {
  assert_mx_lookup 10 mail001 \
                   20 mail002
}

@test 'Service record lookup' {
  assert_srv_lookup _ldap._tcp 0 100 88 srv010
}

@test 'TXT record lookup' {
  assert_txt_lookup "_kerberos.${domain}" KERBEROS.ACME-INC.COM
  assert_txt_lookup "${domain}" "some text" "more text"
}
