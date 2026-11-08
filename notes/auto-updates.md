---
id: auto-updates
aliases: []
tags: []
---

Mostly for security purposes I would like to have the system automatically pull in package upgrades periodically. One caveat, I would like some minimum age on the package to avoid pulling in something that gets maliciously published and adding it to my build before it gets caught.

Also let's say there is a vulnerability detected in my stack, how can I detect it automatically?

Some resources to check out:

[general official docs on the topic](https://wiki.nixos.org/wiki/Automatic_system_upgrades)

[how to do in Home Manager specifically](https://nix-community.github.io/home-manager/options/home-manager/services/home-manager.html#opt-services.home-manager.autoUpgrade)


