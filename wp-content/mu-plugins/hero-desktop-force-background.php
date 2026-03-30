<?php
/**
 * Force homepage hero background on desktop.
 * Elementor lazyload var can become empty on some environments.
 */

add_action('wp_head', function () {
    echo '<style id="hero-desktop-force-background">
    @media (min-width:1025px){
      /* This specific hero section is marked as elementor-hidden-desktop in DB.
         Force the section itself back to visible on desktop. */
      body.home .elementor-20 .elementor-element.elementor-element-de6d8e2.elementor-hidden-desktop{
        display:block !important;
        visibility:visible !important;
        opacity:1 !important;
      }
      body.home .elementor-20 .elementor-element.elementor-element-de6d8e2 > .elementor-container{
        min-height:500px !important;
      }

      .elementor-20 .elementor-element.elementor-element-de6d8e2:not(.elementor-motion-effects-element-type-background),
      .elementor-20 .elementor-element.elementor-element-de6d8e2 > .elementor-motion-effects-container > .elementor-motion-effects-layer{
        background-image:url("/wp-content/uploads/2023/05/new_rtg_bg2.png") !important;
        background-position:bottom center !important;
        background-repeat:no-repeat !important;
        background-size:cover !important;
      }
    }
    </style>';
}, 999);
