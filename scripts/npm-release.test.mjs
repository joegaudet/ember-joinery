// npm-release.mjs opens every npm login and 2FA link it sees in the release's output, and
// nothing else, whatever the terminal codes around it.
import { test } from 'node:test'
import assert from 'node:assert/strict'

import { npmAuthUrls } from './npm-release.mjs'

test('finds the 2FA link npm prints for a publish', () => {
  const out = 'Authenticate your account at:\r\nhttps://www.npmjs.com/auth/cli/3f1c-9a2b\r\n'
  assert.deepEqual(npmAuthUrls(out), ['https://www.npmjs.com/auth/cli/3f1c-9a2b'])
})

test('finds the link npm login prints', () => {
  const out = 'Login at:\nhttps://www.npmjs.com/login?next=/login/cli/7d0e-41aa\nPress ENTER'
  assert.deepEqual(npmAuthUrls(out), ['https://www.npmjs.com/login?next=/login/cli/7d0e-41aa'])
})

test('strips colour codes around and inside the line', () => {
  const out =
    '\x1b[1mAuthenticate:\x1b[22m\r\n\x1b[36mhttps://www.npmjs.com/auth/cli/ab-12\x1b[39m\r\n'
  assert.deepEqual(npmAuthUrls(out), ['https://www.npmjs.com/auth/cli/ab-12'])
})

test('ignores other npmjs.com links', () => {
  assert.deepEqual(npmAuthUrls('see https://www.npmjs.com/package/@ember-joinery/ember\n'), [])
})
