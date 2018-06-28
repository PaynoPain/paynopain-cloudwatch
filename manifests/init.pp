# Class: cloudwatch
# ===========================
#
# Installs AWS Cloudwatch Monitoring Scripts and sets up a cron entry to push
# monitoring information to Cloudwatch.
#
# Read more about AWS Cloudwatch Monitoring Scripts:
#   http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/mon-scripts.html
#
# == Parameters
#
# [*credential_file*]
#   Path to file containing IAM user credentials.
#   Default: undef
#
# [*enable_mem_util*]
#   Collects and sends the MemoryUtilization metric as a percentage.
#   Default: true
#
# [*enable_mem_used*]
#   Collects and sends the MemoryUsed metric.
#   Default: true
#
# [*enable_mem_avail*]
#   Collects and sends the MemoryAvailable metric.
#   Default: true
#
# [*enable_swap_util*]
#   Collects and sends SwapUtilization metric as a percentage.
#   Default: true
#
# [*enable_swap_used*]
#   Collects and sends SwapUsed metric.
#   Default: true
#
# [*disk_path*]
#   Selects the disks on which to report.
#   Default: ['/']
#
# [*enable_disk_space_util*]
#   Collects and sends the DiskSpaceUtilization metric for the selected disks.
#   Default: true
#
# [*enable_disk_space_used*]
#   Collects and sends the DiskSpaceUsed metric for the selected disks.
#   Default: true
#
# [*enable_disk_space_avail*]
#   Collects and sends the DiskSpaceAvailable metric for the selected disks.
#   Default: true
#
# [*memory_units*]
#   Specifies units in which to report memory usage.
#   Default: 'megabytes'
#
# [*disk_space_units*]
#   Specifies units in which to report disk space usage.
#   Default: 'gigabytes'
#
# [*aggregated*]
#   Adds aggregated metrics for instance type, AMI ID, and overall for the region.
#   Default: false
#
# [*aggregated_only*]
#   The script only aggregates metrics for instance type, AMI ID, and overall for the region.
#   Default: false
#
# [*auto_scaling*]
#   Adds aggregated metrics for the Auto Scaling group.
#   Default: false
#
# [*auto_scaling_only*]
#   The script reports only Auto Scaling metrics.
#   Default: false
#
# [*cron_min*]
#   The minute at which to run the cron job, specified an cron format. e.g. '*/5' would push metrics to Cloudwatch
#   every 5 minutes.
#   Default: '*'
#
# [*install_target*]
#   The directory to install the AWS scripts into.
#   Default: '/opt'
#
# [*manage_dependencies*]
#   Whether or not this module should manage the installation of the packages which the AWS scripts depend on.
#   Default: true

class cloudwatch (
  $credential_file         = undef,
  $enable_mem_util         = true,
  $enable_mem_used         = true,
  $enable_mem_avail        = true,
  $enable_swap_util        = true,
  $enable_swap_used        = true,
  $disk_path               = ['/'],
  $enable_disk_space_util  = true,
  $enable_disk_space_used  = true,
  $enable_disk_space_avail = true,
  $memory_units            = 'megabytes',
  $disk_space_units        = 'gigabytes',
  $aggregated              = false,
  $aggregated_only         = false,
  $auto_scaling            = false,
  $auto_scaling_only       = false,
  $cron_min                = '*',
  $install_target          = '/opt',
  $manage_dependencies     = true
) {

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
          ${aggregated_val} ${auto_scaling_val}"

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

  concat { '/etc/awslogs/awslogs.conf':
      ensure         => 'present',
      owner          => 'root',
      group          => 'root',
      mode           => '0644',
      ensure_newline => true,
      warn           => true,
      require        => File['/etc/awslogs'],
  }
  
  concat::fragment { 'awslogs-header':
      target  => '/etc/awslogs/awslogs.conf',
      content => template('cloudwatch/awslogs_header.erb'),
      order   => '00',
  }
}
