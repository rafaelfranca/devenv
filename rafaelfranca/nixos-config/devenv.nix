{ pkgs, ... }:

{
  packages = with pkgs; [
    nixd
    nixpkgs-fmt
    statix
  ];

  enterShell = ''
    echo "Nix development environment loaded"
    echo "Available tools:"
    echo "  - nixd: Nix language server"
    echo "  - nixpkgs-fmt: Nix code formatter"
    echo "  - statix: Nix linter"
  '';
}
