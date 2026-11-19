# Copy components

Copy a component's source into your app, to change it as your own.

Most apps install Joinery from npm (see [Installation](/getting-started/installation.md)) and
get every fix with an update. When you need to change a component's markup or behaviour, not
just its look, copy it in instead, as shadcn/ui does: `npx ember-joinery add` writes the
component's source into your app, where it is yours to edit. Its look still comes from
Joinery's CSS, and its harness still tests it.

<div class="callout">

**Not on npm yet.** The `ember-joinery` CLI publishes with Joinery's first release.

</div>

## Add a component

```bash
npx ember-joinery add dialog
```

```text
Created app/joinery/components/dialog.gts
Created app/joinery/components/button.gts
Created app/joinery/components/icon.gts

Installing @ember-joinery/primitives@^1.0.0 lucide@^0.474.0 with pnpm…
```

It copies the component and every component it uses (Dialog uses Button and Icon), with the
folder layout the package has, so their imports of each other work unchanged.
Then it installs the npm packages the copies import that your app doesn't have yet, with the
package manager your lockfile names. Name as many components as you like, or pass `--all`.
`npx ember-joinery list` prints them all.

Import a copy from your app by its path:

```gts
import Dialog from 'my-app/joinery/components/dialog.gts'
import Button from 'my-app/joinery/components/button.gts'

<template>
  <Dialog @name="edit-profile" as |d|>
    <Button @variant="outline" {{d.trigger}}>Edit profile</Button>
    <d.Content>…</d.Content>
  </Dialog>
</template>
```

The copies are TypeScript (`.gts`), as Joinery's source is, so your app needs TypeScript and
`@babel/plugin-transform-typescript` in its Babel config; the CLI says so when your
`package.json` doesn't list `typescript`. Copies are tested in a Vite (Embroider) app with
TypeScript, as Joinery's own test app is.

## What still comes from npm

A copy is the component's own layer. What it's built on stays in packages:

- **Behaviour**: `@ember-joinery/primitives`, the headless layer (focus, dismissing, the top
  layer, keyboard handling). shadcn's copies keep Radix as a dependency the same way.
- **Icons**: `lucide`.
- **Styles**: Joinery's CSS. A copy renders the same `jn-*` classes, so keep the
  `tokens.css` and `joinery.css` imports from [Installation](/getting-started/installation.md);
  [Theming](/getting-started/theming.md) and [Styles](/getting-started/styles.md) apply to
  copies too. To restyle one component, add a class or edit its markup.
- **Tests**: `@ember-joinery/test-support`. A copy keeps its `data-test-jn-*` attributes, so
  its harness drives it unchanged (see [Testing](/getting-started/testing.md)):

```gts
import { DialogHarness } from '@ember-joinery/test-support'
import Dialog from 'my-app/joinery/components/dialog.gts'

test('it opens', async function (assert) {
  await render(
    <template>
      <Dialog @name="edit-profile" as |d|>…</Dialog>
    </template>,
  )
  const dialog = new DialogHarness('edit-profile')
  await dialog.open()
  assert.true(dialog.isOpen)
})
```

## joinery.json

The first `add` writes `joinery.json` at your app's root, holding where the copies go:

```json
{
  "path": "app/joinery"
}
```

Later runs read it, so an update lands where the first copy did. Put the copies somewhere else
with `--path` on the first run (`npx ember-joinery add dialog --path app/ui`), or edit the file.

## Update a component

Your copies don't change when Joinery does: you update one by running `add` again, as with
shadcn. It never overwrites a file you've changed without asking, so look first:

1. See which files would change:

   ```bash
   npx ember-joinery add dialog --dry-run
   ```

   Each file is listed as `create`, `overwrite` (yours differs from this version's) or
   `unchanged`, with the npm packages it would install. Run it with the version you want:
   `npx ember-joinery@latest add dialog --dry-run`. An update that needs newer primitives
   installs them.

2. Compare a changed file with this version's:

   ```bash
   npx ember-joinery add dialog --diff dialog.gts
   ```

   Without a file name, `--diff` shows the first five changed files.

3. Take the new version, or merge it by hand. To replace your files with this version's:

   ```bash
   npx ember-joinery add dialog --overwrite
   ```

   Without `--overwrite`, `add` asks before replacing each file you've changed. With `--yes`,
   or in CI where there's no terminal to ask in, it keeps yours and lists them.

## Options

```bash
npx ember-joinery add [components...] [options]
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

They are shadcn's `add` options, with the same names and short forms.

## What can't be copied yet

- **Add-on packages**: Carousel, Chart, Code Block, Data Table, File Upload, the Rich Text
  Editor, Power Calendar and the masked inputs. Install them from npm; each page says so.
- **Primitives**: `@ember-joinery/primitives` stays a package that copies depend on.
- **Blocks**: copy a block from its page in the guide, with the example's Copy button.
