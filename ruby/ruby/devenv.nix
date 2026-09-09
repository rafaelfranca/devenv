{ pkgs, ... }:
let
  testTask = target: {
    exec = ''
      set -euo pipefail
      unset BUNDLE_GEMFILE BUNDLE_PATH CONFIGURE_ARGS GEM_HOME GEM_PATH RUBYLIB RUBYOPT
      RUBY_TEST_TIMEOUT_SCALE=10 RUBY_TESTOPTS='-q --tty=no' \
        ruby -e 'pid = fork { Process.setsid; exec(*ARGV) }; Process.wait(pid); exit($?.exitstatus || 1)' \
        -- make -j"''${NIX_BUILD_CORES:-$(getconf _NPROCESSORS_ONLN)}" ${target} </dev/null
    '';
  };
in
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

  tasks."ruby:bootstrap:test" = testTask "btest";
  tasks."ruby:short:test" = testTask "test";
  tasks."ruby:basic:test" = testTask "test-basic";
  tasks."ruby:framework:test" = testTask "test-testframework";
  tasks."ruby:tool:test" = testTask "test-tool";
  tasks."ruby:all:test" = testTask "test-all";
  tasks."ruby:language:test" = testTask "test-ruby";
  tasks."ruby:ractor:test" = testTask "rtest";
  tasks."ruby:spec:test" = testTask "test-spec";
  tasks."ruby:bundler:test" = testTask "test-bundler";
  tasks."ruby:bundled-gems:test" = testTask "test-bundled-gems";
  tasks."ruby:syntax-suggest:test" = testTask "test-syntax-suggest";
  tasks."ruby:yjit:test" = testTask "yjit-check";
  tasks."ruby:zjit:test" = testTask "zjit-check";
  tasks."ruby:zjit:unit:test" = testTask "zjit-test";
  tasks."ruby:check" = testTask "check";

  tasks."ruby:test" = {
    after = [ "ruby:yjit:test" "ruby:zjit:test" "ruby:check" ];
    exec = ":";
  };
}
