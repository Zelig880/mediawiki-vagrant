# == Class mediawiki::extension::scribunto
#
class mediawiki::extension::scribunto {
    apt::pin { 'luasandbox':
        ensure   => absent,
        package  => 'php-luasandbox',
        pin      => 'release a=stretch-backports',
        priority => 1001,
    }
}
