# == Class: browsertests
#
# Configures the environment to be used with Wikimedia Foundation's
# Selenium-driven browser tests.
#
# To run the tests, you'll need to enable X11 forwarding for the SSH
# session you use to connect to your Vagrant instance. You can do so by
# running 'vagrant ssh -- -X'.
#
# Note that including this class only sets up the environment for running
# tests; it no longer installs and configures the qa/browsertests project
# itself. For the latter, include role::browsertests.
#
# === Parameters
#
# [*default_browser*]
#   Default browser used in browser tests. Possible values are 'firefox' or
#   'phantomjs' (experimental). Default: 'firefox'.
#
# [*selenium_user*]
#   MediaWiki account name used when executing browser tests.
#
# [*selenium_password*]
#   Password for the MediaWiki account.
#
# [*mediawiki_url*]
#   URL of the wiki to be tested. Default: 'http://127.0.0.1/wiki/'.
#
# [*mediawiki_api_url*]
#   URL of the wiki API to be tested. Default: 'http://127.0.0.1/w/api.php'.
#
# === Examples
#
#  Configure the browser tests to run against Wikimedia's beta cluster
#  (see <http://www.mediawiki.org/wiki/Beta_cluster>):
#
#    class { 'browsertests':
#        mediawiki_url    => 'http://deployment.wikimedia.beta.wmflabs.org/wiki/',
#    }
#
class browsertests(
    $default_browser   = 'firefox',
    $selenium_user     = 'Selenium_user',
    $selenium_password = 'vagrant',
    $mediawiki_url     = 'http://127.0.0.1/wiki/',
    $mediawiki_api_url = 'http://127.0.0.1/w/api.php',
) {
    mediawiki::user { $selenium_user:
        password => $selenium_password,
    }

    # Set defaults for all environment variables required for testing.
    env::var { 'BROWSER':
        value => $default_browser,
    }

    env::var { 'MEDIAWIKI_URL':
        value => $mediawiki_url,
    }

    env::var { 'MEDIAWIKI_API_URL':
        value => $mediawiki_api_url,
    }

    env::var { 'MEDIAWIKI_USER':
        value => $selenium_user,
    }

    env::var { 'MEDIAWIKI_PASSWORD':
        value => $selenium_password,
    }

    package { $default_browser:
        ensure => present,
    }
}
