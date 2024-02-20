<?php

// Parsing the URL
$parsed_url = parse_url($getenv('DATABASE_URL'));

// Extracting individual components
$dbname = ltrim($parsed_url['path'], '/');
$dbhost = $parsed_url['host'];
$dbport = $parsed_url['port'];
$db_user = $parsed_url['user'];
$db_password = $parsed_url['pass'];


$CONFIG = array (
  'dbname' => ltrim($parsed_url['path'], '/'),
  'dbhost' => $parsed_url['host'],
  'dbport' => $parsed_url['port'],
  'dbtableprefix' => 'oc_',
  'dbuser' => $parsed_url['user'],
  'dbpassword' => $parsed_url['pass'],
  'installed' => true,
  'instanceid' => '',
);
