# Ansible role `bind`

An Ansible role for setting up BIND ISC as an authoritative DNS server for a single domain. Specifically, the responsibilities of this role are to:

- install BIND
- set up the main configuration file
    - master server
    - slave server
- set up forward and reverse lookup zone files

This role supports multiple reverse zones. Forward IPv6 lookups are also supported.  [Reverse IPv6 lookups](http://www.zytrax.com/books/dns/ch3/#ipv6), as of yet, are not (See Issue #10).

Configuring the firewall is not a concern of this role, so you should do this using another role (e.g. [bertvv.el7](https://galaxy.ansible.com/list#/roles/2305)).

If you like/use this role, please consider giving it a star or reviewing it on Ansible Galaxy. Thanks!

## Requirements

- This role is written specifically for RHEL/CentOS and works on versions 6 and 7.
- The `filter_plugins` directory should be copied to `${ANSIBLE_HOME}`. It contains a few functions that manipulate IP addresses. If you forget this step, you will get the error message "`no filter named 'reverse_lookup_zone'`" in the task 'Main BIND config file'. See [~~Issue #5~~](https://github.com/bertvv/ansible-role-bind/issues/5).

## Role Variables

Variables are not required, unless specified.

| Variable                       | Default                          | Comments (type)                                                                                                  |
| :---                           | :---                             | :---                                                                                                             |
| `bind_acls`                    | `[]`                             | A list of ACL definitions, which are dicts with fields `name` and `match_list`. See below for an example.        |
| `bind_allow_query`             | `['localhost']`                  | A list of hosts that are allowed to query this DNS server. Set to ['any'] to allow all hosts                     |
| `bind_listen_ipv4`             | `['127.0.0.1']`                  | A list of the IPv4 address of the network interface(s) to listen on. Set to ['any'] to listen on all interfaces. |
| `bind_listen_ipv6`             | `['::1']`                        | A list of the IPv6 address of the network interface(s) to listen on                                              |
| `bind_log`                     | `data/named.run`                 | Path to the log file                                                                                             |
| `bind_other_name_servers`      | `[]`                             | A list of nameservers outside of the domain. For each one, an NS record will be created.                         |
| `bind_recursion`               | `false`                          | Determines whether requests for which the DNS server is not authoritative should be forwarded†.                  |
| `bind_rrset_order`             | `random`                         | Defines order for DNS round robin (either `random` or `cyclic`)                                                  |
| `bind_zone_also_notify`        | -                                | A list of servers that will receive a notification when the master zone file is reloaded.                        |
| `bind_zone_hostmaster_email`   | `hostmaster`                     | The e-mail address of the system administrator                                                                   |
| `bind_zone_hosts`              | `[]`                             | Host definitions. See below this table for examples.                                                             |
| `bind_zone_mail_servers`       | `[{name: mail, preference: 10}]` | A list of dicts (with fields `name` and `preference`) specifying the mail servers for this domain.               |
| `bind_zone_master_server_ip`   | -                                | **(Required)** The IP address of the master DNS server.                                                          |
| `bind_zone_minimum_ttl`        | `1D`                             | Minimum TTL field in the SOA record.                                                                             |
| `bind_zone_name_servers`       | `[ansible_hostname]`             | A list of the DNS servers for this domain.                                                                       |
| `bind_zone_name`               | `example.com`                    | The domain name                                                                                                  |
| `bind_zone_networks`           | `['10.0.2']`                     | A list of the networks that are part of the domain                                                               |
| `bind_zone_other_name_servers` | `[]`                             | A list of the DNS servers outside of this domain.                                                                |
| `bind_zone_services`           | `[]`                             | A list of services to be advertized by SRV records                                                               |
| `bind_zone_text`               | `[]`                             | A list of dicts with fields `name` and `text`, specifying TXT records                                            |
| `bind_zone_time_to_expire`     | `1W`                             | Time to expire field in the SOA record.                                                                          |
| `bind_zone_time_to_refresh`    | `1D`                             | Time to refresh field in the SOA record.                                                                         |
| `bind_zone_time_to_retry`      | `1H`                             | Time to retry field in the SOA record.                                                                           |
| `bind_zone_ttl`                | `1W`                             | Time to Live field in the SOA record.                                                                            |

† Best practice for an authoritative name server is to leave recursion turned off. However, [for some cases](http://www.zytrax.com/books/dns/ch7/queries.html#allow-query-cache) it may be necessary to have recursion turned on.

### Host definitions

Host names that this DNS server should resolve can be specified with the variable `bind_zone_hosts` as a list of dicts with fields `name`, `ip` and `aliases`, e.g.:

```Yaml
bind_zone_hosts:
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
```

To allow to surf to http://example.com/, set the host name of your web server to `'@'` (must be quoted!). In BIND syntax, `@` indicates the domain name itself.

IP addresses (both IPv4 and IPv6) can be specified as a string or as a list. This results in a single or multiple A/AAAA records for the host, respectively. This enables [DNS round robin](http://www.zytrax.com/books/dns/ch9/rr.html), a simple load balancing technique. The order in which the IP addresses are returned can be configured with role variable `bind_rrset_order`.

As you can see, not all hosts are in the same network. This is perfectly acceptable, and supported by this role. All networks should be specified in `bind_zone_networks`, though, or the host will not get a PTR record for reverse lookup:

```Yaml
bind_zone_networks:
  - 192.0.2
  - 10
```

Remark that only the network part should be specified here!

### Service records

Service (SRV) records can be added with the variable `bind_zone_services`, e.g.:

```Yaml
bind_zone_services:
  - name: _ldap._tcp
    weight: 100
    port: 88
    target: dc001
```

This is a list of dicts with mandatory fields `name` (service name), `target` (host providing the service), `port` (TCP/UDP port of the service) and optional fields `priority` (default = 0) and `weight` (default = 0).

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

No dependencies. If you want to configure the firewall, do this through another role (e.g. [bertvv.el7](https://github.com/bertvv/ansible-role-el7)).

## Example Playbook

See the test playbook [test.yml](https://github.com/bertvv/ansible-role-bind/blob/tests/test.yml) (in the [tests branch](https://github.com/bertvv/ansible-role-bind/tree/tests)) for an elaborate example that shows all features.

## Testing

### Setting up the test environment

Tests for this role are provided in the form of a Vagrant environment that is kept in a separate branch, `tests`. I use [git-worktree(1)](https://git-scm.com/docs/git-worktree) to include the test code into the working directory. Instructions for running the tests:

1. Fetch the tests branch: `git fetch origin tests`
2. Create a Git worktree for the test code: `git worktree add tests tests` (remark: this requires at least Git v2.5.0). This will create a directory `tests/`.
3. `cd tests/`
4. `vagrant up` will then create a VM and apply a test playbook (`test.yml`).

You may want to change the base box into one that you like. The current one, [bertvv/centos71](https://atlas.hashicorp.com/bertvv/boxes/centos71) was generated using a Packer template from the [Boxcutter project](https://github.com/boxcutter/centos) with a few modifications.

### Tests for the bind role

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

An automated acceptance test written in [BATS](https://github.com/sstephenson/bats.git) is provided that checks most settings specified in `tests/test.yml`. You can run it by executing the shell script `tests/runtests.sh`. The script can be run on either your host system (assuming you have a Bash shell), or one of the VMs. The script will download BATS if needed and run the test script `tests/dns.bats` on both the master and the slave DNS server.

```ShellSession
$ cd tests
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

### Symbolic links in test code

The directory `tests/roles/bind` is a symbolic link that should point to the root of this project in order to work. Additionally, the `filter_plugins` should be linked to the tests directory. To create these links if necessary, do

```ShellSession
$ cd tests/
$ mkdir roles
$ ln -frs ../../PROJECT_DIR roles/bind
$ ln -frs ../filter_plugins/ .
```

## Contributing


## License

BSD

## Contributors

Issues, feature requests, ideas, suggestions, etc. are appreciated and can be posted in the Issues section. Pull requests are also very welcome. Preferably, create a topic branch and when submitting, squash your commits into one (with a descriptive message).

- [Bert Van Vreckem](https://github.com/bertvv/) (Maintainer)
- [Joanna Delaporte](https://github.com/jdelaporte)
