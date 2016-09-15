# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV["LC_ALL"] = "C.UTF-8"
ENV["LANG"] = "C.UTF-8"

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.require_version ">= 1.8.5"

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

    config.vm.define "opdk" do |opdk|

      opdk.vm.box = "stackinabox/opdk"
      opdk.vm.box_version = "= 0.9.4"

      # eth1, this will be OpenStacks's "management" network
      opdk.vm.network "private_network", ip: "192.168.27.100", adapter_ip: "192.168.27.1", netmask: "255.255.255.0", auto_config: true

      # eth2, this will be OpenStack's "public" network
      opdk.vm.network "private_network", ip: "172.24.4.225", adapter_ip: "172.24.4.225", netmask: "255.255.255.0", auto_config: false

      config.ssh.forward_agent = true
      config.ssh.insert_key = false

      if Vagrant.has_plugin?("vagrant-docker-compose")
        # sometimes is takes a second to get docker to startup
        opdk.vm.provision "shell", inline: "sleep 20 || sudo systemctl restart docker.service || sleep 20", run: "always"
        opdk.vm.provision :docker
        opdk.vm.provision :docker_compose, 
          yml: "/vagrant/compose/urbancode/docker-compose.yml",
          command_options: { rm: "", up: "-d --no-recreate --timeout 10"}, 
          project_name: "urbancode",
          compose_version: "1.8.0",
          env: { DOCKER_HOST: "192.168.27.100:2375" },
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
      end

    end

    if Vagrant.has_plugin?("vagrant-multi-hostsupdater")
      config.multihostsupdater.aliases = {'192.168.27.100' => ['openstack.stackinabox.io', 'bluebox.stackinabox.io', 'docker.stackinabox.io', 'heat.stackinabox.io', 'designer.stackinabox.io', 'ucd.stackinabox.io', 'registry.stackinabox.io', 'docker.stackinabox.io', 'agent.stackinabox.io', 'blueprintdb.stackinabox.io']}
    else
        print "\n"
        print "vagrant-multi-hostsupdater plugin has not been found.\n"
        print "Please install it by running `vagrant plugin install vagrant-multi-hostsupdater`\n"
        exit 22
    end

end
