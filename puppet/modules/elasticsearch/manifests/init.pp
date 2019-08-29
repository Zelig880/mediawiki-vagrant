# == Class: Elasticsearch
#
# Elasticsearch is a powerful open source search and analytics
# engine, much like Solr, but with a more user-friendly inteface.
#
class elasticsearch(
    $max_heap,
    $min_heap
) {
    require ::elasticsearch::repository

    require_package('openjdk-8-jre-headless')

    package { 'elasticsearch':
        ensure  => latest,
        name    => 'elasticsearch-oss',
        require => File['/etc/default/elasticsearch'],
    }

    # Install a customized elasticsearch.yml
    file { '/etc/elasticsearch/elasticsearch.yml':
        ensure  => present,
        source  => 'puppet:///modules/elasticsearch/elasticsearch.yml',
        owner   => 'root',
        group   => 'elasticsearch',
        mode    => '0444',
        require => Package['elasticsearch'],
    }

    # This is needed when upgrading from 2.x to 5.x, the directory
    # ends up owned by root and elasticsearch refuses to start
    file { '/var/run/elasticsearch':
        ensure  => directory,
        owner   => 'elasticsearch',
        group   => 'elasticsearch',
        mode    => '0755',
        require => Package['elasticsearch'],
    }

    service { 'elasticsearch':
        ensure  => running,
        enable  => true,
        require => [
            Package['elasticsearch'],
            Package['openjdk-8-jre-headless'],
        ]
    }

    exec { 'wait-for-elasticsearch':
        require => Service['elasticsearch'],
        command => 'curl --connect-timeout 5 --retry-connrefuse --retry-delay 10 --retry-max-time 60 --retry 10  http://localhost:9200 -s -o /dev/null'
    }

    file { '/etc/default/elasticsearch':
        source => 'puppet:///modules/elasticsearch/defaults',
        notify => Service['elasticsearch'],
    }

    file { '/etc/elasticsearch/jvm.options':
        content => template('elasticsearch/jvm.options.erb'),
        require => Package['elasticsearch'],
        notify  => Service['elasticsearch'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/etc/elasticsearch/log4j2.properties':
        source  => 'puppet:///modules/elasticsearch/log4j2.properties',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['elasticsearch'],
    }

    file { '/etc/logrotate.d/elasticsearch':
        source => 'puppet:///modules/elasticsearch/logrotate',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    # The logrotate above works on size, rather than daily.  For this to work
    # reasonably well logrotate needs to run multiple times per day
    file { '/etc/cron.hourly':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/etc/cron.hourly/logrotate':
        ensure  => 'link',
        target  => '/etc/cron.daily/logrotate',
        require => File['/etc/cron.hourly'],
    }

    apache::reverse_proxy { 'elasticsearch':
        port => 9200,
    }
}
