with import <nixpkgs>
{
  config.android_sdk.accept_license = true;
  overlays = [ ];
};
let
  PROJECT_ROOT = builtins.getEnv "PWD";

  # CoC Config
  cocConfig = writeText "coc-settings.json" (
    builtins.toJSON {
      "python.formatting.provider" = "black";
      "python.linting.enabled" = true;
      "python.linting.flake8Enabled" = true;
      "python.linting.mypyEnabled" = true;
      "python.linting.pylintEnabled" = false;
      "python.pythonPath" = "/home/sumner/projects/beeper/.venv/bin/python";
    }
  );

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
    vim ${PROJECT_ROOT}/notes/days/$(date +%Y-%m-%d).todo.md
  '';
in
mkShell rec {
  name = "impurePythonEnv";
  venvDir = "./.venv";

  RIPGREP_CONFIG_PATH = pkgs.writeText "ripgreprc" (lib.concatStringsSep "\n" [
    "--hidden"
    "--search-zip"
    "--smart-case"
  ]);
  GIT_CONFIG_GLOBAL = ./.gitconfig;
  GITGET_ROOT = PROJECT_ROOT;

  LD_LIBRARY_PATH = [
    "${file}/lib"
  ];

  buildInputs = [
    # Python
    python310
    python310Packages.boto3
    python310Packages.bottle
    python310Packages.click
    python310Packages.pillow
    python310Packages.psycopg2
    python310Packages.python-olm
    python310Packages.python-magic
    python310Packages.pyyaml
    python310Packages.requests
    python310Packages.sh
    python310Packages.venvShellHook
    python310Packages.virtualenv

    # Other packages
    appimage-run
    ffmpeg

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
    go_1_20
    # go-tools
    gopls
    gotools
    olm

    # Node
    nodejs-16_x

    # Synapse Docs
    mdbook
    matrix-synapse

    # Utilities
    daynotes
    ngrok
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

  # Now we can execute any commands within the virtual environment.
  # This is optional and can be left out to run pip manually.
  postShellHook = ''
    # allow pip to install wheels
    unset SOURCE_DATE_EPOCH

    mkdir -p .vim
    ln -sf ${cocConfig} ${PROJECT_ROOT}/.vim/coc-settings.json
  '';
}
