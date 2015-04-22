# Ansible role `bind`

An Ansible role for setting up BIND ISC as a master DNS server for a single domain. Specifically, the responsibilities of this role are to:

- install BIND
- manage firewall rules
- set up the main configuration file
- set up forward and reverse lookup zone files

This role supports multiple reverse zones.

## Requirements

- The `firewalld` service should be running
- The `filter_plugins` directory should be copied to `${ANSIBLE_HOME}`. It contains a few functions that manipulate IP addresses

## Role Variables

| Variable                     | Default                          | Comments (type)                                                                                                  |
| :---                         | :---                             | :---                                                                                                             |
| `bind_allow_query`           | `['localhost']`                  | A list of hosts that are allowed to query this DNS server. Set to ['any'] to allow all hosts                     |
| `bind_listen_ipv4`           | `['127.0.0.1']`                  | A list of the IPv4 address of the network interface(s) to listen on. Set to ['any'] to listen on all interfaces. |
| `bind_listen_ipv6`           | `['::1']`                        | A list of the IPv6 address of the network interface(s) to listen on                                              |
| `bind_recursion`             | `yes`                            | Allow recursion. Set to `no` for an authoritative DNS server.                                                    |
| `bind_zone_hostmaster_email` | `hostmaster`                     | The e-mail address of the system administrator                                                                   |
| `bind_zone_hosts`            | -                                | Host definitions. See below this table for examples.                                                             |
| `bind_zone_mail_servers`     | `[{name: mail, preference: 10}]` | A list of dicts (with fields `name` and `preference`) specifying the mail servers for this domain.               |
| `bind_zone_minimum_ttl`      | `1D`                             | Minimum TTL field in the SOA record.                                                                             |
| `bind_zone_name`             | `example.com`                    | The domain name                                                                                                  |
| `bind_zone_name_servers`     | `[ansible_hostname]`             | A list of the DNS servers for this domain.                                                                       |
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

No dependencies.

## Example Playbook

See the [test playbook](tests/test.yml) for an elaborate example that shows all features.

## Testing

The `tests` directory contains tests for this role in the form of a Vagrant environment. The directory `tests/roles/bind` is a symbolic link that should point to the root of this project in order to work. To create it, do

```ShellSession
$ cd tests/
$ mkdir roles
$ ln -frs ../../PROJECT_DIR roles/bind
$ ln -frs ../filter_plugins/ .
```

You may want to change the base box into one that you like. The current one is based on Box-Cutter's [CentOS Packer template](https://github.com/boxcutter/centos).

The playbook [`test.yml`](tests/test.yml) applies the role to a VM, setting role variables. After running it, you should be able to log in to the server and query the DNS:

```ShellSession
$ vagrant ssh
$ dig www.example.com @10.0.2.15 +short
pub0003.example.com.
10.0.2.20
$ dig -x 172.16.0.10 @10.0.2.15 +short
priv0001.example.com.
$ dig example.com -t MX @10.0.2.15 +short
10 mail.example.com.
$ dig example.com -t NS @10.0.2.15 +short
testbind.example.com.
```

## Contributing

Issues, feature requests, ideas are appreciated and can be posted in the Issues section. Pull requests are also very welcome. Preferably, create a topic branch and when submitting, squash your commits into one (with a descriptive message).

## License

BSD

## Author Information

Bert Van Vreckem (bert.vanvreckem@gmail.com)

