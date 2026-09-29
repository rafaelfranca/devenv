{ pkgs, ... }:
{
  languages.rust.enable = true;

  languages.ruby = {
    enable = true;
    lsp.enable = false;
  };

  languages.javascript = {
    enable = true;
    package = pkgs.nodejs_24;
    lsp.enable = false;
  };

  packages = with pkgs; [
    pkg-config
    sqlite
    wrk
  ];
}
