<?php
$CONFIG = array (
  // Leave empty to not copy any skeleton files
  'skeletondirectory' => '',
  'templatedirectory' => '',
  // disable Help menu item in the user menu
  'knowledgebaseenabled' => false,
  // enable previews
  'enable_previews' => true,
  // theme
  'theme' => '',
  'log_type' => 'errorlog',
  'log_type_audit' => 'errorlog',
  'loglevel' => getenv('NC_CONFIG_LOGLEVEL') ?: 2,
  'loglevel_frontend' => getenv('NC_CONFIG_LOGLEVEL_FRONTEND') ?: 2,
  'instanceid' => 'ocxl4ele2dpm',
);

$trustedDomains = getenv('NC_TRUSTED_DOMAINS');
$overwriteProtocol = getenv('NC_CONFIG_OVERWRITEPROTOCOL') ?: 'https';
if ($trustedDomains) {
  $CONFIG['overwrite.cli.url'] = $overwriteProtocol.'://'.$trustedDomains;
  $CONFIG['overwriteprotocol'] = $overwriteProtocol;
  $CONFIG['overwritehost'] = $trustedDomains;
}
