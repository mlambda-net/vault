Vagrant.configure("2") do |config|

  config.vm.define "vault" do |vault|
    vault.vm.box = "bento/ubuntu-16.04"
    vault.vm.hostname = "vault"
  end

  config.vm.provision "shell", path: "./scripts/user_data.sh"

  config.vm.network "forwarded_port", guest: 8200, host: 9000
  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
    v.cpus = 1
  end

end
