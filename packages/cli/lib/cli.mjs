// `ember-joinery add` and `ember-joinery list`: copy Joinery's components into an app, as
// shadcn's `add` does, with its flags. Updating is `add` again: --dry-run, --diff and --view
// look before anything is written, and --overwrite takes this version's files.
import { spawnSync } from 'node:child_process'
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { createInterface } from 'node:readline/promises'
import { basename, dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const REGISTRY = join(dirname(fileURLToPath(import.meta.url)), '../registry')
const CONFIG = 'joinery.json'
const DEFAULT_PATH = 'app/joinery'
const SHOWN = 5 // --diff and --view without a path show this many files, as shadcn's do

const USAGE = `Usage: ember-joinery add [components...] [options]
       ember-joinery list

Options for add:
  -y, --yes            skip the confirmation prompt (changed files are kept)
  -o, --overwrite      overwrite existing files
  -c, --cwd <cwd>      the app's folder (default: the current folder)
  -a, --all            add every component
  -p, --path <path>    where the files go (default: joinery.json's path, or ${DEFAULT_PATH})
  -s, --silent         mute output
      --dry-run        show what would change, and write nothing
      --diff [path]    show diffs: the first ${SHOWN} changed files, or that file (implies --dry-run)
      --view [path]    show this version's files: the first ${SHOWN}, or that one (implies --dry-run)
`

const FLAGS = {
  '-y': 'yes',
  '--yes': 'yes',
  '-o': 'overwrite',
  '--overwrite': 'overwrite',
  '-a': 'all',
  '--all': 'all',
  '-s': 'silent',
  '--silent': 'silent',
  '--dry-run': 'dryRun',
  '-h': 'help',
  '--help': 'help',
}
const VALUES = { '-c': 'cwd', '--cwd': 'cwd', '-p': 'path', '--path': 'path' }

/**
 * shadcn's flags. `--diff` and `--view` take an optional path: the next argument, when it is a
 * file name (it has a dot, which no component name does).
 */
function parse(argv) {
  const options = { names: [] }
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i]
    if (FLAGS[arg]) options[FLAGS[arg]] = true
    else if (VALUES[arg]) {
      if (argv[i + 1] === undefined) throw new Error(`${arg} needs a value`)
      options[VALUES[arg]] = argv[++i]
    } else if (arg === '--diff' || arg === '--view') {
      const next = argv[i + 1]
      options[arg.slice(2)] =
        next !== undefined && next.includes('.') && !next.startsWith('-') ? argv[++i] : true
    } else if (arg.startsWith('-')) throw new Error(`Unknown option ${arg}`)
    else options.names.push(arg)
  }
  return options
}

/** Levenshtein distance, for "did you mean". */
function distance(a, b) {
  const row = Array.from({ length: b.length + 1 }, (_, i) => i)
  for (let i = 1; i <= a.length; i++) {
    let previous = row[0]
    row[0] = i
    for (let j = 1; j <= b.length; j++) {
      const current = row[j]
      row[j] = Math.min(row[j] + 1, row[j - 1] + 1, previous + (a[i - 1] === b[j - 1] ? 0 : 1))
      previous = current
    }
  }
  return row[b.length]
}

/** `^1.2.3`, `~1.2.3` or `1.2.3` → [1, 2, 3]; anything else (workspace:, file:, a tag) → null. */
const baseVersion = range =>
  range
    .match(/^[\^~]?(\d+)\.(\d+)\.(\d+)$/)
    ?.slice(1)
    .map(Number)

const older = (a, b) => {
  for (let i = 0; i < 3; i++) if (a[i] !== b[i]) return a[i] < b[i]
  return false
}

/** The package manager the lockfile names, as shadcn picks it. */
function packageManager(cwd) {
  if (existsSync(join(cwd, 'pnpm-lock.yaml'))) return 'pnpm'
  if (existsSync(join(cwd, 'yarn.lock'))) return 'yarn'
  if (existsSync(join(cwd, 'bun.lock')) || existsSync(join(cwd, 'bun.lockb'))) return 'bun'
  return 'npm'
}

function defaultInstall(pm, specs, cwd) {
  const result = spawnSync(pm, [pm === 'npm' ? 'install' : 'add', ...specs], {
    cwd,
    stdio: 'inherit',
    shell: process.platform === 'win32',
  })
  if (result.status !== 0) throw new Error(`${pm} could not install ${specs.join(' ')}`)
}

async function defaultConfirm(question) {
  const rl = createInterface({ input: process.stdin, output: process.stdout })
  try {
    return /^y(es)?$/i.test((await rl.question(`${question} (y/N) `)).trim())
  } finally {
    rl.close()
  }
}

/**
 * A unified diff of `yours` against `theirs`, with three lines of context, or '' when they are
 * the same. A plain LCS over lines: component files are a few hundred lines at most.
 */
export function unifiedDiff(name, yours, theirs, label = 'new') {
  if (yours === theirs) return ''
  const a = yours.split('\n')
  const b = theirs.split('\n')
  if (a.at(-1) === '') a.pop()
  if (b.at(-1) === '') b.pop()
  const lcs = Array.from({ length: a.length + 1 }, () => new Uint32Array(b.length + 1))
  for (let i = a.length - 1; i >= 0; i--)
    for (let j = b.length - 1; j >= 0; j--)
      lcs[i][j] = a[i] === b[j] ? lcs[i + 1][j + 1] + 1 : Math.max(lcs[i + 1][j], lcs[i][j + 1])

  // Every line as [' ' | '-' | '+', text, line in a, line in b].
  const lines = []
  let i = 0
  let j = 0
  while (i < a.length || j < b.length) {
    if (i < a.length && j < b.length && a[i] === b[j]) lines.push([' ', a[i], i++, j++])
    // Removals before additions, as diff(1) prints them.
    else if (i < a.length && (j === b.length || lcs[i + 1][j] >= lcs[i][j + 1]))
      lines.push(['-', a[i], i++, j])
    else lines.push(['+', b[j], i, j++])
  }

  const context = 3
  const changed = lines.flatMap(([op], k) => (op === ' ' ? [] : [k]))
  let out = `--- ${name} (yours)\n+++ ${name} (${label})\n`
  for (let k = 0; k < changed.length;) {
    const start = Math.max(0, changed[k] - context)
    let end = changed[k]
    while (k < changed.length && changed[k] <= end + 2 * context) end = changed[k++]
    end = Math.min(lines.length - 1, end + context)
    const hunk = lines.slice(start, end + 1)
    const aCount = hunk.filter(([op]) => op !== '+').length
    const bCount = hunk.filter(([op]) => op !== '-').length
    out += `@@ -${hunk[0][2] + 1},${aCount} +${hunk[0][3] + 1},${bCount} @@\n`
    out += hunk.map(([op, text]) => `${op}${text}\n`).join('')
  }
  return out
}

/**
 * Runs the CLI. Everything it touches outside the app's folder comes in through `io`, so the
 * tests can drive it: where the registry is, the terminal, the prompt and the installer.
 * Resolves to the exit code.
 */
export async function run(argv, io = {}) {
  const {
    registryDir = REGISTRY,
    isTTY = Boolean(process.stdin.isTTY && process.stdout.isTTY),
    stdout = text => process.stdout.write(text),
    stderr = text => process.stderr.write(text),
    confirm = defaultConfirm,
    install = defaultInstall,
  } = io
  const [command, ...rest] = argv

  let options
  try {
    options = parse(rest)
  } catch (error) {
    stderr(`${error.message}\n\n${USAGE}`)
    return 1
  }
  if (!command || options.help || command === 'help') {
    stdout(USAGE)
    return command ? 0 : 1
  }

  const manifest = JSON.parse(readFileSync(join(registryDir, 'manifest.json'), 'utf8'))
  const names = Object.keys(manifest.items)

  if (command === 'list') {
    stdout(`${names.join('\n')}\n`)
    return 0
  }
  if (command !== 'add') {
    stderr(`Unknown command "${command}".\n\n${USAGE}`)
    return 1
  }

  const log = options.silent ? () => {} : stdout
  const cwd = resolve(io.cwd ?? process.cwd(), options.cwd ?? '.')
  const preview = options.dryRun || options.diff || options.view

  if (!options.all && options.names.length === 0) {
    stderr(`Name a component to add, or pass --all.\n\n${USAGE}`)
    return 1
  }
  for (const name of options.names) {
    if (manifest.items[name]) continue
    const near = names.filter(n => distance(n, name) <= 2 || n.includes(name)).slice(0, 5)
    stderr(
      `Unknown component "${name}".${near.length ? ` Did you mean: ${near.join(', ')}?` : ''}\n`,
    )
    stderr('Run `ember-joinery list` to see them all.\n')
    return 1
  }

  // The components asked for and every component they import, in a stable order.
  const wanted = new Set()
  const visit = name => {
    if (wanted.has(name)) return
    wanted.add(name)
    manifest.items[name].registryDependencies.forEach(visit)
  }
  ;(options.all ? names : options.names).forEach(visit)
  const items = [...wanted]

  const configFile = join(cwd, CONFIG)
  const config = existsSync(configFile) ? JSON.parse(readFileSync(configFile, 'utf8')) : null
  const path = options.path ?? config?.path ?? DEFAULT_PATH

  const files = [...new Set(items.flatMap(name => manifest.items[name].files))].map(file => {
    const target = join(cwd, path, file)
    const theirs = readFileSync(join(registryDir, 'files', file), 'utf8')
    const yours = existsSync(target) ? readFileSync(target, 'utf8') : null
    const status = yours === null ? 'create' : yours === theirs ? 'unchanged' : 'overwrite'
    return { file, shown: join(path, file), target, theirs, yours, status }
  })

  // npm packages: the missing ones, and @ember-joinery/* when the app's range is older.
  const app = existsSync(join(cwd, 'package.json'))
    ? JSON.parse(readFileSync(join(cwd, 'package.json'), 'utf8'))
    : {}
  const declared = { ...app.devDependencies, ...app.dependencies }
  const needed = new Set(items.flatMap(name => manifest.items[name].dependencies))
  const specs = [...needed].sort().flatMap(name => {
    const range = manifest.dependencies[name]
    const have = declared[name]
    if (have === undefined) return [`${name}@${range}`]
    const ours = baseVersion(range)
    const theirs = baseVersion(have)
    return name.startsWith('@ember-joinery/') && ours && theirs && older(theirs, ours)
      ? [`${name}@${range}`]
      : []
  })

  // A path picks one file, by its path or its name, as shadcn's `--diff button.tsx` does.
  const pick = arg =>
    arg === true
      ? null
      : files.filter(f => f.file === arg || f.shown === arg || basename(f.file) === arg)

  if (options.view) {
    const chosen = pick(options.view) ?? files
    for (const f of chosen.slice(0, SHOWN)) log(`// ${f.shown}\n${f.theirs}\n`)
    if (options.view === true && chosen.length > SHOWN)
      log(`… and ${chosen.length - SHOWN} more files.\n`)
    return 0
  }
  if (options.diff) {
    const chosen = (pick(options.diff) ?? files).filter(f => f.status !== 'unchanged')
    for (const f of chosen.slice(0, options.diff === true ? SHOWN : chosen.length)) {
      log(unifiedDiff(f.shown, f.yours ?? '', f.theirs, manifest.version))
    }
    if (options.diff === true && chosen.length > SHOWN) {
      log(`… and ${chosen.length - SHOWN} more changed files. Name one: --diff <file>.\n`)
    }
    if (chosen.length === 0) log('No changes.\n')
    return 0
  }
  if (preview) {
    log(`ember-joinery ${manifest.version}: add ${items.join(', ')}\n\n`)
    for (const f of files) log(`  ${f.status.padEnd(9)}  ${f.shown}\n`)
    if (!config) log(`  ${'create'.padEnd(9)}  ${CONFIG}\n`)
    log(specs.length ? `\nWould install: ${specs.join(' ')}\n` : '\nNo npm packages to install.\n')
    return 0
  }

  const written = []
  const skipped = []
  for (const f of files) {
    if (f.status === 'unchanged') continue
    if (f.status === 'overwrite' && !options.overwrite) {
      const yes =
        isTTY &&
        !options.yes &&
        (await confirm(`${f.shown} already exists and differs. Overwrite it?`))
      if (!yes) {
        skipped.push(f)
        continue
      }
    }
    mkdirSync(dirname(f.target), { recursive: true })
    writeFileSync(f.target, f.theirs)
    written.push(f)
  }
  if (!config) writeFileSync(configFile, `${JSON.stringify({ path }, null, 2)}\n`)

  for (const f of written) log(`${f.status === 'create' ? 'Created' : 'Updated'} ${f.shown}\n`)
  if (skipped.length) {
    log(
      `\nSkipped ${skipped.length} changed file${skipped.length === 1 ? '' : 's'} (yours are kept):\n`,
    )
    for (const f of skipped) log(`  ${f.shown}\n`)
    log('Compare with --diff <file>, then take this version with --overwrite.\n')
  }
  if (written.length === 0 && skipped.length === 0) log('Everything is up to date.\n')

  if (specs.length) {
    const pm = packageManager(cwd)
    log(`\nInstalling ${specs.join(' ')} with ${pm}…\n`)
    install(pm, specs, cwd)
  }
  if (!declared.typescript) {
    log(
      '\nThe copies are TypeScript (.gts). Your app needs TypeScript and ' +
        '@babel/plugin-transform-typescript in its Babel config to build them.\n',
    )
  }
  return 0
}
