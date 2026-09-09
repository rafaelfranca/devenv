{ pkgs, ... }:
{
  packages = with pkgs; [
    autoconf
    automake
    cargo
    cargo-insta
    cargo-nextest
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
      ./configure -C --disable-install-doc --enable-yjit=dev --enable-zjit=dev
      make -j"''${NIX_BUILD_CORES:-$(getconf _NPROCESSORS_ONLN)}"
    '';
  };

  tasks."ruby:test" = {
    after = [ "ruby:build" ];
    exec = ''
      set -euo pipefail
      unset BUNDLE_GEMFILE BUNDLE_PATH CONFIGURE_ARGS GEM_HOME GEM_PATH RUBYLIB RUBYOPT
      make -j"''${NIX_BUILD_CORES:-$(getconf _NPROCESSORS_ONLN)}" yjit-check
      make -j"''${NIX_BUILD_CORES:-$(getconf _NPROCESSORS_ONLN)}" zjit-check
      RUBY_TEST_TIMEOUT_SCALE=10 PRECHECK_BUNDLED_GEMS=no \
        make -j"''${NIX_BUILD_CORES:-$(getconf _NPROCESSORS_ONLN)}" check
    '';
  };
}
