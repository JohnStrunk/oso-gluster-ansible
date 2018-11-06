# Upgrading Gluster servers

This document outlines procedures for upgrading the packages on Gluster servers.

## Determining upgrade needs

The playbook `playbooks/check-upgrade.yml` will count the total and
security-specific package updates that are available. The playbook does not
make any modifications to the hosts.

Usage:

```shell
$ ./ansible-ec2 playbooks/check-upgrade.yml

# ... ansible output ...
CUSTOM STATS: ********************************************************
        node3: { "security_updates": "0",  "total_updates": "11"}
        jumper: { "security_updates": "0",  "total_updates": "2"}
        node2: { "security_updates": "0",  "total_updates": "11"}
        node1: { "security_updates": "0",  "total_updates": "11"}
        node5: { "security_updates": "0",  "total_updates": "11"}
        node0: { "security_updates": "0",  "total_updates": "11"}
        node4: { "security_updates": "0",  "total_updates": "11"}
```

## Automated upgrade

The steps below have been automated via the `playbooks/upgrade.yml` Ansible
playbook. This playbook will update all packages to their latest version (not
just security updates), checking and waiting for the cluster to be healthy with
each host upgraded.

An optional playbook, `playbooks/download-upgrades.yml` is available to
pre-download the available packages across all hosts to speed the upgrade
process.

Usage:

```shell
$ ./ansible-ec2 playbooks/download-upgrades.yml
# ... ansible output ...

$ ./ansible-ec2 -l g-us-east-2-c00,g-us-east-2-c01 playbooks/upgrade.yml

# ... ansible output ...
```

The above playbook can also be used to upgrade the jump host.

## Type of upgrade

Before upgrading, it is necessary to decide how extensively packages will be
updated. There are several options:

- All packages can be upgraded via: `sudo yum update`
- Only security fixes can be applied via: `sudo yum update --security`

__General advice:__ If Gluster or the kernel is going to be upgraded, it will
entail stopping Gluster, and a reboot at the end. In this case, go ahead and
fully upgrade the server (all packages).

## Upgrade procedure

- Determine if what is going to be upgraded: Run `sudo yum updateinfo list sec`
  for security-only updates or `sudo yum updateinfo list` for all. If the
  desired update type includes any kernel or Gluster packages, the above advice
  applies.
- Run the upgrade commands through `screen` to avoid problems w/ ssh
  disconnection.
  - To start or reconnect to screen:

    ```shell
    $ screen -xR
    ```

  - To detach: `ctrl-a d`
- Pre-flight
  - Ensure all bricks are online: `sudo gluster vol status` should show pids for
    all bricks in each volume
  - Ensure all volumes are fully healed: `sudo gluster vol heal <volname> info`
    should be run for each volume on that server. The output should show no
    pending entries and all bricks should be "connected." Example:

    ```shell
    $ sudo gluster vol heal supervol00 info
    Brick ip-192-168-0-11.us-east-2.compute.internal:/bricks/supervol00/brick
    Status: Connected
    Number of entries: 0

    Brick ip-192-168-0-13.us-east-2.compute.internal:/bricks/supervol00/brick
    Status: Connected
    Number of entries: 0

    Brick ip-192-168-0-12.us-east-2.compute.internal:/bricks/supervol00/brick
    Status: Connected
    Number of entries: 0
    ```

- Upgrade
  - If gluster packages are going to be upgraded, stop Gluster on this node:

    ```shell
    $ sudo systemctl stop glusterd
    $ sudo pkill glusterfs
    $ sudo pkill glusterfsd
    ```

    Then verify Gluster is stopped:

    ```shell
    $ ps ax | grep gluster
    ```

  - Perform the update:

    ```shell
    $ sudo yum update
    # ... or ...
    $ sudo yum update --security
    ```

  - Make sure all data is safely written to disk:

    ```shell
    $ sync
    ```

  - If the kernel or Gluster was updated, ensure Gluster is stopped (see above)
    and reboot:

    ```shell
    # Gluster should already be stopped!
    $ sudo shutdown -r now
    ```

- Post
  - Ensure `shared_storage` was properly re-mounted

    ```shell
    $ grep shared_storage /proc/mounts
    ip-192-168-0-11.us-east-2.compute.internal:/gluster_shared_storage /run/gluster/shared_storage fuse.glusterfs rw,relatime,user_id=0,group_id=0,default_permissions,allow_other,max_read=131072 0 0
    ```

  - Recheck gluster and wait for pending heals to complete

    ```shell
    $ sudo gluster vol status
    $ sudo gluster vol heal <volname> info summary
    # ... repeat above until the count is low ...
    $ sudo gluster vol heal <volname> info
    ```

The above steps should be repeated for each server in a cluster.
