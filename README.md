# Hyperline for NixOS

[Hyperline](https://hyperline.gg) runs custom games for Deadlock, played
together. This flake installs it on NixOS.

Hyperline plays Deadlock through Steam and Proton. On NixOS, Steam runs games
inside an FHS environment that has the usual Linux layout, and a Hyperline
started outside it cannot start Proton to host a game. This package runs
Hyperline inside that same environment, with the libraries its window needs, so
it works without `nix-ld` or `steam-run`.

## Install

Enable Steam and Hyperline in your system flake:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hyperline.url = "github:paralin/hyperline-nix";
    hyperline.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, hyperline, ... }: {
    nixosConfigurations.my-pc = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        hyperline.nixosModules.default
        {
          nixpkgs.config.allowUnfree = true;
          programs.steam.enable = true;
          programs.hyperline.enable = true;
        }
      ];
    };
  };
}
```

Rebuild, then download the Linux package from
[hyperline.gg/setup](https://hyperline.gg/setup) and install it:

```sh
hyperline install ~/Downloads/hyperline-linux-amd64.tar.gz
```

Open Hyperline from your application menu and sign in. Hyperline updates itself
from then on.

To try it without changing your system configuration:

```sh
nix run github:paralin/hyperline-nix -- install ~/Downloads/hyperline-linux-amd64.tar.gz
nix run github:paralin/hyperline-nix
```

Steam must be installed and signed in, and Deadlock launched through Steam at
least once, so Proton has prepared the game.

## How it works

The Hyperline desktop is one executable that replaces itself when it updates,
so it cannot live in the read-only Nix store. `hyperline install` puts it in
`$XDG_DATA_HOME/hyperline` (by default `~/.local/share/hyperline`), where the
updater can replace it, and `hyperline` starts it inside Steam's FHS
environment. Without an installed desktop, `hyperline` opens the download page.

The flake provides:

| Output | Contents |
| --- | --- |
| `packages.x86_64-linux.default` | The `hyperline` launcher and its application menu entry |
| `nixosModules.default` | `programs.hyperline.enable` and `programs.hyperline.package` |
| `overlays.default` | `pkgs.hyperline` |

## Uninstall

Disable `programs.hyperline`, then remove the installed desktop and its data:

```sh
rm -rf ~/.local/share/hyperline
```

## License

The Nix expressions here are MIT licensed; see [LICENSE](LICENSE). Hyperline
itself is proprietary.
