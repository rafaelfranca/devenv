{ config, lib, pkgs, ... }:
{
  languages.ruby = {
    enable = true;
    version = "3.4.8";
    lsp.enable = false;
  };

  # Native gems must not be reused after the Ruby package changes.
  env.BUNDLE_PATH = lib.mkForce (
    "${config.env.DEVENV_STATE}/.bundle/"
    + builtins.baseNameOf (toString config.languages.ruby.package)
  );

  packages = with pkgs; [
    ffmpeg
    imagemagick
    libyaml
    mupdf
    openslide
    pkg-config
    sqlite
    vips
  ];

  tasks."fizzy:setup" = {
    exec = ''
      set -euo pipefail
      bundle install
      bin/rails db:prepare
    '';
  };
}
