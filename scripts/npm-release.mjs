#!/usr/bin/env node
//
// Releases every package to npm in one go, from a terminal on your machine:
//
//   pnpm release:npm [release.sh options]
//
// It runs the oss-release skill's release.sh (version PR, tag, CI publish, a local publish of
// whatever CI could not publish, trusted publishers, the GitHub release) and does the npm
// website's part in a Chrome window it drives: every npm login or 2FA link the release prints
// opens there. Sign in to npmjs.com in that window the first time; the profile is kept, so after
// that each link only needs your 2FA approval. It never sees your password or codes.
//
// npm only offers its 2FA link when stdin and stdout are a terminal, so the release runs under
// `script`, which gives it one while this script reads what it prints. Safe to re-run: every
// step skips what is already done.
import { execFileSync, spawn } from 'node:child_process'
import { readFileSync, readdirSync } from 'node:fs'
import { homedir } from 'node:os'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { stripVTControlCharacters } from 'node:util'

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..')
const RELEASE_SH = join(homedir(), '.claude', 'skills', 'oss-release', 'release.sh')
const PROFILE = join(homedir(), '.cache', 'ember-joinery-npm-browser')
const ORG = 'ember-joinery'
const REPO = 'joegaudet/ember-joinery'
const WORKFLOW = 'release.yml'

const AUTH_URL = /https:\/\/www\.npmjs\.com\/(?:auth\/cli\/|login\?next=\/login\/cli\/)[\w-]+/g

/** The npm login and 2FA links in a chunk of terminal output. */
export const npmAuthUrls = text =>
  [...stripVTControlCharacters(text).matchAll(AUTH_URL)].map(m => m[0])

let browser
const open = async url => {
  browser ??= import('playwright-core').then(({ chromium }) =>
    chromium.launchPersistentContext(PROFILE, {
      headless: false,
      channel: 'chrome',
      viewport: null,
    }),
  )
  const page = await (await browser).newPage()
  await page.goto(url)
  await page.bringToFront()
}

// Runs a command under a terminal, echoing what it prints and opening each auth link once.
const run = (cmd, args) =>
  new Promise((done, fail) => {
    const seen = new Set()
    let pending = ''
    const child = spawn('script', ['-q', '/dev/null', cmd, ...args], {
      cwd: ROOT,
      stdio: ['inherit', 'pipe', 'inherit'],
      // npm prints the link and waits for it to be approved, instead of offering to open it. Each
      // package's prepack builds it and copies NOTICE in, so an ignore-scripts=true ~/.npmrc
      // would pack tarballs publish.mjs refuses (pnpm 10 still blocks dependencies' scripts).
      env: { ...process.env, npm_config_browser: 'false', npm_config_ignore_scripts: 'false' },
    })
    child.stdout.on('data', chunk => {
      process.stdout.write(chunk)
      const lines = (pending + chunk).split('\n')
      pending = lines.pop()
      for (const url of npmAuthUrls(lines.join('\n'))) {
        if (seen.has(url)) continue
        seen.add(url)
        open(url).catch(err =>
          console.error(`could not open ${url} (${err.message}); open it yourself`),
        )
      }
    })
    child.on('error', fail)
    child.on('exit', code => (code === 0 ? done() : fail(new Error(`${cmd} exited with ${code}`))))
  })

const ok = (cmd, args) => {
  try {
    return execFileSync(cmd, args, {
      cwd: ROOT,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    })
  } catch {
    return null
  }
}

const sleep = ms => new Promise(r => setTimeout(r, ms))

const main = async () => {
  if (!process.stdin.isTTY) throw new Error('run this in a terminal: npm asks for 2FA')

  if (ok('npm', ['whoami']) === null) await run('npm', ['login', '--auth-type=web'])
  console.log(`npm: logged in as ${ok('npm', ['whoami']).trim()}`)

  // Only the website can create an org, and nothing publishes until it exists.
  if (ok('npm', ['org', 'ls', ORG]) === null) {
    console.log(
      `\nCreate the npm org "${ORG}" (free, public packages) in the browser; waiting for it.`,
    )
    await open('https://www.npmjs.com/org/create')
    while (ok('npm', ['org', 'ls', ORG]) === null) await sleep(5000)
  }

  await run('bash', [RELEASE_SH, ...process.argv.slice(2)])

  // release.sh pipes `npm trust` through grep, which takes away the terminal its 2FA needs, so
  // set any trusted publisher it could not here.
  const names = readdirSync(join(ROOT, 'packages'))
    .map(dir => JSON.parse(readFileSync(join(ROOT, 'packages', dir, 'package.json'), 'utf8')))
    .filter(manifest => !manifest.private)
    .map(manifest => manifest.name)
  for (const name of names) {
    if (ok('npx', ['-y', 'npm@latest', 'trust', 'list', name])?.includes(WORKFLOW)) continue
    console.log(`\ntrusted publisher for ${name}`)
    await run('npx', [
      '-y',
      'npm@latest',
      'trust',
      'github',
      name,
      '--repo',
      REPO,
      '--file',
      WORKFLOW,
      '--allow-publish',
      '--yes',
    ])
  }

  console.log('\n✓ released')
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    await main()
  } catch (err) {
    console.error(`✗ ${err.message}`)
    process.exitCode = 1
  } finally {
    await (await browser)?.close()
  }
}
