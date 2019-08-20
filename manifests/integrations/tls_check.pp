# Class: datadog_agent::integrations::tls_check
#
# This class will install the necessary config to hook the tls_check in the agent
#
# Parameters:
#   server
#       (Required, string) - The hostname or IP address with which to connect.
#       String
#
#   port
#       (Optional, integer) - Port to be checked.
#       Default: 443
#
#   transport
#       (Optional, string) - The transport protocol to use when connecting to `server`.
#       Default: TCP
#
#   local_cert_path
#       (Optional, string) - The path to a local certificate in lieu of a server/port. In this mode, the service checks `tls.can_connect` and `tls.version` are unavailable. The certificate can be in PEM or DER format. If in DER format, the file extension must be either `.cer`, `.crt`, or `.der`.
#        trigger if the check fails <threshold> times in <window> attempts.
#
#   server_hostname
#       (Optional, string) - The hostname of the service with which to connect for servers that support SNI. This is also the value used for hostname validation. If not specified, `server` parameter is used.
#
#   validate_hostname
#       (Optional, boolean) - Whether or not to verify the certificate was issued for `server_hostname`. If enabled, this is an additional requirement for the service check `tls.cert_validation`.
#       Default: true
#
#   validate_cert
#       (Optional, boolean) - Whether or not to validate the certificate.
#       If disabled, the service check `tls.cert_validation` always reports as OK except for:
#         1. parsing errors
#         2. hostname mismatch, if `validate_hostname` is true
#       Disabling this is useful when only the monitoring of certificate expiration is desired.
#       Default: True
#
#    allowed_versions
#       (Optional, strings) - The expected versions of TLS/SSL when connecting to `server`. Any protocol versions negotiated by connections that are not in this list makes the service check `tls.version` send CRITICAL. By default, only TLSv1.2 and TLSv1.3 are allowed. Overrides `allowed_versions` in init_config.
#       The supported versions are:
#         SSLv3
#         TLSv1
#         TLSv1.1
#         TLSv1.2
#         TLSv1.3
#
#       allowed_versions:
#         - TLSv1.2
#         - TLSv1.3
#
#    days_warning
#       (Optional, float) - Number of days before certificate expiration from which the service check `tls.cert_expiration` begins emitting WARNING.
#       Default: 14.0
#
#    days_critical
#       (Optional, float) - Number of days before certificate expiration from which the service check `tls.cert_expiration` begins emitting CRITICAL.
#       Default: 7.0
#
#    seconds_warning
#       (Optional, integer) - Number of seconds before certificate expiration from which the service check `tls.cert_expiration` begins emitting WARNING. Overrides `days_warning`.
#
#    seconds_critical
#       (Optional, integer) - Number of seconds before certificate expiration from which the service check `tls.cert_expiration` begins emitting CRITICAL. Overrides `days_critical`.
#
#    cert
#       (Optional, string) - The path to a single file in PEM format containing a certificate as well as any number of CA certificates needed to establish the certificate’s authenticity for use when connecting to `server`. It may also contain an unencrypted private key to use.
#
#    private_key
#       (Optional, string) - The unencrypted private key to use for `cert` when connecting to `server`. This is required if `cert` is set and it does not already contain a private key.
#
#    ca_cert
#       (Optional, string) - The path to a file of concatenated CA certificates in PEM format or a directory containing several CA certificates in PEM format. If a directory, the directory must have been processed using the c_rehash utility supplied with OpenSSL.
#
#   timeout
#       (Optional, integer) - The timeout for connecting to `server`.
#       Default: 10
#
#   name
#       (Optional, string) - Unique identifier for this instance that is added as a tag to all data emitted.
#
#   tags
#       (Optional, key:value strings) - List of tags to attach to every metric and service check emitted by this instance.
#
# Sample Usage:
#
# Add a class for each check instance:
#
# class { 'datadog_agent::integrations::tls_check':
#   check_name => 'localhost-ftp',
#   host       => 'ftp.example.com',
#   port       => '21',
# }
#
# class { 'datadog_agent::integrations::tls_check':
#   check_name => 'localhost-ssh',
#   host       => '127.0.0.1',
#   port       => '22',
#   threshold  => 1,
#   window     => 1,
#   tags       => ['production', 'ssh access'],
# }
#
# class { 'datadog_agent::integrations::tls_check':
#   name                  => 'localhost-web-response',
#   host                  => '127.0.0.1',
#   port                  => '80',
#   timeout               => '8',
#   threshold             => 1,
#   window                => 1,
#   collect_response_time => 1,
#   skip_event            => 1,
#   tags                  => ['production', 'webserver response time'],
# }
#
# Add multiple instances in one class declaration:
#
#  class { 'datadog_agent::integrations::tls_check':
#        instances => [{
#          'check_name' => 'www.example.com-http',
#          'host'       => 'www.example.com',
#          'port'       => '80',
#        },
#        {
#          'check_name' => 'www.example.com-https',
#          'host'       => 'www.example.com',
#          'port'       => '443',
#        }]
#     }


class datadog_agent::integrations::tls_check (
  $server                = $hostname,
  $port                  = 443,
  $transport             = 'TCP',
  $local_cert_path       = undef,
  $server_hostname       = undef,
  $validate_hostname     = undef,
  $validate_cert         = true,
  $allowed_versions      = ['TLSv1.2', 'TLSv1.3'],
  $days_warning          = 30.0,
  $days_critical         = 14.0,
  $seconds_warning       = undef,
  $seconds_critical      = undef,
  $cert                  = undef,
  $private_key           = undef,
  $ca_cert               = undef,
  $timeout               = 10,
  $tags                  = [],
  $instances             = undef,
) inherits datadog_agent::params {
  include datadog_agent

  if !$instances and $host {
    $_instances = [{
      'server'    => $server,
      'port'      => $port,
      'transport' => $transport,
      'timeout'   => $timeout,
      'name'      => $name,
    }]
  } else {
    $_instances = $instances
  }

  $legacy_dst = "${datadog_agent::conf_dir}/tls_check.yaml"
  if !$::datadog_agent::agent5_enable {
    $dst_dir = "${datadog_agent::conf6_dir}/tls_check.d"
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
    content => template('datadog_agent/agent-conf.d/tls_check.yaml.erb'),
    require => Package[$datadog_agent::params::package_name],
    notify  => Service[$datadog_agent::params::service_name]
  }
}
