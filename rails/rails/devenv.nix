{ config, pkgs, ... }:
{
  languages.ruby = {
    enable = true;
    version = "4.0.6";
    lsp.enable = false;
  };

  languages.javascript = {
    enable = true;
    package = pkgs.nodejs_24;
    lsp.enable = false;
    yarn.enable = true;
  };

  packages = with pkgs; [
    ffmpeg
    imagemagick
    libpq
    libpq.pg_config
    libxml2
    libyaml
    mupdf
    pkg-config
    poppler-utils
    sqlite
    vips
  ];

  services.postgres = {
    enable = true;
    package = pkgs.postgresql_16;
  };

  services.mysql = {
    enable = true;
    package = pkgs.mysql84;
    settings.mysqld.port = 3307;
  };

  env.MYSQL_HOST = "127.0.0.1";
  env.MYSQL_PORT = toString config.processes.mysql.ports.main.value;

  services.redis.enable = true;
  env.REDIS_URL = "redis://127.0.0.1:${toString config.processes.redis.ports.main.value}/0";

  services.memcached = {
    enable = true;
    startArgs = [ "-m" "1024" ];
  };
  env.MEMCACHE_SERVERS = "127.0.0.1:${toString config.processes.memcached.ports.main.value}";

  tasks."rails:setup" = {
    after = [
      "devenv:processes:postgres@ready"
      "devenv:processes:mysql@ready"
    ];
    exec = ''
      set -euo pipefail
      pg_isready
      mysqladmin --user=root ping
      bundle install
      yarn install
      bundle exec rake activerecord:db:rebuild
    '';
  };
}
