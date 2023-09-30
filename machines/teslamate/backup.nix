{ stdenv
, lib
, pkgs
, writeShellScript 
, ...
}:
let
  backup = writeShellScript "teslamate-backup" ''
    : ''${1?' Please specify a file to save backup'}
    podman exec database pg_dump -U teslamate teslamate > "$1"
  '';
  restore = writeShellScript "teslamate-backup" ''
    : ''${1?' Please specify a file to restore from'}

    # Stop the teslamate container to avoid write conflicts
    systemctl stop podman-teslamate.service

    # Drop existing data and reinitialize
    podman exec -i database psql -U teslamate << .
      drop schema public cascade;
      create schema public;
      create extension cube;
      create extension earthdistance;
      CREATE OR REPLACE FUNCTION public.ll_to_earth(float8, float8)
          RETURNS public.earth
          LANGUAGE SQL
          IMMUTABLE STRICT
          PARALLEL SAFE
          AS 'SELECT public.cube(public.cube(public.cube(public.earth()*cos(radians(\$1))*cos(radians(\$2))),public.earth()*cos(radians(\$1))*sin(radians(\$2))),public.earth()*sin(radians(\$1)))::public.earth';
    .

    # Restore
    podman exec -i database psql -U teslamate -d teslamate < "$1"

    # Restart the teslamate container
    systemctl start podman-teslamate.service
  '';
in
stdenv.mkDerivation {
  pname = "teslamate-backup";
  version = "0.1.0";
  src = ./.;

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    ln -s ${backup} $out/bin/teslamate-backup
    ln -s ${restore} $out/bin/teslamate-restore
  '';
}