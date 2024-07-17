{
  description = "Beeper development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
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
                  version = "unstable-2024-06-04";

                  src = prev.fetchFromGitHub {
                    owner = "beeper";
                    repo = "synapse";
                    rev = "cc5d647f79c2d351eb1a1c61b323a6797b4e3c0b";
                    hash =
                      "sha256-94O6Y8JN+eJX2IlKzfhKgDCCLJbQMkmJ6exXfvdu7nA=";
                  };

                  cargoDeps = prev.rustPlatform.fetchCargoTarball {
                    inherit src;
                    name = "${pname}-${version}";
                    hash =
                      "sha256-fi052nUPba/lGuhxE/rhKWaNLNvDyTMtrMOmyWi0y8I=";
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

          RAGESHAKE_PASSWORD = lib.removeSuffix "\n"
            (builtins.readFile ./secrets/rageshake-password);

          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

          buildInputs = with pkgs;
            [
              # Libraries
              olm

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
              ffmpeg-full
              libheif
              rlottie
              lottieconverter

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

              # Deno
              deno

              # Golang
              go-tools
              go
              gotools

              # JS
              yarn

              # Kotlin
              gradle
              kotlin

              # Node
              nodejs

              # Rust
              clang
              cmake
              gnumake
              protobuf
              rust-cbindgen
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
