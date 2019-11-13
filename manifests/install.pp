# TODO: doc

class errata_parser::install (
  String[1]            $parser_user_name             = $errata_parser::parser_user_name,
  String[1]            $parser_group_name            = $errata_parser::parser_group_name,
  Stdlib::Absolutepath $parser_user_home             = $errata_parser::parser_user_home,
  Boolean              $parser_user_manage_home      = $errata_parser::parser_user_manage_home,
  String[1]            $parser_user_shell            = $errata_parser::parser_user_shell,
  String[1]            $parser_user_password         = $errata_parser::parser_user_password,
  Boolean              $parser_user_purge_ssh_keys   = $errata_parser::parser_user_purge_ssh_keys,
  Boolean              $manage_parser_user_and_group = $errata_parser::manage_parser_user_and_group,
  Optional[Integer[0]] $parser_user_password_max_age = $errata_parser::parser_user_password_max_age,
  Optional[Integer[0]] $parser_user_password_min_age = $errata_parser::parser_user_password_min_age,
  Optional[Integer[1]] $parser_uid                   = $errata_parser::parser_uid,
  Optional[Integer[1]] $parser_gid                   = $errata_parser::parser_gid,
  Optional[String[1]]  $parser_user_description      = $errata_parser::parser_user_description,
){
  assert_private()

  # provide required packages
  ensure_packages([
    'ruby',
    'ruby-dev',
    'ruby-bundler',
    'libapt-pkg-dev',
    'git',
    'python3.7',
    'python3-pip'],
  { 'ensure' => 'present' })

  # set required paths
  $required_paths = [
    "${parser_user_home}/git",
    "${parser_user_home}/errata",
  ]

  # manage group and user
  if $manage_parser_user_and_group {
    group { $parser_group_name:
      ensure => present,
      gid    => $parser_gid,
      before => File[$required_paths],
    }
    user { $parser_user_name:
      ensure           => present,
      home             => $parser_user_home,
      managehome       => $parser_user_manage_home,
      comment          => $parser_user_description,
      shell            => $parser_user_shell,
      uid              => $parser_uid,
      gid              => $parser_gid,
      password         => $parser_user_password,
      purge_ssh_keys   => $parser_user_purge_ssh_keys,
      password_max_age => $parser_user_password_max_age,
      password_min_age => $parser_user_password_min_age,
      require          => Group[$parser_group_name],
      before           => File[$required_paths],
    }
  }

  # provide required paths
  $required_paths.each |$path| {
    file { $path:
      ensure => 'directory',
      mode   => '0755',
      owner  => $parser_user_name,
      group  => $parser_group_name,
    }
  }
}
