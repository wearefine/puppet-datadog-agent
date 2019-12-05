# Class: datadog_agent::integrations::load
#
# This class will install the necessary configuration for the load integration
#
# Sample Usage:
#   include 'datadog_agent::integrations::load'
#
#
class datadog_agent::integrations::load inherits datadog_agent::params {
  include datadog_agent

  $legacy_dst = "${datadog_agent::conf_dir}/load.yaml"
  if !$::datadog_agent::agent5_enable {
    $dst_dir = "${datadog_agent::conf6_dir}/load.d"
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
      mode    => '0644',
      content => template('datadog_agent/agent-conf.d/load.yaml.erb'),
      require => Package[$datadog_agent::params::package_name],
      notify  => Service[$datadog_agent::params::service_name]
  }
}
