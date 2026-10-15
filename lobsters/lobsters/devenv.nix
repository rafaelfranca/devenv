{ config, lib, pkgs, ... }:
{
  languages.ruby = {
    enable = true;
    version = "4.0.0";
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
    vips
  ];

  tasks."lobsters:setup" = {
    exec = ''
      set -euo pipefail
      bundle install
      if [ ! -f config/database.yml ]; then
        cp config/database.yml.sample config/database.yml
      fi
      bin/rails db:prepare
    '';
  };
}
