{ config, lib, pkgs, ... }:
{
  languages.ruby = {
    enable = true;
    version = "4.0.6";
    lsp.enable = false;
  };

  # Native gems must not be reused after the Ruby package changes.
  env.BUNDLE_PATH = lib.mkForce (
    "${config.env.DEVENV_STATE}/.bundle/"
    + builtins.baseNameOf (toString config.languages.ruby.package)
  );

  packages = with pkgs; [
    libyaml
    pkg-config
  ];

  tasks."globalid:setup" = {
    exec = ''
      set -euo pipefail
      BUNDLE_FROZEN=true bundle install
    '';
  };
}
