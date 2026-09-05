{ ... }:

{
  stylix.targets.starship.enable = true;

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    # Diamond/powerline prompt reusing the same segment layout and colors as
    # arch-reference's retired oh-my-posh config (colored.omp.toml): username
    # on red, cwd on green, git on cyan, time on purple, dark text on every
    # segment. Colors come from Stylix's base16 palette (stylix.targets.
    # starship above) instead of arch-reference's hardcoded hex.
    settings = {
      add_newline = true;

      format = ''
        [](fg:red)[$username](bg:red fg:black)[](fg:red bg:green)[$directory](bg:green fg:black)[](fg:green bg:cyan)[$git_branch$git_status](bg:cyan fg:black)[](fg:cyan bg:purple)[$time](bg:purple fg:black)[](fg:purple)
        $character'';

      username = {
        show_always = true;
        format = "[ $user ]($style)";
        style_user = "bg:red fg:black";
        style_root = "bg:red fg:black";
      };

      directory = {
        format = "[ $path ]($style)";
        style = "bg:green fg:black";
        truncation_length = 3;
        truncate_to_repo = true;
      };

      git_branch = {
        format = "[$symbol$branch]($style)";
        style = "bg:cyan fg:black";
        symbol = " ";
      };

      git_status = {
        format = "[$all_status$ahead_behind ]($style)";
        style = "bg:cyan fg:black";
      };

      time = {
        disabled = false;
        format = "[ $time ]($style)";
        style = "bg:purple fg:black";
        time_format = "%H:%M";
      };

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
    };
  };
}
