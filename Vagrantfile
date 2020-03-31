# -*- mode: ruby -*-
# vi: set ft=ruby :

NODES = 6
DISKS_PER_NODE = 2
DISKSIZE = "50G"

Vagrant.configure("2") do |config|
  config.vm.box = "rhel-svr-7.4-reg"
  config.vm.provider "libvirt" do |lv|
    lv.cpus = "1"
    lv.memory = "1024"
    lv.nested = true
    lv.volume_cache = "none"
  end

  # Can't write to /vagrant on atomic-host, so disable default sync dir
  config.vm.synced_folder ".", "/vagrant", disabled: true
  #config.vm.synced_folder ".", "/vagrant", type: "sshfs"


  config.vm.define "jumper" do |node|
    node.vm.hostname = "jumper"
  end

  (0..NODES-1).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.hostname = "node#{i}"
      node.vm.provider "libvirt" do |provider|
        for _ in 0..DISKS_PER_NODE-1 do
          provider.storage :file, :size => DISKSIZE
        end
      end
      # Only set up provisioning on the last worker node so ansible only gets
      # called once during the provisioning step.
      if i == NODES-1
        node.vm.provision :ansible do |ansible|
          # https://www.vagrantup.com/docs/provisioning/ansible_intro.html
          #ansible.extra_vars = {
          #  "ansible_become" => "true"
          #}
          #ansible.host_vars = {
          #  "host1" => {"http_port" => 80,
          #              "maxRequestsPerChild" => 808},
          #  "host2" => {"http_port" => 303,
          #              "maxRequestsPerChild" => 909}
          #}
          ansible.groups = {
            # mimics AWS dynamic inventory generated group based on instance
            # tag of Name=gluster-mgmt
            "tag_Name_gluster_mgmt" => ["jumper"],
            # tag of gluster-master=us-east-2a-c00
            "tag_gluster_master_us_east_2a_c00" => ["node0"],
            # ec2 tag: gluster-group=us-east-2-c00-g00
            "tag_gluster_group_us_east_2a_c00_g00" => [
              "node0",
              "node1",
              "node2"
            ],
            # tag of gluster-master=us-east-2a-c01
            "tag_gluster_master_us_east_2a_c01" => ["node3"],
            # ec2 tag: gluster-group=us-east-2-c01-g00
            "tag_gluster_group_us_east_2a_c01_g00" => [
              "node3",
              "node4",
              "node5"
            ],
            # tags that need to exist for the config to parse correctly
            "tag_gluster_master_free_stg_c00" => ["dummy"],
            "tag_gluster_group_free_stg_c00_g00" => ["dummy"],
            "tag_gluster_master_us_east_1a_c00" => ["dummy"],
            "tag_gluster_group_us_east_1a_c00_g00" => ["dummy"],
            "tag_gluster_master_us_east_1a_c01" => ["dummy"],
            "tag_gluster_group_us_east_1a_c01_g00" => ["dummy"],
            "tag_gluster_master_us_east_1b_c00" => ["dummy"],
            "tag_gluster_group_us_east_1b_c00_g00" => ["dummy"],
            "tag_gluster_master_us_east_1b_c01" => ["dummy"],
            "tag_gluster_group_us_east_1b_c01_g00" => ["dummy"],
            "tag_gluster_master_us_east_2_c00" => ["dummy"],
            "tag_gluster_group_us_east_2_c00_g00" => ["dummy"],
            "tag_gluster_master_us_east_2_c01" => ["dummy"],
            "tag_gluster_group_us_east_2_c01_g00" => ["dummy"]
          }
          ansible.limit = "all"
          ansible.playbook = "vagrant.yml"
          #ansible.verbose = true
        end
      end
    end
  end
end
