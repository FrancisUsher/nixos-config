{ ... }:

{
  programs.ssh = {
    enable = true;
    settings."bubu-brain*".User = "soong";
  };
}
