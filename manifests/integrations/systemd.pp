# Class: datadog_agent::integrations::systemd_check
#
# This class will install the necessary config to hook the systemd check in the agent
#
# Parameters:
#   services
#       (Required, string) - Full names must be used. Examples: ssh.service, docker.socket
#
#   private_socket
#       (Optional, string) - Path to systemd private socket needed to retrieve systemd data.
#       Default: `/run/systemd/private` or `/host/run/systemd/private` when using Docker Agent
#
#   tags
#       (Optional, key:value strings) - List of tags to attach to every metric and service check emitted by this instance.
#
# Sample Usage:
#
# Add a class for systemd services:
#
#  class { 'datadog_agent::integrations::systemd_check':
#    services => [
#      'sshd.service',
#      'ntp.service',
#      'my_app.service',
#    ]
#  }


class datadog_agent::integrations::systemd (
  $services       = [],
  $private_socket = undef,
  $tags           = [],
) inherits datadog_agent::params {
  include datadog_agent

  $legacy_dst = "${datadog_agent::conf_dir}/systemd.yaml"
  if !$::datadog_agent::agent5_enable {
    $dst_dir = "${datadog_agent::conf6_dir}/systemd.d"
    file { $legacy_dst:
      ensure => 'absent'
    }

    file { $dst_dir:
      ensure  => directory,
      owner   => $datadog_agent::params::dd_user,
      group   => $datadog_agent::params::dd_group,
      mode    => '0755',
      require => Package[$datadog_agent::params::package_name],
      notify  => Service[$datadog_agent::params::service_name]
    }
    $dst = "${dst_dir}/conf.yaml"
  } else {
    $dst = $legacy_dst
  }

  file { $dst:
    ensure  => file,
    owner   => $datadog_agent::params::dd_user,
    group   => $datadog_agent::params::dd_group,
    mode    => '0600',
    content => template('datadog_agent/agent-conf.d/systemd.yaml.erb'),
    require => Package[$datadog_agent::params::package_name],
    notify  => Service[$datadog_agent::params::service_name]
  }
}
