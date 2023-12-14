with import <nixpkgs>
{
  config.android_sdk.accept_license = true;
  overlays = [ ];
};
let
  gitGetURIs = [
    # bridges
    "beeper/dummybridge"
    "beeper/groupme"
    "beeper/linkedin"
    "beeper/signalgo"
    "mautrix/discord"
    "mautrix/facebook"
    "mautrix/go"
    "mautrix/googlechat"
    "mautrix/imessage"
    "mautrix/instagram"
    "mautrix/python"
    "mautrix/signal"
    "mautrix/slack"
    "mautrix/telegram"
    "mautrix/twitter"
    "mautrix/whatsapp"

    # supporting projects
    "tulir/whatsmeow"
    "git@gitlab.com:beeper/signald.git"
    "beeper/linkedin-messaging-api"

    # servers
    "beeper/hungryserv"
    "beeper/matrix-media-repo"
    "beeper/mautrix-asmux"
    "beeper/rageshake"
    "beeper/roomserv"
    "beeper/synapse"
    "beeper/yeetserv"

    # bots
    "beeper/chatwoot"
    "beeper/linear-maubot"
    "beeper/matrix-vacation-responder"
    "smweber/donutbot"
    "sumnerevans/github"

    # infra
    "beeper/beeper-services"
    "beeper/etl"
    "beeper/stack"

    # matrix test suites
    "beeper/complement"
    "matrix-org/sytest"

    # clients
    "beeper/beeper-desktop"

    # ci
    "beeper/bridge-cd-tool"
    "beeper/docker-retag-push-latest"
    "beeper/litestream"
    "git@gitlab.com:beeper/external-custom-ci.git"

    # matrix-spec
    "matrix-org/matrix-spec-proposals"
  ];

  git-get = pkgs.callPackage ./pkgs/git-get.nix { };

  initGitPkgs = pkgs.writeShellScriptBin "initgit" ''
    echo
    echo Cloning necessary repos
    echo
    ${lib.concatStringsSep "\n" (map (r: "${git-get}/bin/git-get ${r}") gitGetURIs)}
    echo
  '';

  # Aliases
  aliases = {
    k = "kubectl";

    kb = "kustomize build --enable-alpha-plugins";

    kl = "k --kubeconfig kubeconfig.yaml";
    k9sl = "k9s --kubeconfig kubeconfig.yaml";

    klh = "kubectl --kubeconfig kubeconfig-hetzner.yaml";
    k9slh = "k9s --kubeconfig kubeconfig-hetzner.yaml";
  };
  aliasPackage = name: val: writeShellScriptBin name "${val} $@";

  daynotes = pkgs.writeShellScriptBin "daynotes" ''
    vim $DAYNOTES_ROOT/$(date +%Y-%m-%d).todo.md
  '';
in
mkShell {
  name = "impurePythonEnv";
  venvDir = "./.venv";

  RIPGREP_CONFIG_PATH = pkgs.writeText "ripgreprc" (lib.concatStringsSep "\n" [
    "--hidden"
    "--search-zip"
    "--smart-case"
  ]);
  GIT_CONFIG_GLOBAL = ./.gitconfig;

  LD_LIBRARY_PATH = [
    "${file}/lib"
  ];

  buildInputs = [
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

    # Other packages
    appimage-run
    ffmpeg
    libheif

    # Local dev env
    k9s
    kubectl
    kustomize
    minikube
    mkcert
    skaffold

    # Utility scripts
    initGitPkgs

    # Deno
    deno

    # Rust
    rustup

    # JS
    yarn

    # Java
    androidenv.androidPkgs_9_0.androidsdk
    glibc
    clang-tools
    gradle
    jdk11
    visualvm

    # Golang
    go_1_21
    # go-tools
    gopls
    gotools
    olm

    # Node
    nodejs

    # Synapse Docs
    mdbook
    matrix-synapse

    # Utilities
    clash
    daynotes
    ngrok
    pre-commit
    protobuf
    protoc-gen-go
    rlwrap
    rnix-lsp
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
}
