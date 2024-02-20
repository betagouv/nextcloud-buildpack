<?php

// Parsing the URL
$parsed_url = parse_url(getenv('DATABASE_URL'));

// Extracting individual components
$dbname = ltrim($parsed_url['path'], '/');
$dbhost = $parsed_url['host'];
$dbport = $parsed_url['port'];
$db_user = $parsed_url['user'];
$db_password = $parsed_url['pass'];


$CONFIG = array (
  'dbname' => $dbname,
  'dbhost' => $dbhost,
  'dbport' => $dbport,
  'dbtableprefix' => 'oc_',
  'dbuser' => $db_user,
  'dbpassword' => $db_password,
  'installed' => true,
  'instanceid' => '',
);
