<?php
if (getenv('NC_SMTP_HOST') && getenv('NC_MAIL_FROM_ADDRESS') && getenv('NC_MAIL_DOMAIN')) {
  $CONFIG = array (
    'mail_smtpmode' => 'smtp',
    'mail_smtphost' => getenv('NC_SMTP_HOST'),
    'mail_smtpport' => getenv('NC_SMTP_PORT') ?: (getenv('NC_SMTP_SECURE') ? 465 : 25),
    'mail_smtpsecure' => getenv('NC_SMTP_SECURE') ?: '',
    'mail_smtpauth' => getenv('NC_SMTP_NAME') && (getenv('NC_SMTP_PASSWORD') || (getenv('NC_SMTP_PASSWORD_FILE') && file_exists(getenv('NC_SMTP_PASSWORD_FILE')))),
    'mail_smtpauthtype' => getenv('NC_SMTP_AUTHTYPE') ?: 'LOGIN',
    'mail_smtpname' => getenv('NC_SMTP_NAME') ?: '',
    'mail_from_address' => getenv('NC_MAIL_FROM_ADDRESS'),
    'mail_domain' => getenv('NC_MAIL_DOMAIN')
  );

  if (getenv('NC_SMTP_PASSWORD_FILE') && file_exists(getenv('NC_SMTP_PASSWORD_FILE'))) {
      $CONFIG['mail_smtppassword'] = trim(file_get_contents(getenv('NC_SMTP_PASSWORD_FILE')));
  } elseif (getenv('NC_SMTP_PASSWORD')) {
      $CONFIG['mail_smtppassword'] = getenv('NC_SMTP_PASSWORD');
  } else {
      $CONFIG['mail_smtppassword'] = '';
  }
}
