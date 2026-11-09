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
      for (const heading of document.querySelectorAll('.guide-prose h2[id]')) {
        assert.dom(heading.querySelector('a.heading-anchor')).hasAttribute('href', `#${heading.id}`)
      }
      // Every <Example> on the page found its file and rendered it.
      for (const example of document.querySelectorAll('[data-test-example]')) {
        const name = example.getAttribute('data-test-example')!
        await waitUntil(() => !example.querySelector('.example-loading'), { timeout: 15000 })
        assert.dom(example.querySelector('.example-preview')).exists(`example ${name} rendered`)
      }
      await a11yAudit()
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
