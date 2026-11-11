// Checks on the hand-written site in docs/site: run with `node --test scripts/*.test.mjs`.
// The page is HTML styled with Joinery's own CSS, so these hold it to the repository: the
// sections link to themselves, every local link and image resolves, every `jn-` class and
// `data-slot` it uses is one Joinery renders, the theme picker offers what the package ships,
// and the page lists every component page and package there is.
import assert from 'node:assert/strict'
import {
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  readdirSync,
  writeFileSync,
} from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { describe, it } from 'node:test'
import { SITE_CSS_DIR, copySiteCss, siteCssFiles } from './site-css.mjs'
import { GUIDE_SHOT, SHOTS, guideFiles, shotFiles } from './site-screenshots.mjs'

const root = new URL('..', import.meta.url).pathname
const site = join(root, 'docs', 'site')
const html = readFileSync(join(site, 'index.html'), 'utf8')
const card = readFileSync(join(root, 'docs', 'social-card.html'), 'utf8')
const sections = [...html.matchAll(/<section id="([^"]+)">([\s\S]*?)<\/section>/g)]
const section = id => sections.find(([, name]) => name === id)?.[2] ?? ''
/** An attribute's values in some markup, leaving out code blocks, whose text can look like one. */
const attributes = (text, name) =>
  [
    ...text.replace(/<pre>[\s\S]*?<\/pre>/g, '').matchAll(new RegExp(`\\s${name}="([^"]*)"`, 'g')),
  ].map(match => match[1])

/** Every file under a folder, as paths relative to it. */
function filesIn(dir, prefix = '') {
  return readdirSync(dir, { withFileTypes: true }).flatMap(entry =>
    entry.isDirectory()
      ? filesIn(join(dir, entry.name), `${prefix}${entry.name}/`)
      : [`${prefix}${entry.name}`],
  )
}

/** What Joinery's sources say: its components, their CSS and the ported style sheets. */
const emberSource = filesIn(join(root, 'packages', 'ember', 'src'))
  .filter(file => /\.(gts|ts|css)$/.test(file))
  .map(file => readFileSync(join(root, 'packages', 'ember', 'src', file), 'utf8'))
  .join('\n')

/** The guide's pages, by their path under the guide (`components/button.md`). */
const guidePages = new Set(filesIn(join(root, 'docs-app', 'app', 'templates')))

const cssNames = dir =>
  readdirSync(join(root, 'packages', 'ember', 'src', dir))
    .filter(file => file.endsWith('.css'))
    .map(file => file.replace(/\.css$/, ''))
    .sort()

describe('docs/site sections', () => {
  it('has sections', () => assert.ok(sections.length > 0))

  for (const [, id, body] of sections) {
    it(`#${id}: its heading links to itself, so it can be shared`, () => {
      const heading = body.match(/<h2[^>]*>([\s\S]*?)<\/h2>/)?.[1] ?? ''
      assert.match(heading, new RegExp(`<a[^>]*href="#${id}"`))
    })
  }

  it('has every section the plan lists, in its order', () => {
    assert.deepEqual(
      sections.map(([, id]) => id),
      [
        'why',
        'install',
        'usage',
        'theming',
        'components',
        'testing',
        'formwright',
        'demo',
        'guide',
        'siblings',
      ],
    )
  })

  it('links within the page only to ids it has', () => {
    const ids = new Set(attributes(html, 'id'))
    for (const href of attributes(html, 'href').filter(href => href.startsWith('#'))) {
      assert.ok(ids.has(href.slice(1)), `${href} is not on the page`)
    }
  })

  it('gives no two elements the same id', () => {
    const ids = attributes(html, 'id')
    assert.deepEqual(
      ids.filter((id, index) => ids.indexOf(id) !== index),
      [],
    )
  })
})

describe('docs/site links and files', () => {
  const local = [...attributes(html, 'href'), ...attributes(html, 'src')].filter(
    url => !/^(https?:|#|mailto:)/.test(url) && url !== './',
  )

  it('links each guide page that exists', () => {
    const guide = local.filter(url => url.startsWith('guide/') && url !== 'guide/')
    assert.ok(guide.length > 0)
    for (const url of guide) {
      const page = url.slice('guide/'.length).split('#')[0]
      assert.ok(guidePages.has(page), `${url}: no docs-app/app/templates/${page}`)
    }
  })

  it('loads files that are in docs/site, or that the Pages build puts there', () => {
    // The demo and the guide are built into docs/site by pages.yml; Joinery's CSS is copied in
    // by `pnpm site:css`.
    const built = url =>
      url === 'guide/' || url.startsWith('guide/') || url === 'demo/' || url.startsWith(`joinery/`)
    for (const url of local.filter(url => !built(url))) {
      assert.ok(existsSync(join(site, url)), `docs/site/${url} is missing`)
    }
  })

  it("loads Joinery's CSS from where `pnpm site:css` copies it", () => {
    assert.equal(SITE_CSS_DIR, 'docs/site/joinery')
    assert.match(html, /<link id="jn-tokens" rel="stylesheet" href="joinery\/tokens\.css" \/>/)
    assert.match(html, /<link id="jn-style" rel="stylesheet" href="joinery\/joinery\.css" \/>/)
  })

  it('loads site.css before Joinery, so its layer sits below Joinery’s', () => {
    assert.ok(html.indexOf('href="site.css"') < html.indexOf('href="joinery/tokens.css"'))
    assert.match(readFileSync(join(site, 'site.css'), 'utf8'), /^@layer site-base, joinery;$/m)
  })

  it('pins every script and style sheet from a CDN with its hash', () => {
    const tags = html.match(/<(script|link)\b[^>]*cdnjs[^>]*>/g) ?? []
    assert.ok(tags.length > 0)
    for (const tag of tags) {
      assert.match(tag, /integrity="sha384-[^"]+"/, tag)
      assert.match(tag, /crossorigin="anonymous"/, tag)
    }
  })
})

describe("docs/site is Joinery's markup", () => {
  for (const [name, text] of [
    ['index.html', html],
    ['social-card.html', card],
  ]) {
    it(`${name}: every jn- class is one Joinery's sources define or render`, () => {
      const classes = new Set(
        attributes(text, 'class').flatMap(value =>
          value.split(/\s+/).filter(c => c.startsWith('jn-')),
        ),
      )
      assert.ok(classes.size > 0)
      for (const name of classes) {
        assert.ok(emberSource.includes(name), `${name} is in no file of packages/ember/src`)
      }
    })

    it(`${name}: every data-slot is one a Joinery part renders`, () => {
      for (const slot of new Set(attributes(text, 'data-slot'))) {
        assert.ok(
          emberSource.includes(`'${slot}'`) || emberSource.includes(`"${slot}"`),
          `data-slot="${slot}" is rendered by no part in packages/ember/src`,
        )
      }
    })
  }
})

describe('docs/site theming', () => {
  const options = id => {
    const select = html.match(new RegExp(`<select[^>]*id="${id}"[^>]*>([\\s\\S]*?)</select>`))
    assert.ok(select, `no #${id}`)
    return attributes(select[1], 'value')
  }

  it("offers every style the package ships (src/styles), and Nova's joinery.css first", () => {
    const styles = options('theme-style')
    assert.equal(styles[0], 'nova')
    assert.deepEqual([...styles].sort(), cssNames('styles'))
  })

  it('offers every base colour the package ships (src/themes), Neutral first', () => {
    const bases = options('theme-base')
    assert.equal(bases[0], 'neutral')
    assert.deepEqual([...bases].sort(), cssNames('themes'))
  })

  it("offers the guide's radii", () => {
    const preview = readFileSync(join(root, 'docs-app', 'app', 'preview.ts'), 'utf8')
    const radii = preview.match(/RADII: readonly number\[\] = \[([^\]]*)\]/)[1]
    assert.deepEqual(
      options('theme-radius').map(Number),
      radii.split(',').map(value => Number(value.trim())),
    )
  })

  it('swaps in the files `pnpm site:css` copies: themes/<colour>.css and styles/<style>.css', () => {
    const script = readFileSync(join(site, 'site.js'), 'utf8')
    assert.match(script, /`styles\/\$\{style\}\.css`/)
    assert.match(script, /`themes\/\$\{base\}\.css`/)
    assert.match(script, /`joinery\/\$\{/)
  })
})

describe('docs/site components', () => {
  const components = section('components')

  it('links every page of the guide’s Components section', () => {
    const pages = [...guidePages]
      .filter(page => /^components\/[^/]+\.md$/.test(page) && page !== 'components/index.md')
      .sort()
    const linked = new Set(attributes(components, 'href'))
    assert.deepEqual(
      pages.filter(page => !linked.has(`guide/${page}`)),
      [],
      'add these to the component groups in #components',
    )
  })

  it('shows each screenshot site-screenshots.mjs takes, light and dark, linked to its page', () => {
    for (const shot of SHOTS) {
      const [light, dark] = shotFiles(shot)
      const tile = components.match(
        new RegExp(`<a href="guide/${shot.page}\\.md">([\\s\\S]*?)</a>`),
      )?.[1]
      assert.ok(tile, `no tile linking guide/${shot.page}.md`)
      assert.match(tile, new RegExp(`class="shot-light"\\s+src="${light}"`))
      assert.match(tile, new RegExp(`class="shot-dark"\\s+src="${dark}"`))
      for (const file of [light, dark]) {
        assert.ok(existsSync(join(site, file)), `docs/site/${file}: run pnpm site:screenshots`)
      }
    }
  })

  it('has no screenshot the script does not take', () => {
    const taken = new Set(SHOTS.flatMap(shotFiles))
    const shown = attributes(html, 'src').filter(src => src.startsWith('img/components/'))
    assert.deepEqual(
      shown.filter(src => !taken.has(src)),
      [],
    )
    assert.deepEqual(
      filesIn(join(site, 'img', 'components'))
        .map(file => `img/components/${file}`)
        .filter(file => !taken.has(file)),
      [],
    )
  })

  it("shows the guide's example frame, light and dark, from a page the guide has", () => {
    assert.ok(guidePages.has(GUIDE_SHOT.page))
    for (const file of guideFiles()) {
      assert.ok(html.includes(`src="${file}"`), `${file} is not on the page`)
      assert.ok(existsSync(join(site, file)), `docs/site/${file}: run pnpm site:screenshots`)
    }
  })
})

describe('docs/site packages', () => {
  it('names every published package in #install', () => {
    const install = section('install')
    const packages = readdirSync(join(root, 'packages'))
      .map(dir => join(root, 'packages', dir, 'package.json'))
      .filter(existsSync)
      .map(file => JSON.parse(readFileSync(file, 'utf8')))
      .filter(pkg => !pkg.private)
      .map(pkg => pkg.name)
    assert.ok(packages.length > 0)
    for (const name of packages) {
      assert.ok(install.includes(`<code>${name}</code>`), `${name} is not in #install's table`)
    }
  })
})

describe('docs/social-card.html', () => {
  it("loads the site's logo and Joinery's CSS from docs/site", () => {
    for (const url of [...attributes(card, 'href'), ...attributes(card, 'src')].filter(
      url => !url.startsWith('http'),
    )) {
      assert.ok(url.startsWith('site/'), url)
      if (!url.startsWith('site/joinery/')) assert.ok(existsSync(join(root, 'docs', url)), url)
    }
    assert.ok(card.includes('href="site/joinery/tokens.css"'))
    assert.ok(card.includes('href="site/joinery/joinery.css"'))
  })
})

describe('scripts/site-css.mjs', () => {
  /** A stand-in for packages/ember/dist, with the files the build writes. */
  function fakeRepo() {
    const repo = mkdtempSync(join(tmpdir(), 'site-css-'))
    const dist = join(repo, 'packages', 'ember', 'dist')
    for (const dir of ['themes', 'styles', 'components'])
      mkdirSync(join(dist, dir), { recursive: true })
    for (const file of [
      'tokens.css',
      'joinery.css',
      'tailwind.css',
      'index.js',
      'themes/stone.css',
      'themes/neutral.css',
      'styles/lyra.css',
      'styles/luma.css',
      'components/button.js',
    ]) {
      writeFileSync(join(dist, file), `/* ${file} */`)
    }
    return { repo, dist }
  }

  it('copies the default theme and style, and every base colour and style, A–Z', () => {
    const { dist } = fakeRepo()
    assert.deepEqual(siteCssFiles(dist), [
      'tokens.css',
      'joinery.css',
      'themes/neutral.css',
      'themes/stone.css',
      'styles/luma.css',
      'styles/lyra.css',
    ])
  })

  it('writes them into docs/site/joinery, replacing what was there', () => {
    const { repo } = fakeRepo()
    const out = join(repo, 'docs', 'site', 'joinery')
    mkdirSync(join(out, 'themes'), { recursive: true })
    writeFileSync(join(out, 'themes', 'gone.css'), '')
    const written = copySiteCss(repo)
    assert.equal(written[0], 'docs/site/joinery/tokens.css')
    assert.deepEqual(filesIn(out).sort(), [
      'joinery.css',
      'styles/luma.css',
      'styles/lyra.css',
      'themes/neutral.css',
      'themes/stone.css',
      'tokens.css',
    ])
    assert.equal(readFileSync(join(out, 'styles', 'lyra.css'), 'utf8'), '/* styles/lyra.css */')
  })

  it('fails, saying what to run, when the package is not built', () => {
    const repo = mkdtempSync(join(tmpdir(), 'site-css-'))
    assert.throws(() => copySiteCss(repo), /run `pnpm build` first/)
  })
})
