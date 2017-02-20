module VagrantPlugins
  module ReverseProxy
    class Plugin
      class Config < Vagrant.plugin(2, :config)
        attr_accessor :enabled, :vhosts, :nginx_locations_config_file, :nginx_servers_config_file, :nginx_reload_command, :nginx_extra_config
        alias_method :enabled?, :enabled

        def initialize
          @enabled = UNSET_VALUE
          @vhosts = UNSET_VALUE
          @nginx_locations_config_file = UNSET_VALUE
          @nginx_servers_config_file = UNSET_VALUE
          @nginx_reload_command = UNSET_VALUE
          @nginx_extra_config = UNSET_VALUE
        end

        def finalize!
          @enabled = false if @enabled == UNSET_VALUE
          if @vhosts == UNSET_VALUE
            @vhosts = nil
          elsif @vhosts.is_a?(Array)
            # Convert to canonical hash form of
            # {path => {:host => name, :port => num, :nginx_extra_config => str}}
            vhosts_hash = {}
            @vhosts.each {|entry| vhosts_hash[entry] = {:host => entry, :port => 80, :nginx_extra_config => ""} }
            @vhosts = vhosts_hash
          elsif @vhosts.is_a?(Hash)
            @vhosts.each do |key, value|
              if (value.is_a?(String))
                @vhosts[key] = {:host => value, :port => 80,  :nginx_extra_config => ""}
              else
                value[:port] ||= 80
                value[:nginx_extra_config] ||= ""
              end
            end
          end
          if @nginx_extra_config == UNSET_VALUE
            @nginx_extra_config = nil
          end
          if @nginx_locations_config_file == UNSET_VALUE
            @nginx_locations_config_file = '/etc/nginx/vagrant-proxy-config-locations'
          end
          if @nginx_servers_config_file == UNSET_VALUE
            @nginx_servers_config_file = '/etc/nginx/vagrant-proxy-config-servers'
          end
          if @nginx_reload_command == UNSET_VALUE
            @nginx_reload_command = nil
          end
        end

        def validate(machine)
          errors = _detected_errors

          unless [true, false, UNSET_VALUE].include?(@enabled)
            errors << 'enabled must be a boolean'
          end

          if @vhosts.instance_of?(Array)
            @vhosts.each do |vhost|
              unless (vhost.is_a?(String) || vhost.is_a?(Hash))
                errors << "vhost #{vhost} is not a string or hash"
              end
            end
          elsif @vhosts.instance_of?(Hash)
            @vhosts.each do |path, vhost|
              unless path.is_a?(String)
                errors << "vhost path `#{path}' is not a string"
              end
              unless vhost.is_a?(String) || vhost.is_a?(Hash)
                errors << "Vhost `#{vhost}' for path `#{path}' is not a string or hash"
              else
                if vhost.is_a?(Hash) && !vhost[:host]
                  errors << "Vhost `#{vhost}' for path `#{path}' has no :host key"
                end
              end
            end
          elsif @vhosts != nil && @vhosts != UNSET_VALUE
            errors << 'vhosts must be an array of hostnames, a string=>string hash or nil'
          end

          unless @nginx_extra_config.instance_of?(String) || @nginx_extra_config == nil || @nginx_extra_config == UNSET_VALUE
            errors << 'nginx_extra_config must be a string'
          end

          unless @nginx_locations_config_file.instance_of?(String) || @nginx_locations_config_file == nil || @nginx_locations_config_file == UNSET_VALUE
            errors << 'nginx_locations_config_file must be a string'
          end

          unless @nginx_servers_config_file.instance_of?(String) || @nginx_servers_config_file == nil || @nginx_servers_config_file == UNSET_VALUE
            errors << 'nginx_servers_config_file must be a string'
          end

          if @nginx_locations_config_file == nil && @nginx_servers_config_file == nil
            errors << 'only one of nginx_locations_config_file and nginx_servers_config_file can be nil'
          end

          unless @nginx_reload_command.instance_of?(String) || @nginx_reload_command == nil || @nginx_reload_command == UNSET_VALUE
            errors << 'nginx_reload_command must be a string'
          end

          { 'Reverse proxy configuration' => errors.compact }
        end
      end
    end
  end
end
