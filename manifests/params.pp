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

class cloudwatch::params {
  $credential_file = undef
  $enable_mem_util = true
  $enable_mem_used = true
  $enable_mem_avail = true
  $enable_swap_util = true
  $enable_swap_used = true
  $disk_path = ['/']
  $enable_disk_space_util = true
  $enable_disk_space_used = true
  $enable_disk_space_avail = true
  $memory_units = 'megabytes'
  $disk_space_units = 'gigabytes'
  $aggregated = false
  $aggregated_only = false
  $auto_scaling = false
  $auto_scaling_only = false
  $cron_min = '*'
  $install_target = '/opt'
  $manage_dependencies = true
}