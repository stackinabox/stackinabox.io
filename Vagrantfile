9# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV["LC_ALL"] = "C.UTF-8"
ENV["LANG"] = "C.UTF-8"

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.require_version ">= 1.9.1"

vagrant_dir = File.expand_path(File.dirname(__FILE__))
personalization = File.expand_path(File.join(vagrant_dir, "Personalization"), __FILE__)
if not File.exist?(personalization)
  FileUtils.cp(File.expand_path(File.join(vagrant_dir, "Personalization.dist"), __FILE__), personalization)
end
load personalization

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

    if Vagrant.has_plugin?("vagrant-vbguest")
      config.vbguest.auto_update = false
    end

    if $use_nfs == "true"
    	# this will override the default '/vagrant' shared folder settings and use nfs
    	config.vm.synced_folder ".", "/vagrant"#, type: "nfs", mount_options: ['rw', 'vers=3', 'tcp', 'nolock']
    end

    config.vm.define "opdk" do |opdk|

      opdk.vm.box = "stackinabox/openstack"
      opdk.vm.box_version = "= 0.9.9"

      # eth1, this will be OpenStacks's "management" network
      opdk.vm.network "private_network", ip: "192.168.27.100", adapter_ip: "192.168.27.1", netmask: "255.255.255.0", auto_config: true

      # eth2, this will be OpenStack's "public" network
      opdk.vm.network "private_network", ip: "172.24.4.225", adapter_ip: "172.24.4.225", netmask: "255.255.255.0", auto_config: false

      config.ssh.forward_agent = true
      config.ssh.insert_key = false
      config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

      if Vagrant.has_plugin?("vagrant-docker-compose")
        opdk.vm.provision :docker
        opdk.vm.provision :docker_compose,
          yml: "/vagrant/compose/urbancode/docker-compose.yml",
          command_options: { rm: "", up: "-d --no-recreate --timeout 90" },
          project_name: "urbancode",
          compose_version: "1.8.0",
          run: "always"
      else
        print "\n"
        print "vagrant-docker-compose plugin has not been found.\n"
        print "Please install it by running `vagrant plugin install vagrant-docker-compose`\n"
        exit 22
      end

      opdk.vm.provider :virtualbox do |vb|

          # Use VBoxManage to customize the VM.
          vb.customize ["modifyvm", :id, "--ioapic", "on"] # turn on I/O APIC
          vb.customize ["modifyvm", :id, "--cpus", "#{$cpus}"] # set number of vcpus
          vb.customize ["modifyvm", :id, "--memory", "#{$memory}"] # set amount of memory allocated vm memory
          vb.customize ["modifyvm", :id, "--ostype", "Ubuntu_64"] # set guest OS type
          vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"] # enables DNS resolution from guest using host's DNS
          vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"] # turn on promiscuous mode on nic 3
          vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
          vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
          vb.customize ["modifyvm", :id, "--nictype3", "virtio"]
          vb.customize ["modifyvm", :id, "--pae", "on"] # enables PAE
          vb.customize ["modifyvm", :id, "--longmode", "on"] # enables long mode (64 bit mode in GUEST OS)
          vb.customize ["modifyvm", :id, "--hpet", "on"] # enables a High Precision Event Timer (HPET)
          vb.customize ["modifyvm", :id, "--hwvirtex", "on"] # turn on host hardware virtualization extensions (VT-x|AMD-V)
          vb.customize ["modifyvm", :id, "--nestedpaging", "on"] # if --hwvirtex is on, this enables nested paging
          vb.customize ["modifyvm", :id, "--largepages", "on"] # if --hwvirtex & --nestedpaging are on
          vb.customize ["modifyvm", :id, "--vtxvpid", "on"] # if --hwvirtex on
          vb.customize ["modifyvm", :id, "--vtxux", "on"] # if --vtux on (Intel VT-x only) enables unrestricted guest mode
          vb.customize ["modifyvm", :id, "--boot1", "disk"] # tells vm to boot from disk only
          vb.customize ["modifyvm", :id, "--rtcuseutc", "on"] # lets the real-time clock (RTC) operate in UTC time
          vb.customize ["modifyvm", :id, "--audio", "none"]
          vb.customize ["modifyvm", :id, "--clipboard", "disabled"]
          vb.customize ["modifyvm", :id, "--usbehci", "off"]
          vb.customize ["modifyvm", :id, "--vrde", "off"]
          vb.customize ["guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000]
          #fix for https://github.com/mitchellh/vagrant/issues/7648
          vb.customize ['modifyvm', :id, '--cableconnected1', 'on']
          vb.customize ['modifyvm', :id, '--cableconnected2', 'on']
          vb.customize ['modifyvm', :id, '--cableconnected3', 'on']
      end

      opdk.vm.provider :vmware_desktop do |vw|
          vw.vmx["displayName"] = "stackinabox" # sets the name that virtual box will show in it's UI
          vw.vmx["numvcpus"] = "#{$cpus}" # set number of vcpus
          vw.vmx["memsize"] = "#{$memory}" # set amount of memory allocated vm memory
          vw.vmx["guestOS"] = "ubuntu-64"
          vw.vmx["vhv.enable"] = "TRUE"
          vw.vmx["vmx.allowNested"] = "TRUE"
          vw.vmx["mainMem.allow8GB"] = "TRUE"
          vw.vmx["vmx.superPriorityBoost"] = "TRUE"
          vw.vmx["RemoteDisplay.vnc.enabled"] = "FALSE"

          vw.vmx["ethernet0.present"] = "TRUE"
          vw.vmx["ethernet0.startConnected"] = "TRUE"
          vw.vmx["ethernet0.virtualDev"] = "vmxnet"
          vw.vmx["ethernet0.connectionType"] = "nat"
          vw.vmx["ethernet0.addresstype"] = "generated"

          vw.vmx["ethernet1.present"] = "TRUE"
          vw.vmx["ethernet1.startConnected"] = "TRUE"
          vw.vmx["ethernet1.virtualDev"] = "vmxnet"
          vw.vmx["ethernet1.connectionType"] = "custom"
          vw.vmx["ethernet1.vnet"] = "vmnet2"
          vw.vmx["ethernet1.addresstype"] = "generated"

          vw.vmx["ethernet2.present"] = "TRUE"
          vw.vmx["ethernet2.startConnected"] = "TRUE"
          vw.vmx["ethernet2.virtualDev"] = "vmxnet"
          vw.vmx["ethernet2.connectionType"] = "custom"
          vw.vmx["ethernet2.vnet"] = "vmnet3"
          vw.vmx["ethernet2.addresstype"] = "generated"
      end

    end

end
