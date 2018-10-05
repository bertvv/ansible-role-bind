# Ansible role `bind`

[![Build Status](https://travis-ci.org/bertvv/ansible-role-bind.svg?branch=master)](https://travis-ci.org/bertvv/ansible-role-bind)

An Ansible role for setting up BIND ISC as an **authoritative-only** DNS server for multiple domains on EL7 or Ubuntu Server. Specifically, the responsibilities of this role are to:

- install BIND
- set up the main configuration file
    - master server
    - slave server
- set up forward and reverse lookup zone files

This role supports multiple forward and reverse zones, including for IPv6. Although enabling recursion is supported (albeit *strongly* discouraged), consider using another role if you want to set up a caching or forwarding name server.

Configuring the firewall is not a concern of this role, so you should do this using another role (e.g. [bertvv.rh-base](https://galaxy.ansible.com/bertvv/rh-base/)).

If you like/use this role, please consider giving it a star. Thanks!

See the [change log](CHANGELOG.md) for notable changes between versions.

## Requirements

- **The package `python-ipaddr` should be installed on the management node** (since v3.7.0)

## Role Variables

Variables are not required, unless specified.

| Variable                     | Default                          | Comments (type)                                                                                                             |
| :---                         | :---                             | :---                                                                                                                        |
| `bind_acls`                  | `[]`                             | A list of ACL definitions, which are dicts with fields `name` and `match_list`. See below for an example.                   |
| `bind_allow_query`           | `['localhost']`                  | A list of hosts that are allowed to query this DNS server. Set to ['any'] to allow all hosts                                |
| `bind_allow_recursion`       | `['any']`                        | Similar to bind_allow_query, this option applies to recursive queries.                                                      |
| `bind_check_names`           | `[]`                             | Check host names for compliance with RFC 952 and RFC 1123 and take the defined actioni (e.g. `warn`, `ignore`, `fail`). |
| `bind_dnssec_enable`         | `true`                           | Is DNSSEC enabled                                                                                                           |
| `bind_dnssec_validation`     | `true`                           | Is DNSSEC validation enabled                                                                                                |
| `bind_extra_include_files`   | `[]`                             |                                                                                                                             |
| `bind_forward_only`          | `false`                          | If `true`, BIND is set up as a caching name server                                                                          |
| `bind_forwarders`            | `[]`                             | A list of name servers to forward DNS requests to.                                                                          |
| `bind_listen_ipv4`           | `['127.0.0.1']`                  | A list of the IPv4 address of the network interface(s) to listen on. Set to ['any'] to listen on all interfaces.            |
| `bind_listen_ipv6`           | `['::1']`                        | A list of the IPv6 address of the network interface(s) to listen on                                                         |
| `bind_log`                   | `data/named.run`                 | Path to the log file                                                                                                        |
| `bind_query_log`             | -                                | When defined (e.g. `data/query.log`), this will turn on the query log                                                       |
| `bind_recursion`             | `false`                          | Determines whether requests for which the DNS server is not authoritative should be forwarded†.                             |
| `bind_rrset_order`           | `random`                         | Defines order for DNS round robin (either `random` or `cyclic`)                                                             |
| `bind_zone_dir`              | -                                | When defined, sets a custom absolute path to the server directory (for zone files, etc.) instead of the default.            |
| `bind_zone_domains`          | n/a                              | A list of domains to configure, with a seperate dict for each domain, with relevant details                                 |
| `- allow_update`             | `['none']`                       | A list of hosts that are allowed to dynamically update this DNS zone.                                                       |
| `- also_notify`              | -                                | A list of servers that will receive a notification when the master zone file is reloaded.                                   |
| `- delegate`                 | `[]`                             | Zone delegation. See below this table for examples.                                                                         |
| `- hostmaster_email`         | `hostmaster`                     | The e-mail address of the system administrator for the zone                                                                 |
| `- hosts`                    | `[]`                             | Host definitions. See below this table for examples.                                                                        |
| `- ipv6_networks`            | `[]`                             | A list of the IPv6 networks that are part of the domain, in CIDR notation (e.g. 2001:db8::/48)                              |
| `- mail_servers`             | `[{name: mail, preference: 10}]` | A list of dicts (with fields `name` and `preference`) specifying the mail servers for this domain.                          |
| `- name_servers`             | `[ansible_hostname]`             | A list of the DNS servers for this domain.                                                                                  |
| `- name`                     | `example.com`                    | The domain name                                                                                                             |
| `- networks`                 | `['10.0.2']`                     | A list of the networks that are part of the domain                                                                          |
| `- other_name_servers`       | `[]`                             | A list of the DNS servers outside of this domain.                                                                           |
| `- services`                 | `[]`                             | A list of services to be advertized by SRV records                                                                          |
| `- text`                     | `[]`                             | A list of dicts with fields `name` and `text`, specifying TXT records. `text` can be a list or string.                      |
| `bind_zone_file_mode`        | 0640                             | The file permissions for the main config file (named.conf)                                                                  |
| `bind_zone_master_server_ip` | -                                | **(Required)** The IP address of the master DNS server.                                                                     |
| `bind_zone_minimum_ttl`      | `1D`                             | Minimum TTL field in the SOA record.                                                                                        |
| `bind_zone_time_to_expire`   | `1W`                             | Time to expire field in the SOA record.                                                                                     |
| `bind_zone_time_to_refresh`  | `1D`                             | Time to refresh field in the SOA record.                                                                                    |
| `bind_zone_time_to_retry`    | `1H`                             | Time to retry field in the SOA record.                                                                                      |
| `bind_zone_ttl`              | `1W`                             | Time to Live field in the SOA record.                                                                                       |

† Best practice for an authoritative name server is to leave recursion turned off. However, [for some cases](http://www.zytrax.com/books/dns/ch7/queries.html#allow-query-cache) it may be necessary to have recursion turned on.

### Minimal variables for a working zone

Even though only variable `bind_zone_master_server_ip` is required for the role to run without errors, this is not sufficient to get a working zone. In order to set up an authoritative name server that is available to clients, you should also at least define the following variables:

| Variable                     | Master | Slave |
| :---                         | :---:  | :---: |
| `bind_zone_domains`          | V      | V     |
| `  - name`                   | V      | V     |
| `  - networks`               | V      | --    |
| `  - name_servers`           | V      | --    |
| `  - hosts`                  | V      | --    |
| `bind_listen_ipv4`           | V      | V     |
| `bind_allow_query`           | V      | V     |

### Domain definitions

```Yaml
bind_zone_domains:
  - name: mydomain.com
    hosts:
      - name: pub01
        ip: 192.0.2.1
        ipv6: 2001:db8::1
        aliases:
          - ns
      - name: '@'
        ip:
          - 192.0.2.2
          - 192.0.2.3
        ipv6:
          - 2001:db8::2
          - 2001:db8::3
        aliases:
          - www
      - name: priv01
        ip: 10.0.0.1
    networks:
      - '192.0.2'
      - '10'
      - '172.16'
    delegate:
      - zone: foo
        dns: 192.0.2.1
    services:
      - name: _ldap._tcp
        weight: 100
        port: 88
        target: dc001
```

### Minimal slave configuration

```Yaml
    bind_listen_ipv4: ['any']
    bind_allow_query: ['any']
    bind_zone_master_server_ip: 192.168.111.222
    bind_zone_domains:
      - name: example.com
```

### Hosts

Host names that this DNS server should resolve can be specified in `hosts` as a list of dicts with fields `name`, `ip` and `aliases`

To allow to surf to http://example.com/, set the host name of your web server to `'@'` (must be quoted!). In BIND syntax, `@` indicates the domain name itself.

If you want to specify multiple IP addresses for a host, add entries to `bind_zone_hosts` with the same name (e.g. `priv01` in the code snippet). This results in multiple A/AAAA records for that host and allows [DNS round robin](http://www.zytrax.com/books/dns/ch9/rr.html), a simple load balancing technique. The order in which the IP addresses are returned can be configured with role variable `bind_rrset_order`.

### Networks

As you can see, not all hosts are in the same network. This is perfectly acceptable, and supported by this role. All networks should be specified in `networks` (part of bind_zone_domains.name dict), though, or the host will not get a PTR record for reverse lookup:

Remark that only the network part should be specified here! When specifying a class B IP address (e.g. "172.16") in a variable file, it must be quoted. Otherwise, the Yaml parser will interpret it as a float.

Based on the idea and examples detailed at <https://linuxmonk.ch/wordpress/index.php/2016/managing-dns-zones-with-ansible/> for the gdnsd package, the zonefiles are fully idempotent, and thus only get updated if "real" content changes.

### Zone delgation

To delegate a zone to a DNS, it is enough to create a `NS` record (under delegate) which is the equivalent of:

```
foo IN NS 192.0.2.1
```

### Service records

Service (SRV) records can be added with the services. Tis should be a list of dicts with mandatory fields `name` (service name), `target` (host providing the service), `port` (TCP/UDP port of the service) and optional fields `priority` (default = 0) and `weight` (default = 0).

### ACLs

ACLs can be defined like this:

```Yaml
bind_acls:
  - name: acl1
    match_list:
      - 192.0.2.0/24
      - 10.0.0.0/8
```

The names of the ACLs will be added to the `allow-transfer` clause in global options.

## Dependencies

No dependencies. If you want to configure the firewall, do this through another role (e.g. [bertvv.rh-base](https://galaxy.ansible.com/bertvv/rh-base)).

## Example Playbook

See the test playbook [test.yml](https://github.com/bertvv/ansible-role-bind/blob/docker-tests/test.yml) for an elaborate example that showcases most features.

## Testing

There are two test environments for this role, one based on Vagrant, the other on Docker. The latter powers the Travis-CI tests. The tests are kept in a separate (orphan) branch so as not to clutter the actual code of the role. [git-worktree(1)](https://git-scm.com/docs/git-worktree) is used to include the test code into the working directory. Remark that this requires at least Git v2.5.0.

### Running Docker tests

1. Fetch the test branch: `git fetch origin docker-tests`
2. Create a Git worktree for the test code: `git worktree add docker-tests docker-tests`. This will create a directory `docker-tests/`

The script `docker-tests.sh` will create a Docker container, and apply this role from a playbook `test.yml`. The Docker images are configured for testing Ansible roles and are published at <https://hub.docker.com/r/bertvv/ansible-testing/>. There are images available for several distributions and versions. The distribution and version should be specified outside the script using environment variables:

```
DISTRIBUTION=centos VERSION=7 ./docker-tests/docker-tests.sh
```

The specific combinations of distributions and versions that are supported by this role are specified in `.travis.yml`.

The first time the test script is run, a container will be created that is assigned the IP address 172.17.0.2. This will be the master DNS-server. The server is still running after the script finishes and can be queried from the command line, e.g.:

```
$ dig @172.17.0.2 www.acme-inc.com +short
srv001.acme-inc.com.
172.17.1.1
```

If you run the script again, a new container is launched with IP address 172.17.0.3 that will be set up as a slave DNS-server. After a few seconds, it will have received updates from the master server and can be queried as well.

```
$ dig @172.17.0.3 www.acme-inc.com +short
srv001.acme-inc.com.
172.17.1.1
```

The script `docker-tests/functional-tests.sh` will run a [BATS](https://github.com/sstephenson/bats) test suite, `dns.bats` that performs a number of different queries. Specify the server IP address as the environment variable `${SUT_IP}` (short for System Under Test).

```
$ SUT_IP=172.17.0.2 ./docker-tests/functional-tests.sh
### Using BATS executable at: /usr/local/bin/bats
### Running test /home/bert/CfgMgmt/roles/bind/tests/dns.bats
 ✓ Forward lookups public servers
 ✓ Reverse lookups
 ✓ Alias lookups public servers
 ✓ IPv6 forward lookups
 ✓ NS record lookup
 ✓ Mail server lookup
 ✓ Service record lookup
 ✓ TXT record lookup

8 tests, 0 failures
$ SUT_IP=172.17.0.3 ./docker-tests/functional-tests.sh
[...]
```

### Running Vagrant tests

1. Fetch the tests branch: `git fetch origin vagrant-tests`
2. Create a Git worktree for the test code: `git worktree add vagrant-tests vagrant-tests`. This will create a directory `vagrant-tests/`.
3. `cd vagrant-tests/`
4. `vagrant up` will then create two VMs and apply a test playbook (`test.yml`).

The command `vagrant up` results in a setup with *two* DNS servers, a master and a slave, set up according to playbook `test.yml`.

| **Hostname**     | **ip**        |
| :---             | :---          |
| `testbindmaster` | 192.168.56.53 |
| `testbindslave`  | 192.168.56.54 |

IP addresses are in the subnet of the default VirtualBox Host Only network interface (192.168.56.0/24). You should be able to query the servers from your host system. For example, to verify if the slave is updated correctly, you can do the following:

```ShellSession
$ dig @192.168.56.54 ns1.example.com +short
testbindmaster.example.com.
192.168.56.53
$ dig @192.168.56.54 example.com www.example.com +short
web.example.com.
192.168.56.20
192.168.56.21
$ dig @192.168.56.54 MX example.com +short
10 mail.example.com.

```

An automated acceptance test written in [BATS](https://github.com/sstephenson/bats.git) is provided that checks most settings specified in `vagrant-tests/test.yml`. You can run it by executing the shell script `vagrant-tests/runtests.sh`. The script can be run on either your host system (assuming you have a Bash shell), or one of the VMs. The script will download BATS if needed and run the test script `vagrant-tests/dns.bats` on both the master and the slave DNS server.

```ShellSession
$ cd vagrant-tests
$ vagrant up
[...]
$ ./runtests.sh
Testing 192.168.56.53
✓ The `dig` command should be installed
✓ It should return the NS record(s)
✓ It should be able to resolve host names
✓ It should be able to resolve IPv6 addresses
✓ It should be able to do reverse lookups
✓ It should be able to resolve aliases
✓ It should return the MX record(s)

6 tests, 0 failures
Testing 192.168.56.54
✓ The `dig` command should be installed
✓ It should return the NS record(s)
✓ It should be able to resolve host names
✓ It should be able to resolve IPv6 addresses
✓ It should be able to do reverse lookups
✓ It should be able to resolve aliases
✓ It should return the MX record(s)

6 tests, 0 failures
```

Running from the VM:

```ShellSession
$ vagrant ssh testbindmaster
Last login: Sun Jun 14 18:52:35 2015 from 10.0.2.2
Welcome to your Packer-built virtual machine.
[vagrant@testbindmaster ~]$ /vagrant/runtests.sh
Testing 192.168.56.53
 ✓ The `dig` command should be installed
[...]
```

## License

BSD

## Contributors

This role could only have been realized thanks to the contributions of many. If you have an idea to improve it even further, don't hesitate to pitch in!

Issues, feature requests, ideas, suggestions, etc. can be posted in the Issues section.

Pull requests are also very welcome. Please create a topic branch for your proposed changes. If you don't, this will create conflicts in your fork after the merge. Don't hesitate to add yourself to the contributor list below in your PR!

- [Angel Barrera](https://github.com/angelbarrera92)
- [B. Verschueren](https://github.com/bverschueren)
- [Bert Van Vreckem](https://github.com/bertvv/) (Maintainer)
- [Brad Durrow](https://github.com/bdurrow)
- [Christopher Hicks](http://www.chicks.net/)
- [David J. Haines](https://github.com/dhaines)
- [Fazle Arefin](https://github.com/fazlearefin)
- [Greg Cockburn](https://github.com/gergnz)
- [Guillaume Darmont](https://github.com/gdarmont)
- [Joanna Delaporte](https://github.com/jdelaporte)
- [Jose Taas](https://github.com/josetaas)
- [Jörg Eichhorn](https://github.com/jeichhorn)
- [Loic Dachary](http://dachary.org)
- [Mario Ciccarelli](https://github.com/kartone)
- [Peter Janes](https://github.com/peterjanes)
- [Rafael Bodill](https://github.com/rafi)
- [Stuart Knight](https://github.com/blofeldthefish)
- [Tom Meinlschmidt](https://github.com/tmeinlschmidt)
