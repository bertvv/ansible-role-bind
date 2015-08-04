# Ansible role `bind`

An Ansible role for setting up BIND ISC as a master DNS server for a single domain. Specifically, the responsibilities of this role are to:

- install BIND
- set up the main configuration file
    - master server
    - slave server
- set up forward and reverse lookup zone files

This role supports multiple reverse zones.

## Requirements

- This role is written specifically for RHEL/CentOS and works on versions 6 and 7.
- The `filter_plugins` directory should be copied to `${ANSIBLE_HOME}`. It contains a few functions that manipulate IP addresses. If you forget this step, you will get the error message "`no filter named 'reverse_lookup_zone'`" in the task 'Main BIND config file'. See [~~Issue #5~~](https://github.com/bertvv/ansible-role-bind/issues/5).

## Role Variables

Variables are not required, unless specified.

| Variable                     | Default                          | Comments (type)                                                                                                  |
| :---                         | :---                             | :---                                                                                                             |
| `bind_allow_query`           | `['localhost']`                  | A list of hosts that are allowed to query this DNS server. Set to ['any'] to allow all hosts                     |
| `bind_listen_ipv4`           | `['127.0.0.1']`                  | A list of the IPv4 address of the network interface(s) to listen on. Set to ['any'] to listen on all interfaces. |
| `bind_listen_ipv6`           | `['::1']`                        | A list of the IPv6 address of the network interface(s) to listen on                                              |
| `bind_recursion`             | `no`                             | Allow recursion. Set to `yes` for a caching DNS server.                                                          |
| `bind_zone_hostmaster_email` | `hostmaster`                     | The e-mail address of the system administrator                                                                   |
| `bind_zone_hosts`            | -                                | Host definitions. See below this table for examples.                                                             |
| `bind_zone_mail_servers`     | `[{name: mail, preference: 10}]` | A list of dicts (with fields `name` and `preference`) specifying the mail servers for this domain.               |
| `bind_zone_master_server_ip` | -                                | **(Required)** The IP address of the master DNS server.                                                          |
| `bind_zone_minimum_ttl`      | `1D`                             | Minimum TTL field in the SOA record.                                                                             |
| `bind_zone_name_servers`     | `[ansible_hostname]`             | A list of the DNS servers for this domain.                                                                       |
| `bind_zone_name`             | `example.com`                    | The domain name                                                                                                  |
| `bind_zone_networks`         | `['10.0.2']`                     | A list of the networks that are part of the domain                                                               |
| `bind_zone_time_to_expire`   | `1W`                             | Time to expire field in the SOA record.                                                                          |
| `bind_zone_time_to_refresh`  | `1D`                             | Time to refresh field in the SOA record.                                                                         |
| `bind_zone_time_to_retry`    | `1H`                             | Time to retry field in the SOA record.                                                                           |
| `bind_zone_ttl`              | `1W`                             | Time to Live field in the SOA record.                                                                            |

### Host definitions

Host names that this DNS server should resolve can be specified with the variable `bind_zone_hosts` as a list of dicts with fields `name`, `ip` and `aliases`, e.g.:

```Yaml
bind_zone_hosts:
  - name: pub01
    ip: 192.0.2.1
    aliases:
      - ns
  - name: pub02
    ip: 192.0.2.2
    aliases:
      - www
      - web
  - name: priv01
    ip: 10.0.0.1
```

As you can see, not all hosts are in the same network. This is perfectly acceptable, and supported by this role. All networks should be specified in `bind_zone_networks`, though, or the host will not get a PTR record for reverse lookup:

```Yaml
bind_zone_networks:
  - 192.0.2
  - 10
```

Remark that only the network part should be specified here!

## Dependencies

No dependencies. If you want to configure the firewall, do this through another role (e.g. [bertvv.el7](https://github.com/bertvv/ansible-role-el7)).

## Example Playbook

See the [test playbook](tests/test.yml) for an elaborate example that shows all features.

## Testing

The `tests` directory contains tests for this role in the form of a Vagrant environment. The command `vagrant up` results in a setup with *two* DNS servers, a master and a slave, set up according to playbook [`test.yml`](tests/test.yml).

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
$ dig @192.168.56.54 MX example.com +short
10 mail.example.com.

```

An automated acceptance test written in [BATS](https://github.com/sstephenson/bats.git) is provided that checks all settings specified in [`test.yml`](tests/test.yml). You can run it by executing the shell script `tests/runtests.sh`. The script can be run on either your host system (assuming you have a Bash shell), or one of the VMs. The script will download BATS if needed and run the test script [`dns.bats`](tests/dns.bats) on both the master and the slave DNS server.

```ShellSession
$ cd tests
$ vagrant up
[...]
$ ./runtests.sh
Testing 192.168.56.53
✓ The `dig` command should be installed
✓ It should return the NS record(s)
✓ It should be able to resolve host names
✓ It should be able to do reverse lookups
✓ It should be able to resolve aliases
✓ It should return the MX record(s)

6 tests, 0 failures
Testing 192.168.56.54
✓ The `dig` command should be installed
✓ It should return the NS record(s)
✓ It should be able to resolve host names
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

The directory `tests/roles/bind` is a symbolic link that should point to the root of this project in order to work. Also the `filter_plugins` should be linked to the tests directory. To create these links if necessary, do

```ShellSession
$ cd tests/
$ mkdir roles
$ ln -frs ../../PROJECT_DIR roles/bind
$ ln -frs ../filter_plugins/ .
```

You may want to change the base box into one that you like. The current one is based on Box-Cutter's [CentOS Packer template](https://github.com/boxcutter/centos).

## Contributing

Issues, feature requests, ideas are appreciated and can be posted in the Issues section. Pull requests are also very welcome. Preferably, create a topic branch and when submitting, squash your commits into one (with a descriptive message).

## License

BSD

## Author Information

Bert Van Vreckem (bert.vanvreckem@gmail.com)

