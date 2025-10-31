Vagrant.configure("2") do |config|
    # Use an official Ubuntu 22.04 LTS box from Vagrant Cloud
    config.vm.box = "ubuntu/jammy64"

    config.ssh.insert_key = false
    
    base_ip = "192.168.56."
    machines = {
        "app"           => {ip: base_ip + "121", memory: 2048, cpus: 2},
        "web1"          => {ip: base_ip + "122", memory: 1024, cpus: 1},
        "web2"          => {ip: base_ip + "123", memory: 1024, cpus: 1},
        "loadbalancer"  => {ip: base_ip + "124", memory: 1024, cpus: 1},
        "backup"        => {ip: base_ip + "125", memory: 1024, cpus: 1},
        "ci"            => {ip: base_ip + "126", memory: 1024, cpus: 1}
    }

    machines.each do |name, cfg|
        config.vm.define name do |vm|
            vm.vm.hostname = name
            vm.vm.network "private_network", ip: cfg[:ip]
            vm.vm.provider "virtualbox" do |vb|
                vb.memory = cfg[:memory]
                vb.cpus = cfg[:cpus]
            end

            # Disable synced folders
            vm.vm.synced_folder ".", "/vagrant", disabled: true

            # forward ports
            if name == "loadbalancer"
                vm.vm.network "forwarded_port", guest: 80, host: 8080
            end
            if name == "backup"
                vm.vm.network "forwarded_port", guest: 19999, host: 19999
            end 
        end
    end
end