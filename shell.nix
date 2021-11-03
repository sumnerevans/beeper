with import <nixpkgs> { };
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

    signal = {
      android = "git@github.com:signalapp/Signal-Android.git";
    };

    beeper-desktop = "git@gitlab.com:beeper/beeper-desktop.git";
    beeper-services = "git@gitlab.com:beeper/beeper-services.git";
    chatwoot = "git@gitlab.com:beeper/chatwoot.git";
    issues = "git@gitlab.com:beeper/issues.git";
    libsignal-client = "git@gitlab.com:beeper/libsignal-client.git";
    libsignal-service-java = "git@gitlab.com:beeper/libsignal-service-java.git";
    linkedin-matrix = "git@gitlab.com:beeper/linkedin.git";
    linkedin-messaging-api = "git@github.com:sumnerevans/linkedin-messaging-api.git";
    matrix-react-sdk = "git@github.com:matrix-org/matrix-react-sdk.git";
    matrix-vacation-responder = "git@gitlab.com:beeper/matrix-vacation-responder.git";
    mx-puppet-monorepo = "git@gitlab.com:beeper/mx-puppet-monorepo.git";
    okhttp = "git@github.com:square/okhttp.git";
    signald = "git@gitlab.com:beeper/signald.git";
    stack = "git@gitlab.com:beeper/stack.git";
    standupbot = "git@gitlab.com:beeper/standupbot.git";
    synapse = "git@gitlab.com:beeper/synapse.git";
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

    if [[ -f ${PROJECT_ROOT}/notes/days/$(date +%Y-%m-%d.md) ]]; then
      echo
      echo "$(tput bold)TODAY'S NOTES$(tput sgr0)"
      echo "$(tput bold)=============$(tput sgr0)"
      echo
      cat ${PROJECT_ROOT}/notes/days/$(date +%Y-%m-%d.md)
      echo
    fi
  '';

  daynotes = pkgs.writeShellScriptBin "daynotes" ''
    vim ${PROJECT_ROOT}/notes/days/$(date +%Y-%m-%d.md)
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
    black
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

    # K8S
    k9s
    kube3d
    kubectl
    kustomize
    kustomize-sops
    skaffold
    sops
    terraform

    # Utility scripts
    initGitPkgs

    # Rust
    rustup

    # JS
    yarn

    # Java
    visualvm

    # Golang
    go
    gopls

    # Synapse
    matrix-synapse

    # Synapse Docs
    mdbook

    # Utilities
    daynotes
    ngrok
    rnix-lsp
    yq
  ] ++ (lib.mapAttrsToList aliasPackage aliases);

  # Run this command, only after creating the virtual environment
  postVenvCreation = ''
    unset SOURCE_DATE_EPOCH

    pip install -r requirements.txt
  '';

  POST_CD_COMMAND = "${listNotes}/bin/list-notes";

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
