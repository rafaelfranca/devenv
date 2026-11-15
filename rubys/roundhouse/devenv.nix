{ pkgs, lib, ... }:
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
    libclang.lib
    libyaml
    pkg-config
    sqlite
    vips
    wrk
  ];

  # ruby-rbs-sys and ruby-prism-sys use bindgen, which loads libclang.so at
  # build time. clang on PATH is not enough on Linux.
  env.LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";

  # ruby-vips opens libvips through ffi by soname (libvips.so.42). ffi
  # searches the dynamic loader path, not pkg-config.
  env.LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.vips ];

  # The gems Roundhouse CI's unit job installs for emitted-Ruby tests.
  # markly is not in nixpkgs, so these come from rubygems into GEM_HOME.
  # The status check loads each one, so a gem whose native extension was
  # built for another Ruby is installed again.
  tasks."roundhouse:gems" = {
    exec = ''
      gem install --no-document rails-html-sanitizer sqlite3 bcrypt rack ruby-vips markly
      gem install --no-document activerecord -v '~> 8.1.0'
    '';
    status = ''
      ruby -e 'gem "activerecord", "~> 8.1.0"
        %w[rails-html-sanitizer sqlite3 bcrypt rack vips markly active_record].each { |lib| require lib }' 2>/dev/null
    '';
  };
}
