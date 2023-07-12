local build(attr) = {
  kind: 'pipeline',
  type: 'exec',
  name: 'nix build %s' % attr,

  steps: [
    {
      name: 'build previous commit',
      commands: [
        'git checkout -q $DRONE_COMMIT_BEFORE',
        'nix build --print-build-logs --out-link ./$DRONE_COMMIT_BEFORE %s' % attr,
      ],
      failure: 'ignore',
      depends_on: [
        'build current commit',
      ],
    },
    {
      name: 'build current commit',
      commands: [
        'git config --global url."https://git.geklaute.cloud".insteadOf ssh://git@git.geklaute.cloud',
        'git checkout -q $DRONE_COMMIT',
        'nix build --print-build-logs --out-link ./$DRONE_COMMIT %s' % attr,
      ],
    },
    {
      name: 'diff closure',
      commands: [
        'nix store diff-closures ./$DRONE_COMMIT_BEFORE ./$DRONE_COMMIT',
      ],
      failure: 'ignore',
      depends_on: [
        'build previous commit',
        'build current commit',
      ],
    },
  ],
};

[
  build('.#nixosConfigurations.%s.config.system.build.toplevel' % conf)
  for conf in [
    'altra',
    'frameless',
    'futro',
    'netcup01',
    'ryzen',
  ]
]
