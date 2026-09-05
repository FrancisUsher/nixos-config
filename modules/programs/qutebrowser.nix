{ ... }:

{
  programs.qutebrowser = {
    enable = true;

    settings = {
      auto_save.session = true;
      colors.webpage.darkmode.enabled = true;
      # Images off by default, whitelisted per-domain below.
      content.images = false;
    };

    # arch-reference's config.py disabled images globally, then re-enabled
    # them per-domain via a whitelist loop over config.pattern(url) blocks.
    perDomainSettings = {
      "*://*.usher.codes/*".content.images = true;
      "*://wallhaven.cc/*".content.images = true;
      "*://github.com/*".content.images = true;
      "*://*.github.io/*".content.images = true;
      "*://ohmyposh.dev/*".content.images = true;
      "*://*.jethro.dev/*".content.images = true;
      "*://quickshell.org/*".content.images = true;
      "*://drop.com/*".content.images = true;
      "*://*.wikipedia.org/*".content.images = true;
      "*://*.zmk.dev/*".content.images = true;
      "*://www.kiserdesigns.com/*".content.images = true;
    };
  };
}
