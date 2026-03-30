#!/bin/sh
set -eu

SQL_FILE="/var/www/html/eurotracksdb.sql"

extract_wp_config() {
  php -r '
    $f = file_get_contents("/var/www/html/wp-config.php");
    $key = $argv[1];
    $re = "/define\\(\\s*[\\x27\\\"]".preg_quote($key,"/")."[\\x27\\\"]\\s*,\\s*[\\x27\\\"]([^\\x27\\\"]*)[\\x27\\\"]\\s*\\)/";
    if (preg_match($re, $f, $m)) { echo $m[1]; }
  ' "$1"
}

DB_NAME="$(extract_wp_config DB_NAME || true)"
DB_USER="$(extract_wp_config DB_USER || true)"
DB_PASSWORD="$(extract_wp_config DB_PASSWORD || true)"
DB_HOST_STR="$(extract_wp_config DB_HOST || true)"

DB_HOST_ONLY="$(printf '%s' "$DB_HOST_STR" | cut -d: -f1)"
DB_PORT_ONLY="$(printf '%s' "$DB_HOST_STR" | cut -s -d: -f2)"
if [ -z "$DB_PORT_ONLY" ]; then
  DB_PORT_ONLY="3306"
fi

TABLE_PREFIX="cegnv_"
TARGET_SITE_URL="https://eurotruck-production.up.railway.app"

wait_for_mysql() {
  i=0
  while [ $i -lt 60 ]; do
    if mysqladmin ping -h "$DB_HOST_ONLY" -P "$DB_PORT_ONLY" -u "$DB_USER" -p"$DB_PASSWORD" --silent >/dev/null 2>&1; then
      return 0
    fi
    i=$((i + 1))
    sleep 2
  done
  return 1
}

ensure_wp_core_files() {
  if [ ! -f /var/www/html/index.php ] || [ ! -f /var/www/html/wp-blog-header.php ]; then
    cp -a /usr/src/wordpress/. /var/www/html/
    chown -R www-data:www-data /var/www/html/ 2>/dev/null || true
  fi
}

seed_wordpress_files_if_missing() {
  UPLOADS_MARKER="/var/www/html/wp-content/uploads/elementor/css/global.css"
  WP_VENDOR_MARKER="/var/www/html/wp-includes/js/dist/vendor/wp-polyfill-inert.min.js"

  if [ ! -f "$UPLOADS_MARKER" ] && [ -d "/opt/www-seed/wp-content" ]; then
    cp -a /opt/www-seed/wp-content/. /var/www/html/wp-content/
    chown -R www-data:www-data /var/www/html/wp-content/ 2>/dev/null || true
  fi

  if [ ! -f "$WP_VENDOR_MARKER" ] && [ -d "/opt/base-core/wp-includes" ]; then
    cp -a /opt/base-core/wp-includes/. /var/www/html/wp-includes/
    chown -R www-data:www-data /var/www/html/wp-includes/ 2>/dev/null || true
  fi
}

drop_all_tables() {
  tables="$(mysql -h "$DB_HOST_ONLY" -P "$DB_PORT_ONLY" -u "$DB_USER" -p"$DB_PASSWORD" -D "$DB_NAME" \
    -N -s -e "SELECT table_name FROM information_schema.tables WHERE table_schema='$DB_NAME';" 2>/dev/null || true)"
  if [ -z "$tables" ]; then
    return 0
  fi

  for t in $tables; do
    mysql -h "$DB_HOST_ONLY" -P "$DB_PORT_ONLY" -u "$DB_USER" -p"$DB_PASSWORD" -D "$DB_NAME" \
      -e "SET FOREIGN_KEY_CHECKS=0; DROP TABLE IF EXISTS \`${t}\`; SET FOREIGN_KEY_CHECKS=1;" >/dev/null 2>&1 || true
  done
}

import_sql_every_start() {
  if [ ! -f "$SQL_FILE" ]; then
    echo "SQL file not found at $SQL_FILE"
    return 1
  fi

  echo "Resetting database '${DB_NAME}' and importing '${SQL_FILE}'..."
  drop_all_tables
  mysql -h "$DB_HOST_ONLY" -P "$DB_PORT_ONLY" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$SQL_FILE"
  echo "SQL import finished."

  mysql -h "$DB_HOST_ONLY" -P "$DB_PORT_ONLY" -u "$DB_USER" -p"$DB_PASSWORD" -D "$DB_NAME" -e "
    UPDATE ${TABLE_PREFIX}options
    SET option_value='${TARGET_SITE_URL}'
    WHERE option_name IN ('siteurl','home');
  " >/dev/null 2>&1 || true
  echo "Updated siteurl/home to ${TARGET_SITE_URL}"
}

disable_broken_aio_security_plugin() {
  AIO_PLUGIN_DIR="/var/www/html/wp-content/plugins/all-in-one-wp-security-and-firewall"
  AIO_VENDOR_FILE="/var/www/html/wp-content/plugins/all-in-one-wp-security-and-firewall/vendor/team-updraft/common-libs/src/updraft-semaphore/class-updraft-semaphore.php"
  if [ ! -f "$AIO_VENDOR_FILE" ] && [ -d "$AIO_PLUGIN_DIR" ]; then
    echo "AIOWPS vendor files are missing; disabling plugin to prevent 500 crash."
    mv "$AIO_PLUGIN_DIR" "${AIO_PLUGIN_DIR}.disabled"
  fi
}

rewrite_old_urls_in_database() {
  if ! command -v wp >/dev/null 2>&1; then
    return 0
  fi

  wp option update home "${TARGET_SITE_URL}" --allow-root --path=/var/www/html >/dev/null 2>&1 || true
  wp option update siteurl "${TARGET_SITE_URL}" --allow-root --path=/var/www/html >/dev/null 2>&1 || true

  wp search-replace 'https://eurotruck.uz' "${TARGET_SITE_URL}" --all-tables --allow-root --path=/var/www/html --skip-columns=guid >/dev/null 2>&1 || true
  wp search-replace 'http://eurotruck.uz' "${TARGET_SITE_URL}" --all-tables --allow-root --path=/var/www/html --skip-columns=guid >/dev/null 2>&1 || true
  wp search-replace 'eurotruck.uz' 'eurotruck-production.up.railway.app' --all-tables --allow-root --path=/var/www/html --skip-columns=guid >/dev/null 2>&1 || true
  wp search-replace 'https://www.eurotruck.uz' "${TARGET_SITE_URL}" --all-tables --allow-root --path=/var/www/html --skip-columns=guid >/dev/null 2>&1 || true
  wp search-replace 'http://www.eurotruck.uz' "${TARGET_SITE_URL}" --all-tables --allow-root --path=/var/www/html --skip-columns=guid >/dev/null 2>&1 || true
  wp search-replace 'https://unimaxtec.uz' "${TARGET_SITE_URL}" --all-tables --allow-root --path=/var/www/html --skip-columns=guid >/dev/null 2>&1 || true
  wp search-replace 'http://unimaxtec.uz' "${TARGET_SITE_URL}" --all-tables --allow-root --path=/var/www/html --skip-columns=guid >/dev/null 2>&1 || true
  wp search-replace '//eurotruck.uz' '//eurotruck-production.up.railway.app' --all-tables --allow-root --path=/var/www/html --skip-columns=guid >/dev/null 2>&1 || true
  wp search-replace '\/\/eurotruck.uz' '\/\/eurotruck-production.up.railway.app' --all-tables --allow-root --path=/var/www/html --skip-columns=guid >/dev/null 2>&1 || true
}

rewrite_old_asset_urls() {
  CSS_DIR="/var/www/html/wp-content/uploads/elementor/css"
  if [ ! -d "$CSS_DIR" ]; then
    return 0
  fi

  find "$CSS_DIR" -type f -name "*.css" \
    -exec sed -i "s|https://eurotruck.uz|${TARGET_SITE_URL}|g" {} + || true
  find "$CSS_DIR" -type f -name "*.css" \
    -exec sed -i "s|http://eurotruck.uz|${TARGET_SITE_URL}|g" {} + || true
  find "$CSS_DIR" -type f -name "*.css" \
    -exec sed -i "s|eurotruck.uz|eurotruck-production.up.railway.app|g" {} + || true
  find "$CSS_DIR" -type f -name "*.css" \
    -exec sed -i "s|https://www.eurotruck.uz|${TARGET_SITE_URL}|g" {} + || true
  find "$CSS_DIR" -type f -name "*.css" \
    -exec sed -i "s|http://www.eurotruck.uz|${TARGET_SITE_URL}|g" {} + || true
  find "$CSS_DIR" -type f -name "*.css" \
    -exec sed -i "s|//eurotruck.uz|//eurotruck-production.up.railway.app|g" {} + || true
}

disable_problematic_plugins() {
  if ! command -v wp >/dev/null 2>&1; then
    return 0
  fi

  # AIOWPS rename-login feature is causing runtime warnings and bad redirects on Railway.
  wp plugin deactivate all-in-one-wp-security-and-firewall --allow-root --path=/var/www/html >/dev/null 2>&1 || true
  wp option patch update aio_wp_security_configs aiowps_enable_rename_login_page '' --allow-root --path=/var/www/html >/dev/null 2>&1 || true
  wp option patch update aio_wp_security_configs aiowps_login_page_slug '' --allow-root --path=/var/www/html >/dev/null 2>&1 || true
}

sanitize_known_malware() {
  # Remove known backdoor files from wp-content and replace infected stubs.
  rm -f /var/www/html/wp-content/install.php /var/www/html/wp-content/item.php || true

  for f in \
    /var/www/html/wp-content/plugins/translatepress-multilingual/assets/css/galleries/index.php \
    /var/www/html/wp-content/plugins/elementor-pro/core/notifications/query-content/index.php \
    /var/www/html/wp-content/plugins/ultimate-post-kit/assets/images/cloudflare/index.php \
    /var/www/html/wp-content/plugins/ultimate-post-kit/modules/alice-carousel/audits/index.php \
    /var/www/html/wp-content/plugins/elementor/modules/safe-mode/audits/index.php \
    /var/www/html/wp-content/plugins/elementor/core/debug/i18ns/index.php
  do
    if [ -f "$f" ] && grep -Eq 'secretyt|pwdyt|j250704_13|j250703_13|TW2KX\(strrev|Zkf2V\(strrev' "$f" 2>/dev/null; then
      printf '%s\n%s\n' '<?php' '// Silence is golden.' > "$f"
    fi
  done
}

fix_desktop_hero_fallback() {
  CSS_FILE="/var/www/html/wp-content/uploads/elementor/css/post-20.css"
  if [ ! -f "$CSS_FILE" ]; then
    return 0
  fi

  sed -E -i 's#background-image:var\(--e-bg-lazyload-loaded\);--e-bg-lazyload:url\("([^"]+)"\);#background-image:url("\1");--e-bg-lazyload:url("\1");#g' "$CSS_FILE" || true
}

finalize_wp_runtime() {
  if ! command -v wp >/dev/null 2>&1; then
    return 0
  fi
  # Flush Elementer CSS (regenerate) and WP rewrite to make sure new URLs/styles apply.
  wp elementor flush_css --allow-root --path=/var/www/html >/dev/null 2>&1 || true
  wp cache flush --allow-root --path=/var/www/html >/dev/null 2>&1 || true
  wp rewrite flush --hard --allow-root --path=/var/www/html >/dev/null 2>&1 || true
}

echo "Waiting for MySQL..."
wait_for_mysql
ensure_wp_core_files
seed_wordpress_files_if_missing
disable_broken_aio_security_plugin
import_sql_every_start
rewrite_old_urls_in_database
rewrite_old_asset_urls
disable_problematic_plugins
sanitize_known_malware
fix_desktop_hero_fallback
finalize_wp_runtime

exec "$@"
