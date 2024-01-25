{
  description = "Beeper development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, android-nixpkgs }:
    (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;

          overlays = [
            (final: prev: {
              matrix-synapse-unwrapped =
                prev.matrix-synapse-unwrapped.overrideAttrs (old: rec {
                  pname = "matrix-synapse";
                  version = "unstable-2024-01-18";

                  src = prev.fetchFromGitHub {
                    owner = "beeper";
                    repo = "synapse";
                    rev = "82161750dd0b361ebe87245a396dfdc45da54a83";
                    hash =
                      "sha256-bW7gvQN2t+kMEP8NwvsHaW/xwwMrxwdwP2I/JduHCFA=";
                  };

                  cargoDeps = prev.rustPlatform.fetchCargoTarball {
                    inherit src;
                    name = "${pname}-${version}";
                    hash =
                      "sha256-BJlhi+pEhp2Io/nabxDJJuvvYtlWbn7odmWllS9/heo=";
                  };

                  propagatedBuildInputs =
                    prev.matrix-synapse-unwrapped.propagatedBuildInputs
                    ++ (with prev.python3.pkgs; [ hiredis txredisapi ]);

                  doInstallCheck = false;
                  doCheck = false;
                });
            })
          ];
        };
        lib = pkgs.lib;

        # Aliases
        aliases = {
          k = "kubectl";

          kb = "kustomize build --enable-alpha-plugins";

          kl = "k --kubeconfig kubeconfig.yaml";
          k9sl = "k9s --kubeconfig kubeconfig.yaml";

          klh = "kubectl --kubeconfig kubeconfig-hetzner.yaml";
          k9slh = "k9s --kubeconfig kubeconfig-hetzner.yaml";
        };
        aliasPackage = name: val: pkgs.writeShellScriptBin name "${val} $@";

        # Android
        android_sdk = ((pkgs.callPackage android-nixpkgs { }).sdk (sdkPkgs:
          with sdkPkgs; [
            build-tools-34-0-0
            cmdline-tools-latest
            emulator
            ndk-26-1-10909125
            platform-tools
            platforms-android-26
            platforms-android-34
          ]));

        daynotes = pkgs.writeShellScriptBin "daynotes" ''
          vim $DAYNOTES_ROOT/$(date +%Y-%m-%d).todo.md
        '';
      in {
        devShells.default = pkgs.mkShell {
          name = "impurePythonEnv";
          venvDir = "./.venv";

          RIPGREP_CONFIG_PATH = pkgs.writeText "ripgreprc"
            (lib.concatStringsSep "\n" [
              "--hidden"
              "--search-zip"
              "--smart-case"
            ]);
          GIT_CONFIG_GLOBAL = pkgs.writeText "gitconfig" ''
            [include]
                path = ~/.config/git/config

            [user]
                email = sumner@beeper.com
          '';
          ANDROID_HOME = "${android_sdk}/share/android-sdk";

          buildInputs = with pkgs;
            [
              # Python
              pkg-config
              python3
              python3Packages.boto3
              python3Packages.bottle
              python3Packages.click
              python3Packages.gevent
              python3Packages.pillow
              python3Packages.psycopg2
              python3Packages.PyICU
              python3Packages.python-magic
              python3Packages.python-olm
              python3Packages.pyyaml
              python3Packages.requests
              python3Packages.sh
              python3Packages.urllib3

              python3Packages.venvShellHook
              python3Packages.virtualenv

              # Synapse
              matrix-synapse

              # Bridge dependencies
              ffmpeg
              libheif

              # Kubernetes + local stack
              gcc
              k9s
              kubectl
              kustomize
              libffi
              minikube
              mkcert
              skaffold
              stdenv.cc.cc.lib

              # Android
              android_sdk

              # Deno
              deno

              # Golang
              go_1_21
              gopls
              gotools
              olm

              # JS
              yarn

              # Kotlin
              gradle
              kotlin

              # Node
              nodejs

              # Rust
              rustup

              # Synapse Docs
              mdbook
              matrix-synapse

              # Utilities
              daynotes
              mitmproxy
              ngrok
              pre-commit
              protobuf
              protoc-gen-go
              rlwrap
              yq-go

              # Databases
              litestream
              litecli
              pgcli
              sqlite
              sqldiff

              # Commit hooks
              pre-commit
            ] ++ (lib.mapAttrsToList aliasPackage aliases);

          # Run this command, only after creating the virtual environment
          postVenvCreation = ''
            unset SOURCE_DATE_EPOCH
          '';
        };
      }));
}
