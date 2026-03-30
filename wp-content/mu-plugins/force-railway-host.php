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

function eurotruck_force_host_in_url($url) {
    if (empty($url) || !is_string($url)) {
        return $url;
    }

    $p = wp_parse_url($url);
    if (!is_array($p)) {
        return $url;
    }

    $path = isset($p['path']) ? $p['path'] : '';
    $query = isset($p['query']) ? '?' . $p['query'] : '';
    $fragment = isset($p['fragment']) ? '#' . $p['fragment'] : '';

    return EUROTRUCK_FORCE_SCHEME . '://' . EUROTRUCK_FORCE_HOST . $path . $query . $fragment;
}

add_filter('pre_option_home', 'eurotruck_force_option_url', 1);
add_filter('pre_option_siteurl', 'eurotruck_force_option_url', 1);
add_filter('option_home', 'eurotruck_force_option_url', 1);
add_filter('option_siteurl', 'eurotruck_force_option_url', 1);

add_filter('home_url', function ($url) {
    return eurotruck_force_host_in_url($url);
}, 1);

add_filter('site_url', function ($url) {
    return eurotruck_force_host_in_url($url);
}, 1);

add_filter('redirect_canonical', function ($redirect_url) {
    return eurotruck_force_host_in_url($redirect_url);
}, 1);
