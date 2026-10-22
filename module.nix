# The NixOS module installs the Hyperline launcher. Hyperline hosts and joins
# games through Steam, so it needs programs.steam as well.
{ hyperline }:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.hyperline;
in
{
  options.programs.hyperline = {
    enable = lib.mkEnableOption "Hyperline, custom games for Deadlock";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage hyperline { };
      defaultText = lib.literalExpression "hyperline.packages.\${system}.default";
      description = "The Hyperline launcher to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.programs.steam.enable;
        message = "programs.hyperline needs programs.steam.enable = true, since Hyperline plays Deadlock through Steam.";
      }
    ];
    environment.systemPackages = [ cfg.package ];
  };
}
