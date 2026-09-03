{ hostName, ... }:

{
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = "nixos_small";
      display.color = if hostName == "bubu-brain" then "yellow" else "red";
      modules = [
        "title"
        "separator"
        "os"
        "host"
        "uptime"
        "packages"
        "memory"
        "processes"
        "shell"
        "lm"
        "wm"
        "cursor"
        "terminal"
        "terminalfont"
      ];
    };
  };
}
