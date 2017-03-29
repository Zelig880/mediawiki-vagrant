# == Class: npm
#
# Provision npm dependency manager.
#
# === Parameters
#
# [*cache_dir*]
#   Npm cache directory (npm_config_cache).
#   Default '/tmp/cache/npm'
#
class npm (
    $cache_dir   = '/tmp/cache/npm',
) {

    apt::repository { 'nodesource':
        uri        => 'https://deb.nodesource.com/node_6.x',
        dist       => $::lsbdistcodename,
        components => 'main',
        keyfile    => 'puppet:///modules/npm/nodesource-pubkey.asc',
    }

    # Pin it higher than the Wikimedia repo
    apt::pin { 'nodejs':
        package  => 'nodejs',
        pin      => 'release o=Node Source',
        priority => 1010,
    }

    # Install the npm and nodejs-legacy packages manually
    # before the nodesource repo has been added so as not to
    # conflict for package versions
    exec { 'ins-npm-nodejs-legacy':
        command     => '/usr/bin/apt-get update && /usr/bin/apt-get install -y --force-yes npm nodejs-legacy',
        environment => 'DEBIAN_FRONTEND=noninteractive',
        unless      => '/usr/bin/dpkg -l npm && /usr/bin/dpkg -l nodejs-legacy',
        user        => 'root',
        before      => [
            Apt::Repository['nodesource'],
            Apt::Pin['nodejs'],
        ],
    }

    package { 'nodejs':
        ensure  => latest,
        require => [
            Apt::Repository['nodesource'],
            Apt::Pin['nodejs'],
        ],
    }

    exec { 'npm_set_cache_dir':
        command => "/bin/mkdir -p ${cache_dir} && /bin/chmod -R 0777 ${cache_dir}",
        unless  => "/usr/bin/test -d ${cache_dir}",
        user    => 'root',
        group   => 'root',
    }

    env::var { 'NPM_CONFIG_CACHE':
        value   => $cache_dir,
        require => Exec['npm_set_cache_dir'],
    }
}

