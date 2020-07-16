#! /usr/bin/env bats
#
# Functional tests for a DNS server set up as a test case for Ansible role
# bertvv.bind
#
# The variable SUT_IP, the IP address of the System Under Test must be set
# outside of the script.

#{{{ Helper functions

# Usage: assert_forward_lookup NAME DOMAIN IP
# Exits with status 0 if NAME.DOMAIN resolves to IP, a nonzero
# status otherwise
assert_forward_lookup() {
  local name="$1"
  local domain="$2"
  local ip="$3"

  local result
  result=$(dig @"${SUT_IP}" "${name}.${domain}" +short)

  echo "Expected: ${ip}"
  echo "Actual  : ${result}"
  [ "${ip}" = "${result}" ]
}

# Usage: assert_forward_ipv6_lookup NAME DOMAIN IP
assert_forward_ipv6_lookup() {
  local name="${1}"
  local domain="${2}"
  local ip="${3}"

  local result
  result=$(dig @"${SUT_IP}" AAAA "${name}.${domain}" +short)

  echo "Expected: ${ip}"
  echo "Actual  : ${result}"
  [ "${ip}" = "${result}" ]
}

# Usage: assert_reverse_lookup NAME DOMAIN IP
# Exits with status 0 if a reverse lookup on IP resolves to NAME,
# a nonzero status otherwise
assert_reverse_lookup() {
  local name="$1"
  local domain="$2"
  local ip="$3"

  local expected="${name}.${domain}."
  local result
  result=$(dig @"${SUT_IP}" -x "${ip}" +short)

  echo "Expected: ${expected}"
  echo "Actual  : ${result}"
  [ "${expected}" = "${result}" ]
}

# Usage: assert_alias_lookup ALIAS NAME DOMAIN IP
# Exits with status 0 if a forward lookup on NAME resolves to the
# host name NAME.DOMAIN and to IP, a nonzero status otherwise
assert_alias_lookup() {
  local alias="$1"
  local name="$2"
  local domain="$3"
  local ip="$4"
  local result
  result=$(dig @"${SUT_IP}" "${alias}.${domain}" +short)

  grep "${name}\\.${domain}\\." <<<  "${result}"
  grep "${ip}" <<< "${result}"
}

# Usage: assert_ns_lookup DOMAIN NS_NAME...
# Exits with status 0 if all specified host names occur in the list of
# name servers for the domain.
assert_ns_lookup() {
  local domain="${1}"
  shift
  local result
  result=$(dig @"${SUT_IP}" "${domain}" NS +short)

  [ -n "${result}" ] # the list of name servers should not be empty
  while (( "$#" )); do
    grep "$1\\." <<< "${result}"
    shift
  done
}

# Usage: assert_mx_lookup DOMAIN PREF1 NAME1 PREF2 NAME2...
#   e.g. assert_mx_lookup example.com 10 mailsrv1 20 mailsrv2
# Exits with status 0 if all specified host names occur in the list of
# mail servers for the domain.
assert_mx_lookup() {
  local domain="${1}"
  shift
  local result
  result=$(dig @"${SUT_IP}" "${domain}" MX +short)

  [ -n "${result}" ] # the list of name servers should not be empty
  while (( "$#" )); do
    grep "$1 $2\\.${domain}\\." <<< "${result}"
    shift
    shift
  done
}

# Usage: assert_srv_lookup DOMAIN SERVICE WEIGHT PORT TARGET
#  e.g.  assert_srv_lookup example.com _ldap._tcp 0 100 88 ldapsrv
assert_srv_lookup() {
  local domain="${1}"
  shift
  local service="${1}"
  shift
  local expected="${*}.${domain}."
  local result
  result=$(dig @"${SUT_IP}" SRV "${service}.${domain}" +short)

  echo "expected: ${expected}"
  echo "actual  : ${result}"
  [ "${result}" = "${expected}" ]
}

# Perform a TXT record lookup
# Usage: assert_txt_lookup NAME TEXT...
# e.g. assert_txt_lookup _kerberos.example.com KERBEROS.EXAMPLE.COM
assert_txt_lookup() {
  local name="$1"
  shift
  local result
  result=$(dig @"${SUT_IP}" TXT "${name}" +short)

  echo "expected: ${*}"
  echo "actual  : ${result}"
  while [ "$#" -ne "0" ]; do
    grep "${1}" <<< "${result}"
    shift
  done
}


#}}}

@test "Forward lookups acme-inc.com" {
  #                     host name  domain       IP
  assert_forward_lookup ns1        acme-inc.com 172.17.0.2
  assert_forward_lookup ns2        acme-inc.com 172.17.0.3
  assert_forward_lookup srv001     acme-inc.com 172.17.1.1
  assert_forward_lookup srv002     acme-inc.com 172.17.1.2
  assert_forward_lookup mail001    acme-inc.com 172.17.2.1
  assert_forward_lookup mail002    acme-inc.com 172.17.2.2
  assert_forward_lookup mail003    acme-inc.com 172.17.2.3
  assert_forward_lookup srv010     acme-inc.com 10.0.0.10
  assert_forward_lookup srv011     acme-inc.com 10.0.0.11
  assert_forward_lookup srv012     acme-inc.com 10.0.0.12
}

@test "Reverse lookups acme-inc.com" {
  #                     host name  domain       IP
  assert_reverse_lookup ns1        acme-inc.com 172.17.0.2
  assert_reverse_lookup ns2        acme-inc.com 172.17.0.3
  assert_reverse_lookup srv001     acme-inc.com 172.17.1.1
  assert_reverse_lookup srv002     acme-inc.com 172.17.1.2
  assert_reverse_lookup mail001    acme-inc.com 172.17.2.1
  assert_reverse_lookup mail002    acme-inc.com 172.17.2.2
  assert_reverse_lookup mail003    acme-inc.com 172.17.2.3
  assert_reverse_lookup srv010     acme-inc.com 10.0.0.10
  assert_reverse_lookup srv011     acme-inc.com 10.0.0.11
  assert_reverse_lookup srv012     acme-inc.com 10.0.0.12
}

@test "Alias lookups acme-inc.com" {
  #                   alias      hostname  domain       IP
  assert_alias_lookup www        srv001    acme-inc.com 172.17.1.1
  assert_alias_lookup mysql      srv002    acme-inc.com 172.17.1.2
  assert_alias_lookup smtp       mail001   acme-inc.com 172.17.2.1
  assert_alias_lookup mail-in    mail001   acme-inc.com 172.17.2.1
  assert_alias_lookup imap       mail003   acme-inc.com 172.17.2.3
  assert_alias_lookup mail-out   mail003   acme-inc.com 172.17.2.3

}

@test "IPv6 forward lookups acme-inc.com" {
  #                          hostname domain       IPv6
  assert_forward_ipv6_lookup srv001   acme-inc.com 2001:db8::1
  assert_forward_ipv6_lookup srv002   acme-inc.com 2001:db8::2
  assert_forward_ipv6_lookup mail001  acme-inc.com 2001:db8::d:1
  assert_forward_ipv6_lookup mail002  acme-inc.com 2001:db8::d:2
  assert_forward_ipv6_lookup mail003  acme-inc.com 2001:db8::d:3
}

@test "IPv6 reverse lookups acme-inc.com" {
  #                          hostname domain       IPv6
  assert_forward_ipv6_lookup srv001   acme-inc.com 2001:db8::1
  assert_forward_ipv6_lookup srv002   acme-inc.com 2001:db8::2
  assert_forward_ipv6_lookup mail001  acme-inc.com 2001:db8::d:1
  assert_forward_ipv6_lookup mail002  acme-inc.com 2001:db8::d:2
  assert_forward_ipv6_lookup mail003  acme-inc.com 2001:db8::d:3
}

@test "NS record lookup acme-inc.com" {
  assert_ns_lookup acme-inc.com \
    ns1.acme-inc.com \
    ns2.acme-inc.com 
}

@test "Mail server lookup acme-inc.com" {
  assert_mx_lookup acme-inc.com \
                   10 mail001 \
                   20 mail002
}

@test "Service record lookup acme-inc.com" {
  assert_srv_lookup acme-inc.com _ldap._tcp 0 100 88 srv010
}

@test "TXT record lookup acme-inc.com" {
  assert_txt_lookup _kerberos.acme-inc.com KERBEROS.ACME-INC.COM
  assert_txt_lookup acme-inc.com "some text" "more text"
}

# Tests for domain example.com


@test "Forward lookups example.com" {
  #                     host name  domain      IP
  assert_forward_lookup srv001     example.com 192.0.2.1
  assert_forward_lookup srv002     example.com 192.0.2.2
  assert_forward_lookup mail001    example.com 192.0.2.10
}

@test "Reverse lookups example.com" {
  #                     host name  domain      IP
  assert_reverse_lookup srv001     example.com 192.0.2.1
  assert_reverse_lookup srv002     example.com 192.0.2.2
  assert_reverse_lookup mail001    example.com 192.0.2.10
}

@test "Alias lookups example.com" {
  #                   alias      hostname  domain      IP
  assert_alias_lookup www        srv001    example.com 192.0.2.1
}

@test "IPv6 forward lookups example.com" {
  #                          hostname domain      IPv6
  assert_forward_ipv6_lookup srv001   example.com 2001:db9::1
}

@test "IPv6 reverse lookups example.com" {
  #                     hostname domain      IPv6
  assert_reverse_lookup srv001   example.com 2001:db9::1
}

@test "NS record lookup example.com" {
  assert_ns_lookup example.com \
    ns1.acme-inc.com \
    ns2.acme-inc.com
}

@test "Mail server lookup example.com" {
  assert_mx_lookup example.com \
                   10 mail001
}

