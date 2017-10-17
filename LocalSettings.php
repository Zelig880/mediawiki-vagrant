<?php
/**
 * MediaWiki configuration
 *
 * To customize your MediaWiki instance, you may change the content of this
 * file. See settings.d/README for an alternate way of managing small snippets
 * of configuration data, such as extension invocations.
 *
 * This file is part of Mediawiki-Vagrant.
 */

// Enable error reporting
error_reporting( -1 );
ini_set( 'display_errors', 1 );

// WMF specific HHVM builds don't support unix socket connections to MySQL.
// Use IP address rather than default of 'localhost' to help runtime pick the
// right connection method.
$wgDBserver = '127.0.0.1';

$wgUploadDirectory = '/srv/images';
$wgUploadPath = '/images';
$wgArticlePath = "/wiki/$1";
$wgMaxShellMemory = 1024 * 512;

// Show the debug toolbar if 'debug' is set on the request, either as a
// parameter or a cookie.
if ( !empty( $_REQUEST['debug'] ) ) {
	$wgDebugToolbar = true;
}

// Expose debug info for PHP errors.
$wgShowExceptionDetails = true;

$logDir = '/vagrant/logs';
foreach ( array( 'exception', 'runJobs', 'JobQueueRedis' ) as $logGroup ) {
	$wgDebugLogGroups[$logGroup] = "{$logDir}/mediawiki-{$logGroup}.log";
}

// Calls to deprecated methods will trigger E_USER_DEPRECATED errors
// in the PHP error log.
$wgDevelopmentWarnings = true;

// Expose debug info for SQL errors.
$wgDebugDumpSql = true;
$wgShowDBErrorBacktrace = true;
$wgShowSQLErrors = true;

// Profiling
$wgDebugProfiling = false;

// Images
$wgLogo = '/mediawiki-vagrant.png';
$wgLogoHD = [
	'1.5x' => '/mediawiki-vagrant-1.5x.png',
	'2x'   => '/mediawiki-vagrant-2x.png'
];

$wgUseInstantCommons = true;
$wgEnableUploads = true;

// User settings and permissions
$wgAllowUserJs = true;
$wgAllowUserCss = true;

$wgEnotifWatchlist = true;
$wgEnotifUserTalk = true;

// Eligibility for autoconfirmed group
$wgAutoConfirmAge = 3600 * 24; // one day
$wgAutoConfirmCount = 5; // five edits

// Caching
$wgObjectCaches['redis'] = array(
    'class' => 'RedisBagOStuff',
    'servers' => array( '127.0.0.1:6379' ),
    'persistent' => true,
);
$wgMainCacheType = 'redis';

// This is equivalent to redis_local in production, since MediaWiki-Vagrant only has one
// data center.
$wgMainStash = 'redis';

// Avoid user request serialization and other slowness
$wgSessionCacheType = 'redis';
$wgSessionsInObjectCache = true;

// Jobqueue
$wgJobTypeConf['default'] = array(
	'class'       => 'JobQueueRedis',
	'daemonized'  => true,
	'redisServer' => '127.0.0.1',
	'redisConfig' => array( 'connectTimeout' => 2, 'compression' => 'gzip' ),
);

$wgJobQueueAggregator = array(
	'class'        => 'JobQueueAggregatorRedis',
	'redisServers' => array( '127.0.0.1' ),
	'redisConfig'  => array( 'connectTimeout' => 2 ),
);

$wgLegacyJavaScriptGlobals = false;
$wgEnableJavaScriptTest = true;

require_once __DIR__ . '/settings.d/wikis/CommonSettings.php';

// XXX: Is this a bug in core? (ori-l, 27-Aug-2013)
$wgHooks['GetIP'][] = function ( &$ip ) {
	if ( PHP_SAPI === 'cli' ) {
		$ip = '127.0.0.1';
	}
	return true;
};

// Execute all jobs via standalone jobrunner service rather than
// piggybacking them on web requests.
$wgJobRunRate = 0;

// Bug 73037: handmade gzipping sometimes makes error messages impossible to see in HHVM
$wgDisableOutputCompression = true;

// Allow 'vagrant' password.
$wgPasswordPolicy['policies']['sysop']['MinimalPasswordLength'] = 7;
$wgPasswordPolicy['policies']['bureaucrat']['MinimalPasswordLength'] = 7;

// Ensure that full LoggerFactory configuration is applied
MediaWiki\Logger\LoggerFactory::registerProvider(
	ObjectFactory::getObjectFromSpec( $wgMWLoggerDefaultSpi )
);

// Don't gloss over errors in class name letter-case.
$wgAutoloadAttemptLowercase = false;
