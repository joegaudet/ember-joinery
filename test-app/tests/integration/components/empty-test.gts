import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FolderCode } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Button, Empty, Icon, type EmptyMediaVariant } from '@ember-joinery/ember'
import { ButtonHarness, EmptyHarness } from '@ember-joinery/test-support'

const VARIANTS: EmptyMediaVariant[] = ['default', 'icon']

/** An element's classes and attributes (but the test's own `data-case`), to compare two. */
function rendering(element: Element): { classes: string[]; attributes: Record<string, string> } {
  const attributes: Record<string, string> = {}
  for (const { name, value } of element.attributes) {
    if (name !== 'class' && name !== 'data-case') attributes[name] = value
  }
  return { classes: [...element.classList].sort(), attributes }
}

module('Integration | components | empty', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream classes and data attributes on every part', async function (assert) {
    await render(
      <template>
        <Empty as |e|>
          <e.Header>
            <e.Media @variant="icon"><Icon @icon={{FolderCode}} /></e.Media>
            <e.Title>No data</e.Title>
            <e.Description>No data found</e.Description>
          </e.Header>
          <e.Content><Button>Add data</Button></e.Content>
        </Empty>
      </template>,
    )
    const empty = new EmptyHarness()

    assert
      .dom(empty.element)
      .hasTagName('div')
      .hasClass('jn-empty')
      .hasAttribute('data-slot', 'empty')
      .hasAttribute('data-test-jn', 'empty')
    assert.dom(empty.header).hasClass('jn-empty-header').hasAttribute('data-slot', 'empty-header')
    assert
      .dom(empty.media)
      .hasClass('jn-empty-media')
      .hasClass('jn-empty-media-icon')
      .hasAttribute('data-slot', 'empty-icon', "upstream's slot for the media")
      .hasAttribute('data-variant', 'icon')
    assert
      .dom(empty.part('title'))
      .hasClass('jn-empty-title')
      .hasClass('jn-font-heading')
      .hasAttribute('data-slot', 'empty-title')
    assert
      .dom(empty.part('description'))
      .hasClass('jn-empty-description')
      .hasAttribute('data-slot', 'empty-description')
    assert
      .dom(empty.content)
      .hasClass('jn-empty-content')
      .hasAttribute('data-slot', 'empty-content')
    assert.strictEqual(empty.title, 'No data')
    assert.strictEqual(empty.description, 'No data found')
    assert.strictEqual(empty.mediaVariant, 'icon')
    assert.strictEqual(empty.find(ButtonHarness).label, 'Add data')
    await a11yAudit()
  })

  test('every media variant renders its class and data attribute', async function (assert) {
    await render(
      <template>
        {{#each VARIANTS as |variant|}}
          <Empty @name={{variant}} as |e|>
            <e.Header>
              <e.Media @variant={{variant}}><Icon @icon={{FolderCode}} /></e.Media>
              <e.Title>{{variant}}</e.Title>
            </e.Header>
          </Empty>
        {{/each}}
        <Empty @name="unset" as |e|><e.Media>Media</e.Media></Empty>
      </template>,
    )
    for (const variant of VARIANTS) {
      const empty = new EmptyHarness(variant)
      assert.strictEqual(empty.mediaVariant, variant)
      assert.dom(empty.media).hasClass(`jn-empty-media-${variant}`)
    }
    assert.strictEqual(new EmptyHarness('unset').mediaVariant, 'default', "upstream's default")
    await a11yAudit()
  })

  test('its style sheet centres it and sizes its media, without Tailwind', async function (assert) {
    await render(
      <template>
        <div style="display: flex; width: 640px; height: 400px">
          <Empty @name="state" as |e|>
            <e.Header>
              <e.Media @variant="icon"><Icon @icon={{FolderCode}} /></e.Media>
              <e.Title>No Projects Yet</e.Title>
              <e.Description>You haven't created any projects yet.</e.Description>
            </e.Header>
            <e.Content><Button>Create Project</Button></e.Content>
          </Empty>
        </div>
      </template>,
    )
    const empty = new EmptyHarness('state')
    const style = getComputedStyle(empty.element)
    assert.strictEqual(style.display, 'flex')
    assert.strictEqual(style.flexDirection, 'column')
    assert.strictEqual(style.alignItems, 'center')
    assert.strictEqual(style.justifyContent, 'center')
    assert.strictEqual(style.textAlign, 'center')
    assert.strictEqual(style.flexGrow, '1', 'flex-1 fills its container')
    assert.strictEqual(style.rowGap, '16px', 'gap-4')
    assert.strictEqual(style.paddingTop, '24px', 'p-6')
    assert.strictEqual(style.borderTopLeftRadius, '14px', 'rounded-xl')
    assert.strictEqual(style.borderTopStyle, 'dashed', 'border-dashed, for a border class to show')
    assert.strictEqual(style.borderTopWidth, '0px', 'but no border of its own')
    assert.strictEqual(empty.element.offsetHeight, 400, 'it fills the height')

    const header = getComputedStyle(empty.header)
    assert.strictEqual(header.maxWidth, '384px', 'max-w-sm')
    assert.strictEqual(header.rowGap, '8px', 'gap-2')

    const media = getComputedStyle(empty.media)
    assert.strictEqual(media.width, '32px', 'size-8')
    assert.strictEqual(media.height, '32px')
    assert.strictEqual(media.marginBottom, '8px', 'mb-2')
    assert.strictEqual(media.borderTopLeftRadius, '10px', 'rounded-lg')
    assert.notStrictEqual(media.backgroundColor, 'rgba(0, 0, 0, 0)', 'bg-muted')
    assert.strictEqual(getComputedStyle(empty.media.querySelector('svg')!).width, '16px')

    const title = getComputedStyle(empty.part('title'))
    assert.strictEqual(title.fontSize, '14px', 'text-sm')
    assert.strictEqual(title.fontWeight, '500', 'font-medium')
    const description = getComputedStyle(empty.part('description'))
    assert.strictEqual(description.lineHeight, '22.75px', 'text-sm/relaxed')
    assert.notStrictEqual(description.color, title.color, 'muted')

    const content = getComputedStyle(empty.content)
    assert.strictEqual(content.maxWidth, '384px')
    assert.strictEqual(content.rowGap, '10px', 'gap-2.5')
    await a11yAudit()
  })

  test('@as and a class go on any part, and a description link is underlined', async function (assert) {
    await render(
      <template>
        <Empty @as="section" @name="search" class="mine" as |e|>
          <e.Header @as="header">
            <e.Title @as="h2">404 - Not Found</e.Title>
            <e.Description @as="p" class="hint">
              Need help?
              <a href="#">Contact support</a>
            </e.Description>
          </e.Header>
          <e.Content @as="footer">Content</e.Content>
        </Empty>
      </template>,
    )
    const empty = new EmptyHarness('search')
    assert.dom(empty.element).hasTagName('section').hasClass('mine').hasClass('jn-empty')
    assert.dom(empty.header).hasTagName('header')
    assert.dom(empty.part('title')).hasTagName('h2')
    assert.dom(empty.part('description')).hasTagName('p').hasClass('hint')
    assert.dom(empty.content).hasTagName('footer')
    assert.strictEqual(getComputedStyle(empty.part('title')).marginTop, '0px')
    const link = empty.part('description').querySelector('a')!
    assert.strictEqual(getComputedStyle(link).textDecorationLine, 'underline', '[&>a]:underline')
    await a11yAudit()
  })

  test('keyboard: an empty state takes no focus; its content keeps its own', async function (assert) {
    await render(
      <template>
        <Empty as |e|>
          <e.Header><e.Title>No Notifications</e.Title></e.Header>
          <e.Content><Button @name="refresh">Refresh</Button></e.Content>
        </Empty>
      </template>,
    )
    const empty = new EmptyHarness()
    assert.strictEqual(empty.element.tabIndex, -1, 'not in the tab order')
    const refresh = empty.find(ButtonHarness, 'refresh')
    await refresh.focus()
    assert.true(refresh.isFocused)
    await a11yAudit()
  })

  test('the part modifiers make your own elements its parts, and follow the media variant', async function (assert) {
    class State {
      @tracked variant: EmptyMediaVariant = 'default'
    }
    const state = new State()
    await render(
      <template>
        <Empty @name="components" as |e|>
          <e.Header data-case="component">
            <e.Media data-case="component" @variant="icon">Media</e.Media>
            <e.Title data-case="component">Title</e.Title>
            <e.Description data-case="component">Description</e.Description>
          </e.Header>
          <e.Content data-case="component">Content</e.Content>
        </Empty>
        <Empty @name="modifiers" as |e|>
          <div data-case="modifier" {{e.header}}>
            <div data-case="modifier" {{e.media variant="icon"}}>Media</div>
            <div data-case="modifier" {{e.title}}>Title</div>
            <div data-case="modifier" {{e.description}}>Description</div>
          </div>
          <div data-case="modifier" {{e.content}}>Content</div>
        </Empty>
        <Empty @name="tracked" as |e|>
          <span {{e.media variant=state.variant}}>Media</span>
        </Empty>
      </template>,
    )
    const components = [...document.querySelectorAll('[data-case="component"]')]
    const modifiers = [...document.querySelectorAll('[data-case="modifier"]')]
    assert.strictEqual(components.length, 5)
    components.forEach((component, index) => {
      assert.deepEqual(
        rendering(modifiers[index]!),
        rendering(component),
        `part ${index}: the same`,
      )
    })

    const tracking = new EmptyHarness('tracked')
    assert.strictEqual(tracking.mediaVariant, 'default')
    assert.dom(tracking.media).hasClass('jn-empty-media-default')
    state.variant = 'icon'
    await settled()
    assert.strictEqual(tracking.mediaVariant, 'icon', 'the variant follows')
    assert
      .dom(tracking.media)
      .hasClass('jn-empty-media-icon')
      .doesNotHaveClass('jn-empty-media-default')
    await a11yAudit()
  })

  test('RTL: it stays centred, and a row of buttons runs right to left', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Empty @name="rtl" as |e|>
            <e.Header>
              <e.Title>لا توجد مشاريع بعد</e.Title>
              <e.Description>ابدأ بإنشاء مشروعك الأول.</e.Description>
            </e.Header>
            <e.Content style="flex-direction: row">
              <Button @name="create">إنشاء مشروع</Button>
              <Button @name="import" @variant="outline">استيراد مشروع</Button>
            </e.Content>
          </Empty>
        </DirectionProvider>
      </template>,
    )
    const empty = new EmptyHarness('rtl')
    const centre = (element: Element) => {
      const box = element.getBoundingClientRect()
      return Math.round(box.left + box.width / 2)
    }
    assert.strictEqual(centre(empty.header), centre(empty.element), 'the header is centred')
    assert.strictEqual(getComputedStyle(empty.part('description')).textAlign, 'center')
    const create = empty.find(ButtonHarness, 'create').element.getBoundingClientRect()
    const imported = empty.find(ButtonHarness, 'import').element.getBoundingClientRect()
    assert.ok(create.left > imported.left, 'the first button is on the right')
    await a11yAudit()
  })

  test('the harness reads every description, and an empty state without parts', async function (assert) {
    await render(
      <template>
        <Empty @name="two" as |e|>
          <e.Header>
            <e.Title>404 - Not Found</e.Title>
            <e.Description>The page you're looking for doesn't exist.</e.Description>
          </e.Header>
          <e.Content>
            <e.Description>Need help?</e.Description>
          </e.Content>
        </Empty>
        <Empty @name="bare">Nothing here</Empty>
      </template>,
    )
    const two = new EmptyHarness('two')
    assert.deepEqual(two.descriptions, ["The page you're looking for doesn't exist.", 'Need help?'])
    assert.strictEqual(two.description, "The page you're looking for doesn't exist.", 'the first')
    assert.strictEqual(two.mediaVariant, null, 'no media')
    const bare = new EmptyHarness('bare')
    assert.strictEqual(bare.title, '')
    assert.strictEqual(bare.text, 'Nothing here')
    assert.throws(() => bare.content, /no "content" part found in empty "bare"/)
    await a11yAudit()
  })
})
