# General notes

- Need to consider how it's done in gluster-ansible
  - [PR query](https://github.com/gluster/gluster-ansible-infra/pulls?utf8=%E2%9C%93&q=is%3Apr+vdo)
  - fstab options add: "_netdev,x-systemd.device-timeout=0,x-systemd.requires=vdo.service"
    - _netdev ???
    - systemd.device-timeout=0 ???
    - systemd.requires - ensures vdo is started before mounting
  - g-a also uses `noatime` and `nodiratime` always, but we don't!

- VDO configuration
  - [RHEL Admin guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html-single/storage_administration_guide/#vdo)
    - slab size determines max physical storage in the volume.
      - default = 2GB; max phys volume = 16TB
      - recommended = 2GB for up to 1 TB volume
    - Logical size up to 254x physical is supported (up to 4PB)
    - Memory:
      - VDO: 370MB + 268MB/TB physical storage (~ 1GB for our 2 vols)
      - UDS index: 250MB min (& default)
        - 4B per entry; 1 entry per unique block
        - Maintains info for recently written data. Size based on write rate.
        - Dense index: 1TB window per 1GB RAM
        - Sparse index: 10TB window per 1GB RAM
    - Storage overhead:
      - 1MB per 4GB physical storage + 1MB per slab
      - 1.25MB per 1GB logical rounded up to whole slab
      - Dense UDS: 17GB storage per 1GB RAM index
      - Sparse UDS: 170GB storage per 1GB RAM index
    - Both logical and physical space can be grown

## Installation

Required packages:

```bash
yum install vdo kmod-vdo
```

Create volume:

```bash
vdo create \
    --name=vdo_name \
    --dovice=block_device \          # /dev/disk/by-id/...
    --vdoLogicalSize=logical_size \  # 50T
    --indexMem=0.5 \                 # 512M in-memory index (5T window)
    --sparseIndex=enabled            # use sparse indexing
```

**NOTE:** Must use a persistent name for the block device. If the name changes,
VDO might not start

Recommended mount options: `defaults,x-systemd.requires=vdo.service`

## Monitoring

vdostats utility:

```bash
$ vdostats --human-readable

Device                   1K-blocks    Used     Available    Use%    Space saving%
/dev/mapper/node1osd1    926.5G       21.0G    905.5G       2%      73%
/dev/mapper/node1osd2    926.5G       28.2G    898.3G       3%      64%
```

## Tuning
