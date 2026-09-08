{ pkgs, ... }:
{
  languages.ruby = {
    enable = true;
    version = "4.0.6";
    lsp.enable = false;
  };

  packages = with pkgs; [
    libyaml
    pkg-config
    sqlite
  ];

  tasks."activeresource:setup" = {
    exec = ''
      set -euo pipefail
      bundle install
    '';
  };
}
