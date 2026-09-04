{ config, ... }:

{
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixos-config/modules/programs/claude-code-settings.json";
}
