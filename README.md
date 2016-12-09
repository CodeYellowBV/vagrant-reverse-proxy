# Vagrant Reverse Proxy

This Vagrant plugin automatically installs a reverse proxy
configuration for each of your Vagrant machines.

This means you can access the HTTP interface of your virtual machines
by accessing HTTP on your machine's IP address or DNS hostname, with
a suffix that indicates the VM.

In other words, `http://localhost/my-vm` refers to `http://my-vm/` on
the local machine.  This also works if you access it from an external
machine, even though `my-vm` is a local machine name unknown on the
network.

This plugin currently only supports NGINX, but patches are accepted to
integrate it with other web servers.

## Installation

Install the plugin as usual:

    $ vagrant plugin install vagrant-reverse-proxy

## Usage

First, install NGINX and create a configuration as usual.  Then, in
the `server` configuration block for the host you want to use for
proxying, simply put `include "vagrant-proxy-config-locations";` in the file.

If you don't need anything specific, just put the following in
`/etc/nginx/sites-enabled/default`:

    server {
        listen 80 default;
        listen [::]:80 default;
        # This is the fallback server
        server_name default;
        # Redirect http://localhost/hostname/lalala
        # to http://hostname/lalala
        include "vagrant-proxy-config-locations";
    }

This will load the `/etc/nginx/vagrant-proxy-config` file which is
managed by this plugin.  This file contains `location` statements for
each of your virtual machines, such that `http://localhost/foo` will
proxy to port 80 on the virtual machine with a `config.vm.hostname`
value of `foo`.  This is only done for virtual machines that have
`config.reverse_proxy.enabled` set to `true` in their config.

#### Server Blocks

The plugin also writes `server` block configuration for the enabled
VMs so that they can be accessed directly via their hostname (as long
as the hostname resolves to the host machine's IP address).

To include these, simply include the generated file inside your main NGINX `http` block:

    http {
        include "vagrant-proxy-config-servers";
    }


Whenever you bring up, halt, or reload a machine, the plugin updates the proxy
config files and invokes `sudo nginx -s reload` to make the change immediately visible.

### Custom host names

Sometimes you want to support several virtual hosts for one VM.  To
set that up, you can override the `vhosts` option:

    config.reverse_proxy.vhosts = ['foo.test', 'bar.test']

This will proxy `http://localhost/foo.test` and
`http://localhost/bar.test` to this VM, with a matching `Host` header.

If you want to customize the vhost path, you can use a hash instead of
an array:

    config.reverse_proxy.vhosts = {
        "foo-test" => "foo.test",
        "bar" => "bar.test"
        "bar-altport" => {:host => "bar.test", :port => 8080}
    }

As you can see, this allows you to define which port to connect to
instead of the default port (which is port 80).

### Specifying the NGINX configuration file paths

If you want to change the location of the managed NGINX configuration
files, set the `config.reverse_proxy.nginx_locations_config_file` or
`config.reverse_proxy.nginx_servers_config_file` values to paths on
your host machine in the Vagrantfile configuration:

    config.reverse_proxy.nginx_locations_config_file = '/usr/local/etc/nginx/vagrant-proxy-config-locations'
    config.reverse_proxy.nginx_servers_config_file = '/usr/local/etc/nginx/vagrant-proxy-config-servers'

If you don't want to generate one of the locations or server configuration files, set the appropriate config value to `nil`.

### Specifying the NGINX reload command

After the NGINX configuration file is generated, a reload command is
executed so that the changes take effect. By default the command
executed is `sudo nginx -s reload`. If you need to change this, set
the `config.reverse_proxy.nginx_reload_command` option to the command
to be executed:

    config.reverse_proxy.nginx_reload_command = 'sudo service nginx reload'

## Adding proxy support to your application

This plugin will instruct NGINX to pass the following headers to your
Vagrant box:

- `X-Forwarded-For`: This contains the IP address of the client.
- `X-Forwarded-Host`: This contains the IP address of your hypervisor.
- `X-Forwarded-Port`: This contains the port number of NGINX on your hypervisor.
- `X-Base-Url`: This contains the base URL that redirects to this VM.

Redirects are transparently rewritten by NGINX, but if your
application generates links with absolute URLs, you'll need to ensure
that those links are prefixed with the value of `X-Base-Url`, but only
if the request originated from the trusted NGINX proxy on your
hypervisor.

Be sure to avoid using these headers when the request originated
elsewhere, because trusting these headers as sent by arbitrary clients
is a potential security issue!  If you're using Laravel, you could
consider using the
[trusted proxies middleware](https://github.com/fideloper/TrustedProxy).
If you're using Symfony, just use `setTrustedProxies()` on your
`Request` object, and Symfony takes care of the rest.  Note that
`X-Base-Url` is not supported by either framework, so you'll need to
add a bit of custom code there if you need to override the base URL.


## Changelog

- 0.4.0 Add support for `vagrant reload`, add support for host-based instead
  of location-based dispatching (both thanks to Sam Stevens). NOTE: This is a
  backwards incompatible change: the default name of the config file has
  changed, so you must update the `include` statement in your NGINX config.
- 0.3.1 Allow overriding the NGINX reload command (thanks to Sam Stevens).
- 0.3 Allow overriding the location of the NGINX configuration file
  (thanks to Sam Stevens).  Support multiple VMs in a single Vagrant
  config (suggested by Nicholas Alipaz).
- 0.2 Support for proxying of multiple ports in `vhosts` config.
- 0.1 First version
