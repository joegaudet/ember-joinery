# ember-joinery

## 1.0.0

### Major Changes

- ca6e3e3: `ember-joinery`, the CLI, copies a component's source into your app, as shadcn's `add` does: `npx
ember-joinery add dialog` writes `dialog.gts`, and the Button and Icon it uses, into
  `app/joinery/`, and installs the npm packages the copies need. It takes shadcn's options (`--yes`,
  `--overwrite`, `--cwd`, `--all`, `--path`, `--silent`, `--dry-run`, `--diff`, `--view`), and
  updating is `add` again: `--diff` compares your copy with the new version, and a copy you haven't
  touched is updated, while one you've edited is never overwritten without asking. `joinery.json`
  keeps where the copies go and a hash of each file written. The copies keep Joinery's CSS and their
  harnesses.
