{
  pkgs,
  lib,
  coreutils,
  udev,
  fetchurl,
  util-linux,
  openjdk17_headless,
  ...
}: 
let
  version = "5.0.5";
  graylog = pkgs.graylog.overrideAttrs (final: prev: {
    inherit version;
    src = fetchurl {
      url = "https://packages.graylog2.org/releases/graylog/graylog-${version}.tgz";
      sha256 = "sha256-9uC6ZytK1uw9U+/2FkHF+0GhhLvZ4U/DAB0Wbe9fOiQ=";
    };
    makeWrapperArgs = [ 
      "--set-default" "JAVA_HOME" "${openjdk17_headless}"
      "--set" "PATH" "${lib.makeBinPath [
        coreutils
        udev
        util-linux
      ]}"
      "--set" "LD_LIBRARY_PATH" "${lib.makeLibraryPath [
        udev
      ]}"
    ];
    installPhase = ''
      mkdir -p $out
      cp -r {graylog.jar,bin,plugin} $out
      wrapProgram $out/bin/graylogctl $makeWrapperArgs
    '';
  });
in
graylog