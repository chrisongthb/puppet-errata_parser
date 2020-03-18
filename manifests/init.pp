# TODO: doc

class errata_parser (
  String[1]                 $parser_user_name             = 'errataparser',
  String[1]                 $parser_group_name            = $parser_user_name,
  Stdlib::Absolutepath      $parser_user_home             = "/srv/${parser_user_name}",
  Boolean                   $parser_user_manage_home      = true,
  String[1]                 $parser_user_shell            = '/bin/bash',
  String[1]                 $parser_user_password         = '!',
  Boolean                   $parser_user_purge_ssh_keys   = true,
  Integer[1]                $server_port                  = 8015,
  Boolean                   $manage_parser_user_and_group = true,
  Integer[0,23]             $parser_cron_job_hour         = 3,
  Integer[0,59]             $parser_cron_job_minute       = 0,
  String[1]                 $parser_cron_command          = "${parser_user_home}/errata-parser-job.sh",
  String[1]                 $parser_service_name          = 'errata-server',
  Optional[Integer[0]]      $parser_user_password_max_age = undef,
  Optional[Integer[0]]      $parser_user_password_min_age = undef,
  Optional[Integer[1]]      $parser_uid                   = undef,
  Optional[Integer[1]]      $parser_gid                   = undef,
  Optional[String[1]]       $parser_user_description      = undef,
  Optional[Stdlib::Httpurl] $proxy_uri                    = undef,
){

  contain errata_parser::install
  contain errata_parser::config
  contain errata_parser::service

  Class['errata_parser::install']
  -> Class['errata_parser::config']
  ~> Class['errata_parser::service']

}
