# ember-joinery

Copy [Joinery](https://joegaudet.com/ember-joinery/)'s components into your Ember app, and
update them: shadcn/ui's `add`, for Ember.

```bash
npx ember-joinery add dialog
```

That writes the Dialog's source into `app/joinery/`, with the Button and Icon it uses, and
installs the npm packages the copies import (`@ember-joinery/primitives`, `lucide`). The copies
are yours to change. They keep Joinery's CSS and their `data-test-jn-*` attributes, so
`@ember-joinery/test-support`'s harnesses still drive them.

The copies are TypeScript (`.gts`): your app needs TypeScript and
`@babel/plugin-transform-typescript`.

## Commands

```bash
ember-joinery add [components...] [options]
ember-joinery list
```

| Option          | Short | What it does                                                                |
| --------------- | ----- | --------------------------------------------------------------------------- |
| `--yes`         | `-y`  | Skip the confirmation prompt; files you've changed are kept                 |
| `--overwrite`   | `-o`  | Overwrite existing files                                                    |
| `--cwd <cwd>`   | `-c`  | Your app's folder (default: the current folder)                             |
| `--all`         | `-a`  | Add every component                                                         |
| `--path <path>` | `-p`  | Where the copies go (default: `joinery.json`'s path, or `app/joinery`)      |
| `--silent`      | `-s`  | Mute output                                                                 |
| `--dry-run`     |       | Show what would change, and write nothing                                   |
| `--diff [path]` |       | Show diffs: the first five changed files, or the one named. Writes nothing  |
| `--view [path]` |       | Show this version's files: the first five, or the one named. Writes nothing |

The first `add` writes `joinery.json`, holding the copies' path, and later runs read it.

## Updating

Run `add` again with the version you want. It never overwrites a file you've changed without
asking:

```bash
npx ember-joinery@latest add dialog --dry-run           # which files would change
npx ember-joinery@latest add dialog --diff dialog.gts   # what changed in one
npx ember-joinery@latest add dialog --overwrite         # take the new version
```

The guide's [Copy components](https://joegaudet.com/ember-joinery/guide/getting-started/copy.md)
page has the details.
