<?php
$redis = parse_url(getenv('REDIS_URL'));

if (getenv('REDIS_URL')) {
  $CONFIG = array(
    'filelocking.enabled' => true,
    'memcache.distributed' => '\OC\Memcache\Redis',
    'memcache.locking' => '\OC\Memcache\Redis',
    'redis' => array(
      'host' => $redis['host'],
      'port' => $redis['port'],
      'password' => (string) $redis['pass'],
      'timeout'       => 1.5,
      'read_timeout'  => 1.5,
    ),
  );
}
