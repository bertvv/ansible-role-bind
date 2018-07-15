## DNS Master/Slave configuration example

### Used two VMs

* ocmaster39.openshift.local => 192.168.56.10
* ocslave39.openshift.local => 192.168.56.11

### Playbook examples

* [master_playbook](./master.yml)
* [slave_playbook](./slave.yml)

### Testing resolution w/ master

```
[root@ocmaster39 ~]# dig @192.168.56.10 ocslave39.openshift.local | grep -n1 "ANSWER SECTION"
13-
14:;; ANSWER SECTION:
15-ocslave39.openshift.local. 1209600 IN A 192.168.56.11
```

### Testing resolution w/ slave

```
[root@ocmaster39 ~]# dig @192.168.56.11 ocslave39.openshift.local | grep -n1 "ANSWER SECTION"
13-
14:;; ANSWER SECTION:
15-ocslave39.openshift.local. 1209600 IN A 192.168.56.11
```
