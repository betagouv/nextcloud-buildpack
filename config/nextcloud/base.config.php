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
  'theme' => ''
);

$trustedDomains = getenv('NC_TRUSTED_DOMAINS');
if ($trustedDomains) {
  $CONFIG['overwrite.cli.url'] = 'https://'.$trustedDomains;
  $CONFIG['overwriteprotocol'] = 'https';
  $CONFIG['overwritehost'] = $trustedDomains;
}
