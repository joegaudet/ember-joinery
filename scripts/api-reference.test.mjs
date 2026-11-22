// Builds the API reference (`pnpm docs:api`, after `pnpm build`) and checks it: a page per
// package, named as it's imported, the guide's refinements (examples as code, own members only),
// and what search engines and agents read from it (meta, sitemap, llms-full.txt, api.json).
import { execFileSync } from 'node:child_process'
import { readFileSync, readdirSync } from 'node:fs'
import { test } from 'node:test'
import assert from 'node:assert/strict'

const root = new URL('../', import.meta.url)
const read = path => readFileSync(new URL(path, root), 'utf8')
const base = 'https://joegaudet.com/ember-joinery/api/'

/** The packages the guide's Reference documents (docs-app/vite.config.mjs). */
const API_PACKAGES = [
  .../const API_PACKAGES = \[([\s\S]*?)\]/
    .exec(read('docs-app/vite.config.mjs'))[1]
    .matchAll(/'([^']+)'/g),
].map(match => match[1])

/** The HTML page of a class, found by its name. */
const classPage = name => {
  const file = readdirSync(new URL('docs/api/classes/', root)).find(file =>
    file.endsWith(`.${name}.html`),
  )
  assert.ok(file, `no page for class ${name}`)
  return read(`docs/api/classes/${file}`)
}

execFileSync('pnpm', ['docs:api'], { cwd: root, stdio: 'inherit' })

test('every package the guide documents has a module, named as it is imported', () => {
  const names = JSON.parse(read('docs/api/api.json')).children.map(child => child.name)
  assert.ok(API_PACKAGES.length > 10)
  for (const name of API_PACKAGES) assert.ok(names.includes(name), `${name} has no module`)
  assert.ok(names.includes('@ember-joinery/carousel/test-support'))
  assert.deepEqual(
    names.filter(name => !name.startsWith('@ember-joinery/')),
    [],
  )
})

test("a comment's indented example renders as code, not as markup", () => {
  const page = classPage('Zoetrope')
  assert.match(page, /<pre><code[^>]*>[\s\S]*film\.url[\s\S]*<\/code>/)
  assert.doesNotMatch(page, /<a href="\{\{film\.url\}\}"/)
})

test('a comment keeps its {@link}s when its examples become code', () => {
  const drawer = readdirSync(new URL('docs/api/', root), { recursive: true }).find(file =>
    /primitives\.Drawer\.html$/.test(file),
  )
  assert.ok(drawer, 'no page for Drawer')
  const page = read(`docs/api/${drawer}`)
  assert.match(page, /<a href="[^"]*primitives\.Dialog\.html"[^>]*>Dialog<\/a> underneath/)
  assert.match(page, /<pre><code[^>]*>(?:(?!<\/code>)[\s\S])*Trigger/)
})

test('a class lists its own members, not those it inherits', () => {
  assert.doesNotMatch(classPage('Button'), /willDestroy/)
})

test('pages carry canonical, link-preview and JSON-LD meta', () => {
  const page = read('docs/api/index.html')
  assert.match(page, new RegExp(`<link rel="canonical" href="${base}"`))
  assert.match(
    page,
    /<meta property="og:image" content="https:\/\/joegaudet.com\/ember-joinery\/social-card.png"/,
  )
  assert.match(page, /<meta name="twitter:card" content="summary_large_image"/)
  const ld = JSON.parse(/<script type="application\/ld\+json">(.*?)<\/script>/s.exec(page)[1])
  assert.equal(ld['@type'], 'TechArticle')
  assert.equal(ld.url, base)
})

test('pages use the marketing site styles', () => {
  assert.match(read('docs/api/index.html'), /assets\/custom.css/)
  assert.match(read('docs/api/assets/custom.css'), /--site-accent/)
})

test('the sitemap lists absolute API URLs', () => {
  assert.match(read('docs/api/sitemap.xml'), new RegExp(`<loc>${base}`))
})

test('llms-full.txt is llms.txt plus the API reference', () => {
  const full = read('docs/api/llms-full.txt')
  assert.ok(full.startsWith(read('docs/site/llms.txt')))
  assert.match(full, /## API reference/)
  assert.match(full, /^# Class: Button$/m)
})

test('api.json is the TypeDoc model, for tools that read the API rather than the pages', () => {
  const model = JSON.parse(read('docs/api/api.json'))
  assert.equal(model.name, 'Joinery')
  assert.ok(model.children.some(child => child.name === '@ember-joinery/ember'))
})
