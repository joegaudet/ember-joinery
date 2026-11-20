import { module, test } from 'qunit'

/**
 * Each core component's page offers both ways in: `pnpm add` and `npx ember-joinery add`, the
 * CLI that copies the source in (getting-started/copy.md). These hold the pages to the CLI's
 * manifest (packages/cli/registry, written by `pnpm build`): every core page has its copy
 * command, every command names components the CLI has, and add-on pages, which the CLI can't
 * copy yet, have none.
 */
const pages = import.meta.glob<string>('../../app/templates/**/*.md', {
  query: '?raw',
  import: 'default',
  eager: true,
})
const manifests = Object.values(
  import.meta.glob<{ items: Record<string, unknown> }>(
    '../../../packages/cli/registry/manifest.json',
    {
      import: 'default',
      eager: true,
    },
  ),
)

/** Packages of their own, which `ember-joinery add` doesn't copy from. */
const ADD_ON = /@ember-joinery\/(?!ember\b|primitives\b|test-support\b)[a-z-]+/

const installation = (source: string): string =>
  source.match(/^## Installation\n([\s\S]*?)(?=^## )/m)?.[1] ?? ''

/** Whether a page's install command adds an add-on (its prose may mention one, as Trace's does). */
const installsAddOn = (install: string): boolean =>
  (install.match(/pnpm add [^\n]*/g) ?? []).some(command => ADD_ON.test(command))

const copyCommands = (source: string): string[][] =>
  [...source.matchAll(/npx ember-joinery add ([^\n`]+)/g)].map(match =>
    // Flags, file names (`--diff dialog.gts`) and placeholders (`[components...]`) aren't names.
    match[1]!.split(/\s+/).filter(arg => /^[a-z][a-z-]*$/.test(arg)),
  )

module('Unit | copy commands', function () {
  test('the CLI’s manifest is built', function (assert) {
    assert.strictEqual(manifests.length, 1, 'run `pnpm build` to write packages/cli/registry')
  })

  test('every core component page has its copy command', function (assert) {
    let checked = 0
    for (const [path, source] of Object.entries(pages)) {
      if (!path.includes('/templates/components/')) continue
      const install = installation(source)
      if (!install.includes('pnpm add @ember-joinery/ember') || installsAddOn(install)) continue
      checked++
      assert.true(install.includes('npx ember-joinery add '), `${path} has no copy command`)
    }
    assert.true(checked > 50, `checked ${checked} pages`)
  })

  test('add-on pages have no copy command', function (assert) {
    for (const [path, source] of Object.entries(pages)) {
      if (!installsAddOn(installation(source))) continue
      assert.deepEqual(copyCommands(installation(source)), [], path)
    }
  })

  test('every copy command names components the CLI has', function (assert) {
    const items = manifests[0]?.items ?? {}
    for (const [path, source] of Object.entries(pages)) {
      for (const names of copyCommands(source)) {
        for (const name of names) assert.true(name in items, `${path}: ${name}`)
      }
    }
  })
})
