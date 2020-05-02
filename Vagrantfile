# -*- mode: ruby -*-
# vi: set ft=ruby :

dir = File.dirname(File.expand_path(__FILE__))

require "yaml"
require "json"
require "#{dir}/vagrant/ruby/deep_merge"
require "#{dir}/vagrant/ruby/inventory_path"
require "#{dir}/vagrant/ruby/hostupdater"


# install required plugins if necessary
if ARGV[0] == 'up'
    plugins = YAML.load_file "./vagrant/plugins.yml"
    required_plugins = plugins["plugins"]
    missing_plugins = []
    required_plugins.each do |plugin|
        missing_plugins.push(plugin) unless Vagrant.has_plugin? plugin
    end

    if ! missing_plugins.empty?
        install_these = missing_plugins.join(' ')
        puts "Found missing plugins: #{install_these}.  Installing..."
        exec "vagrant plugin install #{install_these}; vagrant up"
    end
end

host_groups = {}
host_vars = {}

config = YAML.load_file "#{dir}/config.yml"
machines = config["machines"]

Vagrant.configure("2") do |vagrant|
#   vagrant.hostsupdater.aliases = getWebHosts(machines)
  (1..machines.count).each do |machine_id|
    settings = machines[machines.keys[machine_id -1]]

    # These values are the default options
    vagrant.bindfs.default_options = {
      force_user:   'vagrant',
      force_group:  'vagrant',
      perms:        'u=rwX:g=rD:o=rD',
    }

    if config['provider'] == "parallels"
        vagrant.vm.provider :parallels do |parallels|
          parallels.update_guest_tools = false
          parallels.memory = settings["memory"]
          parallels.cpus = settings["cpus"]
        end
    end

    if config['provider'] == "virtualbox"
        vagrant.vm.provider :virtualbox do |parallels|
          virtualbox.memory = settings["memory"]
          virtualbox.cpus = settings["cpus"]
        end
    end

    if config['provider'] == "vmware"
        vagrant.vm.provider :vmware_desktop do |vmware|
          vmware.vmx["memsize"] = settings["memory"]
          vmware.vmx["numvcpus"] = settings["cpus"]
        end
    end

    # Create host_vars for ansible inventory
    if settings.has_key?("host_vars")
      hashes = {}

      settings["host_vars"].each do |section, values|
        hash = {
#           "#{section}" => "'#{values}'"
          "#{section}" => "'#{values.to_json}'"
        }
        hashes = hashes.deep_merge(hash)
      end

      host_vars[settings["hostname"]] = hashes
    end

    # Create host_groups for ansible inventory
    if settings.has_key?("host_groups")
      settings["host_groups"].each do |group|
        hash = {
          "#{group}" => [ settings["hostname"] ]
        }
        host_groups = host_groups.deep_merge(hash)
      end
    end

    # Setting up the guest system
    vagrant.vm.define settings["hostname"] do |machine|
      machine.vm.box = settings["box"]
      machine.vm.box_version = settings["box_version"] ||= ">= 0"
      machine.vm.hostname = settings["hostname"]
      machine.vm.network "private_network", ip: settings["ip"]
      machine.vm.synced_folder ".", "/vagrant", type: "nfs"

      if settings.has_key?("forwarding")
        settings["forwarding"].each do |name, port|
          machine.vm.network "forwarded_port", guest: port["guest"], host: port["host"]
        end
      end

      if settings.has_key?("shared_folders")
        settings['shared_folders'].each do |i, folder|
          if folder["sync_type"] == "nfs"
            machine.vm.synced_folder "#{folder["source"]}", "/mnt/vagrant-#{i}", type: :nfs
            machine.bindfs.bind_folder "/mnt/vagrant-#{i}", "#{folder["target"]}",
              force_user:  folder["owner"]||="vagrant",
              force_group: folder["group"]||="vagrant",
              perms:       "u=rwX:g=rD:o=rD",
              o:           "nonempty",
              after:       :provision
#         else
#            vagrant.vm.synced_folder folder["source"], folder["target"], type: folder["sync_type"]
          end
        end
      end

      machine.vm.provision :ansible do |ansible|
        ansible.compatibility_mode = "2.0"
        ansible.limit = "all"
        ansible.playbook = "./ansible/#{config["playbook"]}"
        ansible.groups = host_groups
        ansible.verbose = config["output"]
        ansible.extra_vars = settings["host_vars"]
#         ansible.extra_vars = begin
#           YAML.load_file "./ansible/hosts/#{settings["hostname"]}.yml"
#         rescue Errno::ENOENT
#           {}
#         end
      end
    end

  end # each
end # configure
