##  1. <a name='TableofContent'></a>Table of Content
<!-- vscode-markdown-toc -->
* 1. [Table of Content](#TableofContent)
* 2. [ Overview](#Overview)
* 3. [Module Description](#ModuleDescription)
* 4. [Setup](#Setup)
	* 4.1. [What errata_parser affects](#Whaterrata_parseraffects)
	* 4.2. [Setup Requirements](#SetupRequirements)
* 5. [Usage](#Usage)
* 6. [Limitations](#Limitations)

<!-- vscode-markdown-toc-config
	numbering=true
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->

##  2. <a name='Overview'></a> Overview
This module installes and configures the [errata parser](https://github.com/ATIX-AG/errata_server) and [errata server](https://github.com/ATIX-AG/errata_server) on a bare Ubuntu system.

##  3. <a name='ModuleDescription'></a>Module Description
This module does not configure firewall rules. Firewall rules will need to be
configured separately in order to allow for correct operation of errata parser and server. Please keep in mind, that you'll need to open local firewalls to access the proxy.

##  4. <a name='Setup'></a>Setup
###  4.1. <a name='Whaterrata_parseraffects'></a>What errata_parser affects
* Installs `ruby-bundler` and its dependencies, `python3.7`, `python3-pip`, `libapt-pkg-dev` and git, see errata_parser::install for details
* The module will setup both errata parser and errata server
* By default, this module creates the group and user.

###  4.2. <a name='SetupRequirements'></a>Setup Requirements
See metadata.json for module dependencies. The node on which you include the module needs internet access, either direct or via a proxy.

##  5. <a name='Usage'></a>Usage

Configure errata_parser with default params:
```
include errata_parser
```
Set params in hiera:
```yaml
---
errata_parser::proxy_uri: 'http://proxy.domain:3128'
errata_parser::server_port: 8080
```

##  6. <a name='Limitations'></a>Limitations
* This module does not use vcsrepos as it would be elaborate to configure proxy
* There is currently no parameter which git revision to use for the repos
* Once cloned, this module does not check for updates in the errata_parser and errata_server git repos. You can manually update the git repos by deleting the `~errata_parser_user/git/{errata_parser,errata_server}` directories. This triggers a re-installation of the modules.
* There are no unit tests yet implemented
* There is a lot of doc to do
* This module is tested and verified on Ubuntu 18.04 LTS
* To get this module flying on Ubuntu 16.04 LTS you have to provide a backport repo for python3.7
