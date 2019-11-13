# TODO: doc

class errata_parser::service (
  String[1] $parser_service_name = $errata_parser::parser_service_name,
){
  assert_private()

  # ensure errata service running
  service { $parser_service_name:
    ensure => 'running',
    enable => true,
  }
}
