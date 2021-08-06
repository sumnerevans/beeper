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
      hangouts = "git@github.com:mautrix/hangouts.git";
      instagram = "git@github.com:mautrix/instagram.git";
      python = "git@github.com:mautrix/python.git";
      signal = "git@github.com:mautrix/signal.git";
      telegram = "git@github.com:mautrix/telegram.git";
      twitter = "git@github.com:mautrix/twitter.git";
    };

    linkedin-matrix = "git@github.com:sumnerevans/linkedin-matrix.git";
    linkedin-messaging-api = "git@github.com:sumnerevans/linkedin-messaging-api.git";
    beeper-desktop = "git@gitlab.com:beeper/beeper-desktop.git";
    beeper-services = "git@gitlab.com:beeper/beeper-services.git";
    issues = "git@gitlab.com:beeper/issues.git";
    libsignal-service-java = "git@gitlab.com:beeper/libsignal-service-java.git";
    signald = "git@gitlab.com:beeper/signald.git";
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
in
mkShell rec {
  name = "impurePythonEnv";
  venvDir = "./.venv";

  buildInputs = [
    python3
    python3Packages.venvShellHook

    # Python Dependencies
    python3Packages.psycopg2
    python3Packages.python-olm
    python3Packages.python_magic

    # Utility scripts
    initGitPkgs

    # Utilities
    ngrok

    rnix-lsp
  ];

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
