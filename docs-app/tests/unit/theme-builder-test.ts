import { module, test } from 'qunit'
import {
  demosFromPages,
  hexToOklch,
  previewStyle,
  styleSheetFor,
  themeCss,
  tokenGroups,
  tokensFor,
} from 'docs-app/theme-builder'

const colors = {
  light: {
    '--radius': '0.625rem',
    '--background': 'oklch(1 0 0)',
    '--primary': 'oklch(0.205 0 0)',
    '--primary-foreground': 'oklch(0.985 0 0)',
    '--chart-1': 'oklch(0.87 0 0)',
    '--brand': 'oklch(0.5 0.1 30)',
  },
  dark: { '--background': 'oklch(0.145 0 0)', '--primary': 'oklch(0.922 0 0)' },
}

module('Unit | theme builder', function () {
  test('a picked #rrggbb colour is written as oklch(), as shadcn writes its tokens', function (assert) {
    assert.strictEqual(hexToOklch('#ffffff'), 'oklch(1 0 0)')
    assert.strictEqual(hexToOklch('#000000'), 'oklch(0 0 0)')
    assert.strictEqual(hexToOklch('#ff0000'), 'oklch(0.628 0.258 29.234)')
    assert.strictEqual(hexToOklch('#808080'), 'oklch(0.6 0 0)', 'a grey has no chroma')
    assert.throws(() => hexToOklch('red'), /#rrggbb/)
  })

  test("the tokens group as shadcn's table lists them, and unknown ones under Other", function (assert) {
    assert.deepEqual(tokenGroups(colors), [
      { title: 'Page', tokens: ['--background'] },
      { title: 'Primary', tokens: ['--primary', '--primary-foreground'] },
      { title: 'Charts', tokens: ['--chart-1'] },
      { title: 'Other', tokens: ['--brand'] },
    ])
  })

  test("a mode's tokens: the base colour's, dark over light, then the edits that are colours", function (assert) {
    const edits = {
      light: { '--primary': ' oklch(0.5 0.2 260) ', '--background': 'not a colour' },
      dark: {},
    }
    const light = tokensFor(colors, edits, 'light')
    assert.strictEqual(light['--primary'], 'oklch(0.5 0.2 260)', 'trimmed')
    assert.strictEqual(light['--background'], 'oklch(1 0 0)', 'a half-typed value is left out')
    assert.false('--radius' in light, 'the radius is a setting of its own')
    const dark = tokensFor(colors, edits, 'dark')
    assert.strictEqual(dark['--primary'], 'oklch(0.922 0 0)', 'the light edit stays light')
    assert.strictEqual(dark['--primary-foreground'], 'oklch(0.985 0 0)', 'unset in .dark: light')
    assert.strictEqual(
      previewStyle({ '--primary': 'red' }, 0.5),
      '--primary: red; --radius: 0.5rem',
    )
  })

  test('the CSS: every token on :root and .dark, the radius, and the style sheet to import', function (assert) {
    const css = themeCss({
      style: 'lyra',
      baseColor: 'stone',
      radius: 0.5,
      light: { '--primary': 'oklch(0.5 0.2 260)' },
      dark: { '--primary': 'oklch(0.7 0.1 260)' },
    })
    assert.true(css.includes("import '@ember-joinery/ember/styles/lyra.css'"))
    assert.true(css.includes('the Stone base colour'))
    assert.true(css.includes(':root {\n  --radius: 0.5rem;\n  --primary: oklch(0.5 0.2 260);\n}'))
    assert.true(css.includes('.dark {\n  --primary: oklch(0.7 0.1 260);\n}'))
    assert.strictEqual(styleSheetFor('nova'), 'joinery.css', 'Nova is joinery.css')
  })

  test("each component page's demo is its first example, but for a block", function (assert) {
    const demos = demosFromPages({
      'components/button.md':
        '# Button\n\n<Example @name="button-demo" @title="Button" />\n<Example @name="button-size" />',
      'components/direction.md':
        '# Direction\n\n<Example @name="card-rtl" @title="Direction" @dir="rtl" />',
      'components/sidebar.md': '# Sidebar\n\n<Example @name="sidebar-demo" @block={{true}} />',
      'components/index.md': '# Components\n\n<SectionList @section="components" />',
    })
    assert.deepEqual(demos, [
      { page: 'components/button.md', title: 'Button', example: 'button-demo' },
      { page: 'components/direction.md', title: 'Direction', example: 'card-rtl', dir: 'rtl' },
    ])
  })
})
