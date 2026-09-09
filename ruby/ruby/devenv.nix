{ pkgs, ... }:
{
  packages = with pkgs; [
    autoconf
    automake
    cargo
    git
    gmp
    gnumake
    gperf
    libffi
    libtool
    libyaml
    openssl
    pkg-config
    readline
    ruby
    rustc
    zlib
  ];

  tasks."ruby:build" = {
    exec = ''
      set -euo pipefail
      unset BUNDLE_GEMFILE BUNDLE_PATH CONFIGURE_ARGS GEM_HOME GEM_PATH RUBYLIB RUBYOPT
      ./autogen.sh
      ./configure -C --disable-install-doc
      make -j"''${NIX_BUILD_CORES:-1}"
    '';
  };

  tasks."ruby:test" = {
    after = [ "ruby:build" ];
    exec = ''
      set -euo pipefail
      unset BUNDLE_GEMFILE BUNDLE_PATH CONFIGURE_ARGS GEM_HOME GEM_PATH RUBYLIB RUBYOPT
      RUBY_TEST_TIMEOUT_SCALE=10 PRECHECK_BUNDLED_GEMS=no \
        make -j"''${NIX_BUILD_CORES:-1}" check
    '';
  };
}
