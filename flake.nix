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

          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
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
          GIT_CONFIG_GLOBAL = ./.gitconfig;

          buildInputs = with pkgs;
            [
              # Python
              pkg-config
              python310
              python310Packages.boto3
              python310Packages.bottle
              python310Packages.click
              python310Packages.pillow
              python310Packages.psycopg2
              python310Packages.PyICU
              python310Packages.python-magic
              python310Packages.python-olm
              python310Packages.pyyaml
              python310Packages.requests
              python310Packages.sh
              python310Packages.venvShellHook
              python310Packages.virtualenv

              # Bridge dependencies
              ffmpeg
              libheif

              # Kubernetes + local stack
              k9s
              kubectl
              kustomize
              minikube
              mkcert
              skaffold

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
