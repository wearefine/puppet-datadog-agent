# Class: datadog_agent::integrations::generic
#
# This class will install a configuration file for an integration
#
# Parameters:
#   $integration_name:
#       This will be used to build the filename. It must correspond to an
#         integration that is supported by dd-agent, see the dd-agent for
#         a current list.
#   $integration_contents:
#       String containing a rendered template.
#
# Sample Usage:
#
# class { 'datadog_agent::integrations::generic':
#   integration_name     => 'custom',
#   integration_contents => template(my_custom_template),
# }
#
class datadog_agent::integrations::generic(
  Optional[String] $integration_name     = undef,
  Optional[String] $integration_contents = undef,
) inherits datadog_agent::params {

  validate_legacy('Optional[String]', 'validate_string', $integration_name)
  validate_legacy('Optional[String]', 'validate_string', $integration_contents)

  $legacy_dst = "${datadog_agent::conf_dir}/${integration_name}.yaml"
  if !$::datadog_agent::agent5_enable {
    $dst_dir = "${datadog_agent::conf6_dir}/${integration_name}.d"
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
    content => $integration_contents,
    require => Package[$datadog_agent::params::package_name],
    notify  => Service[$datadog_agent::params::service_name]
  }
}
