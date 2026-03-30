<?php
/**
 * Force canonical host to Railway URL.
 * This runs before normal plugins and prevents legacy domain redirects.
 */

if (!defined('EUROTRUCK_FORCE_SCHEME')) {
    define('EUROTRUCK_FORCE_SCHEME', 'https');
}
if (!defined('EUROTRUCK_FORCE_HOST')) {
    define('EUROTRUCK_FORCE_HOST', 'eurotruck-production.up.railway.app');
}

function eurotruck_forced_base_url() {
    return EUROTRUCK_FORCE_SCHEME . '://' . EUROTRUCK_FORCE_HOST;
}

function eurotruck_force_option_url($value) {
    return eurotruck_forced_base_url();
}

add_filter('pre_option_home', 'eurotruck_force_option_url', 1);
add_filter('pre_option_siteurl', 'eurotruck_force_option_url', 1);
add_filter('option_home', 'eurotruck_force_option_url', 1);
add_filter('option_siteurl', 'eurotruck_force_option_url', 1);

add_filter('home_url', function ($url, $path, $orig_scheme) {
    return set_url_scheme(eurotruck_forced_base_url(), $orig_scheme) . $path;
}, 1, 3);

add_filter('site_url', function ($url, $path, $scheme) {
    return set_url_scheme(eurotruck_forced_base_url(), $scheme) . $path;
}, 1, 3);

add_filter('redirect_canonical', function ($redirect_url) {
    if (empty($redirect_url)) {
        return $redirect_url;
    }

    $target = wp_parse_url($redirect_url);
    if (!is_array($target)) {
        return $redirect_url;
    }

    $target['scheme'] = EUROTRUCK_FORCE_SCHEME;
    $target['host'] = EUROTRUCK_FORCE_HOST;
    $target['port'] = null;

    $path = isset($target['path']) ? $target['path'] : '/';
    $query = isset($target['query']) ? '?' . $target['query'] : '';
    $fragment = isset($target['fragment']) ? '#' . $target['fragment'] : '';

    return EUROTRUCK_FORCE_SCHEME . '://' . EUROTRUCK_FORCE_HOST . $path . $query . $fragment;
}, 1);
