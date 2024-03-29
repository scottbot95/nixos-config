{ lib, fetchFromGitHub, python3, ... }:

python3.pkgs.buildPythonPackage rec {
  pname = "open-fprintd";
  version = "0.6";

  src = fetchFromGitHub {
    owner = "uunicorn";
    repo = pname;
    rev = version;
    sha256 = "sha256-uVFuwtsmR/9epoqot3lJ/5v5OuJjuRjL7FJF7oXNDzU=";
  };

  checkInputs = with python3.pkgs; [ dbus-python ];

  propagatedBuildInputs = with python3.pkgs; [ dbus-python pygobject3 ];

  postInstall = ''
    install -D -m 644 debian/open-fprintd.service \
      $out/lib/systemd/system/open-fprintd.service
    install -D -m 644 debian/open-fprintd-resume.service \
      $out/lib/systemd/system/open-fprintd-resume.service
    install -D -m 644 debian/open-fprintd-suspend.service \
      $out/lib/systemd/system/open-fprintd-suspend.service
    substituteInPlace $out/lib/systemd/system/open-fprintd.service \
      --replace /usr/lib/open-fprintd "$out/lib/open-fprintd"
    substituteInPlace $out/lib/systemd/system/open-fprintd-resume.service \
      --replace /usr/lib/open-fprintd "$out/lib/open-fprintd"
    substituteInPlace $out/lib/systemd/system/open-fprintd-suspend.service \
      --replace /usr/lib/open-fprintd "$out/lib/open-fprintd"
  '';

  postFixup = ''
    wrapPythonProgramsIn "$out/lib/open-fprintd" "$out $pythonPath"
  '';

  meta = with lib; {
    description =
      "Fprintd replacement which allows you to have your own backend as a standalone service";
    homepage = "https://github.com/uunicorn/open-fprintd";
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}
