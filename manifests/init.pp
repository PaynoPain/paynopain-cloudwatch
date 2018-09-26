# Class: cloudwatch
# ===========================
#
# Installs AWS Cloudwatch Monitoring Scripts and sets up a cron entry to push
# monitoring information to Cloudwatch.
#
# Read more about AWS Cloudwatch Monitoring Scripts:
#   http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/mon-scripts.html
#

class cloudwatch (
  $credential_file         = $::cloudwatch::params::credential_file,
  $enable_mem_util         = $::cloudwatch::params::enable_mem_util,
  $enable_mem_used         = $::cloudwatch::params::enable_mem_used,
  $enable_mem_avail        = $::cloudwatch::params::enable_mem_avail,
  $enable_swap_util        = $::cloudwatch::params::enable_swap_util,
  $enable_swap_used        = $::cloudwatch::params::enable_swap_used,
  $disk_path               = $::cloudwatch::params::disk_path,
  $enable_disk_space_util  = $::cloudwatch::params::enable_disk_space_util,
  $enable_disk_space_used  = $::cloudwatch::params::enable_disk_space_used,
  $enable_disk_space_avail = $::cloudwatch::params::enable_disk_space_avail,
  $memory_units            = $::cloudwatch::params::memory_units,
  $disk_space_units        = $::cloudwatch::params::disk_space_units,
  $aggregated              = $::cloudwatch::params::aggregated,
  $aggregated_only         = $::cloudwatch::params::aggregated_only,
  $auto_scaling            = $::cloudwatch::params::auto_scaling,
  $auto_scaling_only       = $::cloudwatch::params::auto_scaling_only,
  $cron_min                = $::cloudwatch::params::cron_min,
  $install_target          = $::cloudwatch::params::install_target,
  $manage_dependencies     = $::cloudwatch::params::manage_dependencies,
) inherits cloudwatch::params {

  $install_dir = "${install_target}/aws-scripts-mon"
  $zip_name = 'CloudWatchMonitoringScripts-1.2.2.zip'
  $zip_url = "http://aws-cloudwatch.s3.amazonaws.com/downloads/${zip_name}"

  if $manage_dependencies {
    # Establish which packages are needed, depending on the OS family
    case $::operatingsystem {
      /(RedHat|CentOS)$/: {
        $packages = ['perl-Switch', 'perl-DateTime', 'perl-Sys-Syslog', 'perl-LWP-Protocol-https', 'perl-Digest-SHA',
          'unzip', 'cronie']
      }
      'Amazon': {
        $packages = ['perl-Switch', 'perl-DateTime', 'perl-Sys-Syslog', 'perl-LWP-Protocol-https', 'unzip', 'cronie']
      }
      /(Ubuntu|Debian)$/: {
        $packages = ['libwww-perl', 'libdatetime-perl', 'unzip', 'cron']
      }
      default: {
        fail("Dependency management for module cloudwatch is not supported on ${::operatingsystem}")
      }
    }

    ensure_packages($packages)

    archive { $zip_name:
      path         => "/tmp/${zip_name}",
      extract      => true,
      extract_path => $install_target,
      source       => $zip_url,
      creates      => $install_dir,
      require      => Package[$packages]
    }
  } else {
    archive { $zip_name:
      path         => "/tmp/${zip_name}",
      extract      => true,
      extract_path => $install_target,
      source       => $zip_url,
      creates      => $install_dir
    }
  }

  if $credential_file {
    $creds_path = "--aws-credential-file=${credential_file}"
  } else {
    $creds_path = ''
  }

  if $enable_mem_util {
    $mem_util = '--mem-util'
  } else {
    $mem_util = ''
  }

  if $enable_mem_used {
    $mem_used = '--mem-used'
  } else {
    $mem_used = ''
  }

  if $enable_mem_avail {
    $mem_avail = '--mem-avail'
  } else {
    $mem_avail = ''
  }

  if $enable_swap_util {
    $swap_util = '--swap-util'
  } else {
    $swap_util = ''
  }

  if $enable_swap_used {
    $swap_used = '--swap-used'
  } else {
    $swap_used = ''
  }

  $memory_units_val = "--memory-units=${memory_units}"

  $disk_path_val = rstrip(inline_template('<% @disk_path.each do |path| -%>--disk-path=<%=path%> <%end-%>'))

  if $enable_disk_space_util {
    $disk_space_util_val = '--disk-space-util'
  } else {
    $disk_space_util_val = ''
  }

  if $enable_disk_space_used {
    $disk_space_used_val = '--disk-space-used'
  } else {
    $disk_space_used_val = ''
  }

  if $enable_disk_space_avail {
    $disk_space_avail_val = '--disk-space-avail'
  } else {
    $disk_space_avail_val = ''
  }

  $disk_space_units_val = "--disk-space-units=${disk_space_units}"

  if $aggregated {
    if $aggregated_only {
      $aggregated_val = '--aggregated=only'
    } else {
      $aggregated_val = '--aggregated'
    }
  } else {
    $aggregated_val = ''
  }

  if $auto_scaling {
    if $auto_scaling_only {
      $auto_scaling_val = '--auto-scaling=only'
    } else {
      $auto_scaling_val = '--auto-scaling'
    }
  } else {
    $auto_scaling_val = ''
  }

  $cmd = "${install_dir}/mon-put-instance-data.pl
          --from-cron ${memory_units_val} ${disk_space_units_val} ${creds_path} ${credentials} ${iam_role_val}
          ${mem_util} ${mem_used} ${mem_avail} ${swap_util} ${swap_used}
          ${disk_path_val} ${disk_space_util_val} ${disk_space_used_val} ${disk_space_avail_val}
          ${aggregated_val} ${auto_scaling_val} > /dev/null 2>&1"

  if ($manage_dependencies) {
    cron::job { 'cloudwatch':
      ensure  => present,
      name    => 'Push extra metrics to Cloudwatch',
      minute  => $cron_min,
      command => regsubst($cmd, '\s+', ' ', 'G'),
      require => [
        Archive[$zip_name],
        Package[$packages]
      ]
    }
  } else {
    cron::job { 'cloudwatch':
      ensure  => present,
      name    => 'Push extra metrics to Cloudwatch',
      minute  => $cron_min,
      command => regsubst($cmd, '\s+', ' ', 'G'),
      require => Archive[$zip_name]
    }
  }
}
