# TODO: doc

class errata_parser::config (
  String[1]                 $parser_user_name       = $errata_parser::parser_user_name,
  String[1]                 $parser_group_name      = $errata_parser::parser_group_name,
  String[1]                 $parser_user_home       = $errata_parser::parser_user_home,
  Integer[1]                $server_port            = $errata_parser::server_port,
  Integer[0,23]             $parser_cron_job_hour   = $errata_parser::parser_cron_job_hour,
  Integer[0,59]             $parser_cron_job_minute = $errata_parser::parser_cron_job_minute,
  String[1]                 $parser_cron_command    = $errata_parser::parser_cron_command,
  String[1]                 $parser_service_name    = $errata_parser::parser_service_name,
  Optional[Stdlib::Httpurl] $proxy_uri              = $errata_parser::proxy_uri,
){
  assert_private()

  # set proxy defaults for execs and cron::job
  $proxy_environment = $proxy_uri ? {
    undef   => undef,
    default => [
      "https_proxy=${proxy_uri}",
      "http_proxy=${proxy_uri}"
    ],
  }

  # defaults for every exec
  Exec {
    environment => $proxy_environment,
    user        => $parser_user_name,
    provider    => 'shell',
    tag         => $module_name,
  }

  # clone repos
  exec { 'clone errata_parser':
    command => "/usr/bin/git clone https://github.com/ATIX-AG/errata_parser.git ${parser_user_home}/git/errata_parser",
    creates => "${parser_user_home}/git/errata_parser",
    notify  => Exec['install ruby gems for errata parser'],
    require => [ File["${parser_user_home}/git"], Package['git'] ],
  }
  exec { 'clone errata_server':
    command => "/usr/bin/git clone https://github.com/ATIX-AG/errata_server.git ${parser_user_home}/git/errata_server",
    creates => "${parser_user_home}/git/errata_server",
    notify  => Exec['install pip libraries for errata server'],
    require => [ File["${parser_user_home}/git"], Package['git'] ],
  }
  # install python and ruby packages
  exec { 'install pip libraries for errata server':
    command => '/usr/bin/pip3 install .',
    creates => "${parser_user_home}/.local/bin/errata_server",
    cwd     => "${parser_user_home}/git/errata_server",
    require => [ Exec['clone errata_server'], Package['python3-pip'] ],
  }
  exec { 'install ruby gems for errata parser':
    command => '/usr/bin/bundle install --path vendor/bundle',
    creates => "${parser_user_home}/git/errata_parser/vendor/bundle",
    cwd     => "${parser_user_home}/git/errata_parser",
    require => [ Exec['clone errata_parser'], Package['ruby-bundler'] ],
  }
  # generate errata configs
  exec { 'generate errata config for ubuntu':
    command => '/usr/bin/bundle exec gen_errata.rb ubuntu > errata_ubuntu.yaml || true',
    creates => "${parser_user_home}/git/errata_parser/errata_ubuntu.yaml",
    cwd     => "${parser_user_home}/git/errata_parser",
    require => [ Exec['install ruby gems for errata parser'], Package['ruby-bundler'] ],
  }
  exec { 'generate errata config for debRelease':
    command => '/usr/bin/bundle exec debRelease.rb > packages_everything.json || true',
    creates => "${parser_user_home}/git/errata_parser/packages_everything.json",
    cwd     => "${parser_user_home}/git/errata_parser",
    require => [ Exec['install ruby gems for errata parser'], Package['ruby-bundler'] ],
  }
  exec { 'generate errata config for debian':
    command => '/usr/bin/bundle exec gen_errata.rb debian > errata_debian.yaml || true',
    creates => "${parser_user_home}/git/errata_parser/errata_debian.yaml",
    cwd     => "${parser_user_home}/git/errata_parser",
    require => [ Exec['generate errata config for debRelease'], Package['ruby-bundler'] ],
  }

  # publish errata config for debian
  file { "${parser_user_home}/errata/errata_debian.yaml":
    ensure  => 'file',
    owner   => $parser_user_name,
    group   => $parser_group_name,
    mode    => '0644',
    source  => "file://${parser_user_home}/git/errata_parser/errata_debian.yaml",
    require => Exec['generate errata config for debian'],
  }

  # publish errata config for ubuntu
  file { "${parser_user_home}/errata/errata_ubuntu.yaml":
    ensure  => 'file',
    owner   => $parser_user_name,
    group   => $parser_group_name,
    mode    => '0644',
    source  => "file://${parser_user_home}/git/errata_parser/errata_ubuntu.yaml",
    require => Exec['generate errata config for ubuntu'],
  }

  # publish errata parser config
  file { "${parser_user_home}/errata/config.json":
    ensure  => 'file',
    owner   => $parser_user_name,
    group   => $parser_group_name,
    mode    => '0644',
    source  => "file://${parser_user_home}/git/errata_parser/default_config.json",
    require => Exec['clone errata_parser'],
  }

  # provide script for regular errata parsing
  file { 'errata_parser_job_script':
    ensure  => 'file',
    path    => "${parser_user_home}/errata-parser-job.sh",
    owner   => $parser_user_name,
    group   => $parser_group_name,
    mode    => '0744',
    content => "#!/bin/bash\n[ \"\${LOGNAME}\" == 'errataparser' ] || exit 1\ncd ${parser_user_home}/git/errata_parser\n/usr/bin/bundle exec errata_parser.rb --config ${parser_user_home}/errata/config.json --debian ${parser_user_home}/errata/ --ubuntu ${parser_user_home}/errata/ --metadata\n",
  }

  # deploy cron job
  cron::job { 'errata-parser':
    ensure      => 'present',
    user        => $parser_user_name,
    command     => $parser_cron_command,
    minute      => $parser_cron_job_minute,
    hour        => $parser_cron_job_hour,
    environment => $proxy_environment,
    require     => File['errata_parser_job_script'],
  }

  # Provide SystemD Unit
  file { "/etc/systemd/system/${parser_service_name}.service":
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => "[Unit]
Description=Errataserver presenting API

[Service]
User=${parser_user_name}
ExecStart=${parser_user_home}/.local/bin/errata_server --port ${server_port} --datapath ${parser_user_home}/errata/

[Install]
WantedBy=multi-user.target
",
    require => Exec['install pip libraries for errata server'],
  }
  ~> Class['systemd::systemctl::daemon_reload']
}
