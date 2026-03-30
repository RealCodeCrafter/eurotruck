<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the
 * installation. You don't have to use the web site, you can
 * copy this file to "wp-config.php" and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * MySQL settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://codex.wordpress.org/Editing_wp-config.php
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', 'railway');

/** MySQL database username */
define('DB_USER', 'root');

/** MySQL database password */
define('DB_PASSWORD', 'xaUTIEvPzUzMPtjyxAzgyFQlUwjInFAY');

/** MySQL hostname */
define('DB_HOST', 'hopper.proxy.rlwy.net:45011');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define('AUTH_KEY',         'b7U@Ma4GT8lzj8T5!NfsqAZc^kQ)yxM*MzF3N&*u2AoRm^XO4Vw5)9NG9(9%)Qa&');
define('SECURE_AUTH_KEY',  'H#qpORb0)!C82wwIYjpNFA**wyg8hMdLo1VTwo8ruj2gEWfmZPqJ#u7*BoysQhTP');
define('LOGGED_IN_KEY',    's&JDB!ja5go%7vPt4fgK@8Ql7mdb3oaUF8jD%WT))&lxDVADN#NxaC)I%BC(UXbn');
define('NONCE_KEY',        'MgCmI%hj7JQJMrbtKT34dXYT))iWL0vyypNxgpqaU&hZw0rfXF#RY*2wTXnY7@dT');
define('AUTH_SALT',        'EuHln@jhDJTO1Pzq(bF%ubg@Nd%(GlY3!m1Ao0D(d#pe(5n@0QCE2e5r7(fRm8Mi');
define('SECURE_AUTH_SALT', 'UiKVH2nkGNVUR@52YK^1OPA1YcUYlNa7WVNF00@3yaIAKwCJD8WHz4&foEfUK@fT');
define('LOGGED_IN_SALT',   'XdyRbS2zGOcb7tckGqvEtDoMHgG2t4Ig4#%Z1JTO3mNugaq&i*SFe3vv%@!5m%Am');
define('NONCE_SALT',       'edxcDfnbjI1X%PNEQufwPM^h8O!lgHCkfM5#ghMQPqZ3e7gnvs3kEtzb^MuRXk%u');
/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix  = 'cegnv_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */
define('WP_DEBUG', false);

// Railway reverse proxy HTTPS support.
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && strtolower($_SERVER['HTTP_X_FORWARDED_PROTO']) === 'https') {
	define('WP_FORCE_HTTPS', true);
	$_SERVER['HTTPS'] = 'on';
}

/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

define('WP_ALLOW_MULTISITE', true);
define('FS_METHOD', 'direct');
define('DISALLOW_FILE_EDIT', true);

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');