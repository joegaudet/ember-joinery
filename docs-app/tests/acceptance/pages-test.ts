import { module, test } from 'qunit'
import { setupApplicationTest } from 'docs-app/tests/helpers'
import { visit, waitFor, waitUntil, find } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'

/**
 * Every guide page, as `<section>/<page>.md`, straight from docs-app/app/templates: a new page
 * is tested as soon as it exists, with no list to edit.
 */
const PAGES = Object.keys(
  import.meta.glob('../../app/templates/**/*.md', { query: '?raw', import: 'default' }),
)
  .map(path => path.replace('../../app/templates/', ''))
  .sort()

/**
 * The axe rules a page turns off, each with its reason. A page belongs here only when what it
 * shows can't meet the rule; every other rule still runs on it.
 */
const AUDIT_EXCEPTIONS: Record<string, { rules: Record<string, { enabled: false }> }> = {
  // Typography's specimens are real headings, h1 to h4, each under its own section's h2, as on
  // ui.shadcn.com: a specimen resets the outline, so the h4 comes right after an h2.
  'components/typography.md': { rules: { 'heading-order': { enabled: false } } },
}

/**
 * Where upstream's own colours fall short of the 4.5:1 WCAG AA asks of small text, in its light
 * themes, and Joinery keeps them, the component lists those elements in
 * `upstream-contrast/<component>.ts`, with its reason (its page's Accessibility notes say so
 * too, and how an app can darken them): one file each, so components land side by side. A
 * page's colour-contrast audit leaves those elements out, and every other rule runs on them.
 */
const UPSTREAM_CONTRAST = Object.values(
  import.meta.glob<string[]>('./upstream-contrast/*.ts', { eager: true, import: 'default' }),
).flat()
const CONTRAST_BUT_UPSTREAM = {
  include: [['#ember-testing-container']],
  exclude: UPSTREAM_CONTRAST.map(selector => [selector]),
}

/**
 * The axe rules that judge a page as a whole, which a page of examples can fail though each
 * example is fine on its own (its test audits it alone):
 *
 * - `landmark-unique`: upstream's examples name their landmarks as upstream's components do, so
 *   every Breadcrumb is a nav called `breadcrumb`, every Pagination one called `pagination`, and
 *   a page that shows several has several of the same.
 * - `heading-order` wants each heading at most one level below the one before it, but an
 *   example's headings are a component's, as an app would use it: an accordion's items are
 *   `<h3>`s, as upstream's, and the first example sits right under the page's `<h1>`, as on
 *   ui.shadcn.com.
 *
 * So the page's audit runs these rules over the guide's own content, leaving the examples'
 * previews out.
 */
const PAGE_RULES = ['heading-order', 'landmark-unique']
const GUIDE_CONTENT = {
  include: [['#ember-testing-container']],
  exclude: [['.example-preview']],
}

/**
 * The page's first audit runs every rule over all of it but the page's own exceptions, the
 * page rules above and `color-contrast`, which the audits after it run over their own share of
 * the page. A page's own exceptions apply to all three.
 */
const SCOPED_RULES = Object.fromEntries(
  ['color-contrast', ...PAGE_RULES].map(rule => [rule, { enabled: false as const }]),
)

module('Acceptance | guide pages', function (hooks) {
  setupApplicationTest(hooks)

  test('every section of the plan has pages', function (assert) {
    const sections = new Set(PAGES.map(page => page.split('/')[0]))
    for (const section of [
      'getting-started',
      'components',
      'primitives',
      'charts',
      'blocks',
      'formwright',
      'reference',
    ]) {
      assert.true(sections.has(section), section)
    }
  })

  for (const page of PAGES) {
    test(`${page} renders`, async function (assert) {
      await visit(`/${page}`)
      await waitFor('.guide-prose h1, .guide-error', { timeout: 15000 })
      const error = find('.guide-error')?.textContent?.trim()
      assert.notOk(error, `page error: ${error}`)
      assert
        .dom('.guide-prose h1')
        .exists(
          (document.querySelector('.guide-main')?.textContent ?? '')
            .replace(/\s+/g, ' ')
            .slice(0, 600),
        )
      // Every section heading links to itself, so it can be shared.
      for (const heading of document.querySelectorAll('.guide-prose h2[id]:not(.example h2)')) {
        assert.dom(heading.querySelector('a.heading-anchor')).hasAttribute('href', `#${heading.id}`)
      }
      // Every <Example> on the page found its file and rendered it: a block, in its own frame.
      // The audits below don't enter a block's frame; its example's own test audits it.
      for (const example of document.querySelectorAll('[data-test-example]')) {
        const name = example.getAttribute('data-test-example')!
        await waitUntil(() => !example.querySelector('.example-loading'), { timeout: 15000 })
        const preview = () =>
          example.querySelector('.example-preview') ??
          example.querySelector('iframe')?.contentDocument?.querySelector('.example-preview')
        await waitUntil(preview, { timeout: 15000 })
        assert.dom(preview()).exists(`example ${name} rendered`)
      }
      const exceptions = AUDIT_EXCEPTIONS[page]?.rules ?? {}
      await a11yAudit({ rules: { ...exceptions, ...SCOPED_RULES } })
      if (!exceptions['color-contrast'])
        await a11yAudit(CONTRAST_BUT_UPSTREAM, { runOnly: ['color-contrast'] })
      await a11yAudit(GUIDE_CONTENT, { runOnly: PAGE_RULES.filter(rule => !exceptions[rule]) })
    })
  }

  test('the sidebar lists the sections and pages in order', async function (assert) {
    await visit('/getting-started/introduction.md')
    await waitFor('.guide-prose h1', { timeout: 15000 })
    // A section's own label: its text, without the list of its pages.
    const sections = [...document.querySelectorAll('.guide-sidebar nav > ul > li')].map(li =>
      [...li.childNodes]
        .filter(node => !(node instanceof HTMLUListElement))
        .map(node => node.textContent)
        .join('')
        .trim(),
    )
    assert.deepEqual(
      sections.slice(0, 7),
      [
        'Getting Started',
        'Components',
        'Primitives',
        'Charts',
        'Blocks',
        'Formwright',
        'Reference',
      ],
      'the sections, in the plan’s order',
    )
    assert.dom('.guide-sidebar a.active').hasText('Introduction')
  })

  test('the guide starts at the introduction', async function (assert) {
    await visit('/')
    await waitFor('.guide-prose h1', { timeout: 15000 })
    assert.dom('.guide-prose h1').hasText('Introduction')
  })
})
