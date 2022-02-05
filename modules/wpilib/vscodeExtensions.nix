{ pkgs, wpilib, ... }:
let
  utils = pkgs.vscode-utils;
  mkExtensionFromVsix = import ./mkVscodeExtensionFromVsix.nix { inherit pkgs; };
in
(with pkgs.vscode-extensions; [
  redhat.java
]) ++ utils.extensionsFromVscodeMarketplace [
  # FIXME This extension tries to store stuff in ${extensionPath}/cache
  #       which is actually is the /nix/store so is read-only
  # {
  #   name = "vscodeintellicode";
  #   publisher = "visualstudioexptteam";
  #   version = "1.2.16";
  #   sha256 = "rIzUyr5y+DxfXDxj23QbFo9TbWljl2GtsbzaaqJwGrk=";
  # }
  {
    name = "vscode-java-debug";
    publisher = "vscjava";
    version = "0.38.0";
    sha256 = "5QxKHa7fZH5MPkWrz5hCpP66VzICayxqE92jnPE7suQ=";
  }
  {
    name = "vscode-java-test";
    publisher = "vscjava";
    version = "0.34.0";
    sha256 = "7uscmiZNvwXZeDutsWmhkWe4IQ3VZx3Cna9xWM2wLhE=";
  }
  {
    name = "vscode-maven";
    publisher = "vscjava";
    version = "0.35.0";
    sha256 = "rJputnM6LtZ9+8H6Mjwh8OJSArSX2gSogtmLLoucffc=";
  }
  {
    name = "vscode-java-dependency";
    publisher = "vscjava";
    version = "0.19.0";
    sha256 = "TOxDcqyjybilIt4+H3An5i+YcrjbOOLulMy+LDu296Q=";
  }
]
++ [
  (mkExtensionFromVsix {
    name = "wpilib-vscode";
    version = "2022.2.1";
    vsix = "${wpilib}/2022/vsCodeExtensions/WPILib.vsix";
    vscodeExtUniqueId = "wpilibsuite.vscode-wpilib";
  })
]
