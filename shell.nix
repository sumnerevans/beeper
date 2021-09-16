with import <nixpkgs> {};
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
    mautrix = {
      facebook = "git@github.com:mautrix/facebook.git";
      go = "git@github.com:mautrix/go.git";
      hangouts = "git@github.com:mautrix/hangouts.git";
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
    issues = "git@gitlab.com:beeper/issues.git";
    libsignal-client = "git@github.com:signalapp/libsignal-client.git";
    libsignal-service-java = "git@gitlab.com:beeper/libsignal-service-java.git";
    linkedin-matrix = "git@github.com:sumnerevans/linkedin-matrix.git";
    linkedin-messaging-api = "git@github.com:sumnerevans/linkedin-messaging-api.git";
    okhttp = "git@github.com:square/okhttp.git";
    signald = "git@gitlab.com:beeper/signald.git";
    stack = "git@gitlab.com:beeper/stack.git";
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

  initGitPkgs = pkgs.writeShellScriptBin "initgit" ''
    echo
    echo Cloning necessary repos
    echo
    ${lib.concatStringsSep "\n" (lib.flatten (recurseProjectUris "." projectUris))}
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
in
mkShell rec {
  name = "impurePythonEnv";
  venvDir = "./.venv";

  RIPGREP_CONFIG_PATH = ./.ripgreprc;

  buildInputs = [
    # Python
    python3
    python3Packages.venvShellHook
    python3Packages.psycopg2
    python3Packages.python-olm
    python3Packages.python_magic
    python3Packages.click
    python3Packages.pyyaml
    python3Packages.requests
    python3Packages.sh

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

    # Golang
    go
    gopls

    # Utilities
    ngrok
    rnix-lsp
    yq-go
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
    ln -sf ${cocConfig} .vim/coc-settings.json
  '';
}
