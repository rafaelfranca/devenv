{ config, lib, pkgs, ... }:
{
  languages.ruby = {
    enable = true;
    version = "3.4.7";
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
    redis
    sqlite
    vips
  ];

  # Development Action Cable fixes Redis at localhost:6379.
  # The Redis service module can select a different port.
  env.REDISDATA = "${config.env.DEVENV_STATE}/redis";
  processes.redis = {
    exec = ''
      set -euo pipefail
      mkdir -p "$REDISDATA"
      exec redis-server --bind 127.0.0.1 --port 6379 --dir "$REDISDATA"
    '';
    ready.exec = "redis-cli -h 127.0.0.1 -p 6379 ping";
  };

  tasks."writebook:setup" = {
    exec = ''
      set -euo pipefail
      bundle install
      bin/rails db:prepare
    '';
  };
}
