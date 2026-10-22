# Hyperline for NixOS.
#
# The Hyperline desktop is one executable that updates itself in place, so it
# lives in the player's data directory rather than the read-only store. This
# package is its launcher: it installs a downloaded release there and runs it
# inside Steam's own FHS environment, the one Steam runs Deadlock and Proton
# in, with the libraries the desktop's window needs added.
{
  lib,
  steam,
  writeShellScript,
  writeShellScriptBin,
  makeDesktopItem,
  symlinkJoin,
  gnutar,
  gzip,
  coreutils,
  xdg-utils,
}:

let
  # environment is Steam's FHS environment plus the desktop's window and
  # graphics libraries.
  environment =
    (steam.override {
      extraLibraries =
        pkgs: with pkgs; [
          libGL
          libxkbcommon
          vulkan-loader
          wayland
          # nixpkgs renamed these from xorg; older releases have only those.
          (pkgs.libx11 or xorg.libX11)
          (pkgs.libxcursor or xorg.libXcursor)
          (pkgs.libxfixes or xorg.libXfixes)
        ];
    }).run;

  # launch runs inside the environment: it installs a release given with
  # "install", and otherwise starts the installed desktop.
  launch = writeShellScript "hyperline-launch" ''
    set -eu
    export PATH=${
      lib.makeBinPath [
        coreutils
        gnutar
        gzip
        xdg-utils
      ]
    }:$PATH
    data=''${XDG_DATA_HOME:-$HOME/.local/share}/hyperline
    desktop=$data/hyperline

    # Install the executable from a release archive, replacing any earlier
    # one by rename so a running copy keeps its file.
    if [ "''${1:-}" = install ]; then
      archive=''${2:?Give the path of hyperline-linux-amd64.tar.gz}
      unpacked=$(mktemp -d)
      trap 'rm -rf "$unpacked"' EXIT
      tar -xzf "$archive" -C "$unpacked" hyperline
      mkdir -p "$data"
      install -m 755 "$unpacked/hyperline" "$desktop.next"
      mv "$desktop.next" "$desktop"
      echo "Hyperline is installed. Open it from your application menu and sign in."
      exit 0
    fi

    # Without an installed desktop, send the player to the download.
    if [ ! -x "$desktop" ]; then
      echo "Hyperline is not installed yet. Download the Linux package from"
      echo "https://hyperline.gg/setup, then run: hyperline install <path to the .tar.gz>"
      xdg-open https://hyperline.gg/setup >/dev/null 2>&1 || true
      exit 1
    fi
    exec "$desktop" "$@"
  '';

  # bin starts the launcher inside the environment.
  bin = writeShellScriptBin "hyperline" ''
    exec ${environment}/bin/steam-run ${launch} "$@"
  '';

  # desktopItem puts Hyperline in the application menu.
  desktopItem = makeDesktopItem {
    name = "hyperline";
    desktopName = "Hyperline";
    comment = "Play custom Deadlock games with friends";
    exec = "hyperline";
    icon = "applications-games";
    categories = [ "Game" ];
  };
in
symlinkJoin {
  name = "hyperline";
  paths = [
    bin
    desktopItem
  ];
  meta = {
    description = "Custom games for Deadlock, played together";
    homepage = "https://hyperline.gg";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "hyperline";
  };
}
