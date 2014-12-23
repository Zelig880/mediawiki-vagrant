# == Class: sentry
#
# This Puppet class installs and configures a Sentry instance -an
# error aggregator and dashboard which can be used to view and
# organize MediaWiki PHP and JS errors.
#
# === Parameters
#
# [*user*]
#   System user with which to run Sentry.
#
# [*group*]
#   System group with which to run Sentry.
#
# [*db_name*]
#   Logical MySQL database name (example: 'sentry').
#
# [*db_user*]
#   MySQL user to use to connect to the database (example: 'wikidb').
#
# [*db_pass*]
#   Password for MySQL account (example: 'secret123').
#
# [*vhost_name*]
#   Hostname of the Sentry server (example: 'sentry.local.wmftest.net').
#
# [*deploy_dir*]
#   Path where Sentry should be installed (example: '/var/sentry').
#
# [*cfg_file*]
#   Sentry configuration file. Needs to end in '.py'. (example: '/etc/sentry.conf.py')
#   The file will be generated by puppet.
#
# [*mail_log_file*]
#   File to to write mails which would be sent (example: '/vagrant/logs/sentry.mail.log').
#
# [*secret_key*]
#   The secret key required by Sentry.
#
# [*dsn_file*]
#   A text file which will store the DSN to the default group. Clients will
#   need to send logs to this URL. (example: '/var/sentry/sentry_dsn.txt')
#
# [*admin_user*]
#   Username of the Sentry superuser. (example: 'admin')
#
# [*admin_pass*]
#   Password of the Sentry superuser. (example: 'vagrant')
#
class sentry (
    $user,
    $group,
    $db_name,
    $db_user,
    $db_pass,
    $vhost_name,
    $deploy_dir,
    $cfg_file,
    $mail_log_file,
    $secret_key,
    $dsn_file,
    $admin_user,
    $admin_pass,
) {
    include ::apache::mod::proxy
    include ::apache::mod::proxy_http
    include ::apache::mod::headers
    include ::php
    require ::mysql
    require ::virtualenv

    # http://stackoverflow.com/questions/5178292/pip-install-mysql-python-fails-with-environmenterror-mysql-config-not-found
    require_package('libmysqlclient-dev')
    # needed for building the python package lxml
    require_package('libxml2-dev', 'libxslt1-dev')

    $sentry_cli = "${deploy_dir}/bin/sentry --config='${cfg_file}'"
    $sentry_create_project_script = "${deploy_dir}/bin/sentry_create_project.py"

    user { $user:
        ensure => present,
        gid     => $group,
        shell   => '/bin/false',
        home    => '/nonexistent',
        system  => true,
    }

    group { $group:
        ensure => present,
        system => true,
    }

    # Use virtualenv because Sentry has lots of dependencies
    virtualenv::environment { $deploy_dir:
        ensure   => present,
        packages => ['sentry[mysql]==7.*'],
        require  => Package['libmysqlclient-dev'],
    }

    mysql::db { $db_name:
        ensure => present,
    }

    mysql::user { $db_user:
        ensure   => present,
        grant    => "ALL ON ${db_name}.*",
        password => $db_pass,
        require  => Mysql::Db[$db_name],
    }

    apache::site { 'sentry':
        ensure  => present,
        content => template('sentry/apache-site.erb'),
        require => Class['::apache::mod::proxy', '::apache::mod::proxy_http', '::apache::mod::headers'],
    }

    file { $cfg_file:
        ensure  => present,
        group   => $group,
        content => template('sentry/sentry.conf.py.erb'),
        mode    => 0640,
    }

    exec { 'initialize sentry database':
        command => "${sentry_cli} upgrade",
        require => [Virtualenv::Environment[$deploy_dir], Mysql::User[$db_user], File[$cfg_file]],
    }

    file { $sentry_create_project_script:
        ensure  => present,
        content => template('sentry/sentry_create_project.py.erb'),
        mode    => '755',
        require => Virtualenv::Environment[$deploy_dir],
    }

    exec { 'create sentry project':
        command => "${deploy_dir}/bin/python ${sentry_create_project_script}",
        creates => $dsn_file,
        require => [Exec['initialize sentry database'], File[$sentry_create_project_script]],
    }

    file { '/etc/init/sentry.conf':
        ensure  => present,
        content => template('sentry/upstart.erb'),
        mode    => '0444',
    }

    service { 'sentry':
        ensure     => running,
        provider   => 'upstart',
        require    => [Virtualenv::Environment[$deploy_dir], Mysql::User[$db_user]],
        subscribe  => [File[$cfg_file], Exec['create sentry project']],
    }
}
