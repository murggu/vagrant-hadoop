# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

hosts = {
    "hadoop-yarn" => {ip: "192.168.8.90", ram: "2048", cpus: "2"},
}

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  hosts.each do |name, params|

    # Hadoop cluster configuration
    config.vm.define name do |node|
      node.vm.box = "puppetlabs/ubuntu-14.04-64-puppet"

      node.vm.hostname = "#{name}"

      node.vm.network "private_network", ip: params[:ip]
      # node.vm.network "public_network", ip: params[:ip]

      node.vm.provider "virtualbox" do |vb|
        vb.name = "#{name}"
        vb.gui = false
        vb.memory = params[:ram]
        vb.cpus = params[:cpus]
      end

      node.vm.provision "shell", path: "script/install-hadoop.sh"

    end
  end
end