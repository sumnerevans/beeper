with import <nixpkgs>
{
  overlays = [ ];
};
let
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

  projectUris = {
    maubot = {
      gitlab = "git@github.com:maubot/gitlab.git";
      linear = "git@gitlab.com:beeper/linear-maubot.git";
      maubot = "git@github.com:maubot/maubot.git";
    };

    mautrix = {
      asmux = "git@gitlab.com:beeper/mautrix-asmux.git";
      docs = "git@github.com:mautrix/docs.git";
      facebook = "git@github.com:mautrix/facebook.git";
      go = "git@github.com:mautrix/go.git";
      googlechat = "git@github.com:mautrix/googlechat.git";
      imessage = "git@github.com:mautrix/imessage.git";
      instagram = "git@github.com:mautrix/instagram.git";
      python = "git@github.com:mautrix/python.git";
      signal = "git@github.com:mautrix/signal.git";
      telegram = "git@github.com:mautrix/telegram.git";
      twitter = "git@github.com:mautrix/twitter.git";
      whatsapp = "git@github.com:mautrix/whatsapp.git";
    };

    beeper-desktop = "git@gitlab.com:beeper/beeper-desktop.git";
    beeper-services = "git@gitlab.com:beeper/beeper-services.git";
    chatwoot = "git@gitlab.com:beeper/chatwoot.git";
    donutbot = "git@github.com:smweber/donutbot.git";
    element-web = "git@github.com:vector-im/element-web.git";
    external-custom-ci = "git@gitlab.com:beeper/external-custom-ci.git";
    issues = "git@gitlab.com:beeper/issues.git";
    linkedin-matrix = "git@gitlab.com:beeper/linkedin.git";
    linkedin-messaging-api = "git@github.com:sumnerevans/linkedin-messaging-api.git";
    matrix-js-sdk = "https://github.com/matrix-org/matrix-js-sdk.git";
    matrix-react-sdk = "git@github.com:matrix-org/matrix-react-sdk.git";
    matrix-vacation-responder = "git@gitlab.com:beeper/matrix-vacation-responder.git";
    mx-puppet-monorepo = "git@gitlab.com:beeper/mx-puppet-monorepo.git";
    rageshake = "git@gitlab.com:beeper/rageshake.git";
    signald = "git@gitlab.com:signald/signald.git";
    stack = "git@gitlab.com:beeper/stack.git";
    standupbot = "git@gitlab.com:beeper/standupbot.git";
    synapse = "git@gitlab.com:beeper/synapse.git";
    whatsmeow = "git@github.com:tulir/whatsmeow.git";
    yeetserv = "git@gitlab.com:beeper/yeetserv.git";
  };

  cloneCmd = rootDir: key: uri: ''
    if [[ -d ${rootDir}/${key} ]]; then
      echo "${rootDir}/${key} already exists. Will not create."
    else
      mkdir -p ${rootDir}
      ${pkgs.git}/bin/git clone --recurse-submodules -j8 ${uri} ${rootDir}/${key}
    fi
  '';
  recurseProjectUris = rootDir: lib.mapAttrsToList (
    name: value:
      if builtins.isAttrs value
      then recurseProjectUris "${rootDir}/${name}" value
      else cloneCmd rootDir name value
  );

  PROJECT_ROOT = builtins.getEnv "PWD";

  initGitPkgs = pkgs.writeShellScriptBin "initgit" ''
    echo
    echo Cloning necessary repos
    echo
    ${lib.concatStringsSep "\n" (lib.flatten (recurseProjectUris PROJECT_ROOT projectUris))}
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

  listNotes = pkgs.writeShellScriptBin "list-notes" ''
    if [[ "$(pwd)" != "${PROJECT_ROOT}" ]]; then
      exit 0
    fi

    if [[ -f ${PROJECT_ROOT}/notes/days/$(date +%Y-%m-%d).todo.md ]]; then
      echo
      echo "$(tput bold)TODAY'S TODO$(tput sgr0)"
      echo "$(tput bold)=============$(tput sgr0)"
      echo
      cat ${PROJECT_ROOT}/notes/days/$(date +%Y-%m-%d).todo.md
      echo
    fi
  '';

  daynotes = pkgs.writeShellScriptBin "daynotes" ''
    vim ${PROJECT_ROOT}/notes/days/$(date +%Y-%m-%d).todo.md
  '';
in
mkShell rec {
  name = "impurePythonEnv";
  venvDir = "./.venv";

  RIPGREP_CONFIG_PATH = ./.ripgreprc;
  ASMUX_SHARED_SECRET = lib.removeSuffix "\n" (builtins.readFile ./secrets/asmux_shared_secret);

  buildInputs = [
    # Python
    python3
    python3Packages.bottle
    python3Packages.click
    python3Packages.psycopg2
    python3Packages.python-olm
    python3Packages.python_magic
    python3Packages.pyyaml
    python3Packages.requests
    python3Packages.sh
    python3Packages.venvShellHook
    python3Packages.virtualenv

    # Other packages
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

    # Rust
    rustup

    # JS
    yarn

    # Java
    clang-tools
    gradle
    jdk11
    visualvm

    # Golang
    go_1_17
    goimports
    gopls
    olm
    vgo2nix

    # Node
    nodejs-16_x

    # Synapse Docs
    mdbook

    # Utilities
    daynotes
    ngrok
    rnix-lsp
    yq

    # Commit hooks
    pre-commit
  ] ++ (lib.mapAttrsToList aliasPackage aliases);

  # Run this command, only after creating the virtual environment
  postVenvCreation = ''
    unset SOURCE_DATE_EPOCH
  '';

  POST_CD_COMMAND = pkgs.writeShellScript "list-notes" ''
    if [ -f .pre-commit-config.yaml ]; then
      pre-commit install --install-hooks
    fi
    ${listNotes}/bin/list-notes
  '';

  # Now we can execute any commands within the virtual environment.
  # This is optional and can be left out to run pip manually.
  postShellHook = ''
    # allow pip to install wheels
    unset SOURCE_DATE_EPOCH

    mkdir -p .vim
    ln -sf ${cocConfig} ${PROJECT_ROOT}/.vim/coc-settings.json

    # Add /bin to path
    export PATH="${PROJECT_ROOT}/bin:$PATH"
  '';
}
