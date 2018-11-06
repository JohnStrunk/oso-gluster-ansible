# Rebooting a Gluster node

This procedure should be used when it is necessary to restart a gluster node.


## AWS stop/start cycle

AWS periodically notifies tenants that their EC2 instances need to be stopped
and then restarted. This is typically due to either a scheduled maintenance or
to evacuate degraded hardware. In these cases, the EC@ instance must be
"stopped", **NOT TERMINATED**, and then started again. This "power cycling"
gives AWS an opportunity to move the instance to different backing hardware.

In these cases, the proper sequence is to:
1. Using ssh, [shut down the Gluster server
instance.](#shutting-down-a-gluster-instance)
2. Watch the EC2 console for shutdown to complete. The instance state will
change from "running" to "stopped".
3. Use the EC2 console to start the instance again (via `actions > instance
state > start`)
4. [Monitor the recovery process.](#monitoring-restart-and-recovery)


## Shutting down a Gluster instance

- Ensure that all bricks are online for all volumes exported from the node.
  - From the "master node", execute `sudo gluster vol info` to get a list of
    each volume that has a brick on the affected node.
  - On each affected volume, execute `sudo gluster vol status <volname>` and
    ensure that pids are listed for each brick. Also ensure that the expected
    number of bricks are listed.
- Make sure there are no pending heals for the affected volumes by executing
  `sudo gluster vol heal <volname> info`. All bricks should be "connected", the
  "number of entries" should be 0, and no files/dirs should be printed.
- Stop gluster on the node to be shut down:
  ```sh
  # sudo systemctl stop glusterd
  # sudo pkill glusterfs
  # sudo pkill glusterfsd
  ```
- Shut down the node: `sudo shutdown -h now`


## Monitoring restart and recovery

- Ensure glusterd has come back online via `sudo gluster peer status`, making
  sure the newly started machine is "connected"  
- Make sure the bricks are up by checking `sudo gluster vol status <volname>`
  for each volume serverd by the affected node.
- Monitor the healing of each volume via `sudo gluster vol heal <volname>
  info summary`. The "number of entries" should steadily decrease to
  zero.
- Once the heal count has reached a minimum (or zero), `sudo gluster vol heal
  <volname> info` can be used to verify and/or get a list of the remaining
  files. **Don't run this if there are many outstanding heals.**
