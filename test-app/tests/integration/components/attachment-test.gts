import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FileText, RefreshCw, X } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import {
  Attachment,
  AttachmentGroup,
  Dialog,
  Icon,
  Spinner,
  type AttachmentOrientation,
  type AttachmentSize,
  type AttachmentState,
} from '@ember-joinery/ember'
import {
  AttachmentGroupHarness,
  AttachmentHarness,
  ButtonHarness,
  DialogHarness,
  tab,
} from '@ember-joinery/test-support'

// A 1×1 grey PNG, so an image renders without the network.
const IMAGE =
  'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAACklEQVR4nGNgAAAAAgABSK+kcQAAAABJRU5ErkJggg=='

const STATES: AttachmentState[] = ['idle', 'uploading', 'processing', 'error', 'done']
const SIZES: AttachmentSize[] = ['default', 'sm', 'xs']

/**
 * The audits, but for an errored attachment's text: upstream draws its description
 * `--destructive` at 80%, and its media's icon `--destructive` on its own 10% tint, under the
 * 4.5:1 WCAG AA asks of small text (the Attachment page's Accessibility notes say so). One audit
 * runs every other rule on them; the other checks the contrast of everything else.
 */
const ALL_BUT_CONTRAST = { rules: { 'color-contrast': { enabled: false } } }
const BUT_THE_ERROR_TEXT = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="attachment"][data-state="error"] [data-slot="attachment-description"]']],
}

/** A rendered length in pixels. */
const px = (value: string) => Number.parseFloat(value)

/** How much the test container scales what it shows: on-screen lengths are this times CSS ones. */
const scaleOf = (element: HTMLElement) =>
  element.getBoundingClientRect().width / element.offsetWidth

/** The element on screen at the middle of `element`, as a pointer there would hit. */
function hitAt(element: Element): Element | null {
  const box = element.getBoundingClientRect()
  return document.elementFromPoint(box.left + box.width / 2, box.top + box.height / 2)
}

module('Integration | components | attachment', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream classes and data attributes on every part', async function (assert) {
    await render(
      <template>
        <Attachment @name="report" as |at|>
          <at.Media><Icon @icon={{FileText}} /></at.Media>
          <at.Content>
            <at.Title>sales-dashboard.pdf</at.Title>
            <at.Description>PDF · 2.4 MB</at.Description>
          </at.Content>
          <at.Actions>
            <at.Action aria-label="Remove sales-dashboard.pdf"><Icon @icon={{X}} /></at.Action>
          </at.Actions>
          <at.Trigger aria-label="Open sales-dashboard.pdf" />
        </Attachment>
      </template>,
    )
    const attachment = new AttachmentHarness('report')
    assert
      .dom(attachment.element)
      .hasTagName('div')
      .hasClass('jn-attachment')
      .hasClass('group/attachment', 'the marker its parts look for')
      .hasClass('jn-attachment-size-default')
      .hasClass('jn-attachment-orientation-horizontal')
      .hasAttribute('data-slot', 'attachment')
      .hasAttribute('data-state', 'done', "upstream's default")
      .hasAttribute('data-size', 'default')
      .hasAttribute('data-orientation', 'horizontal')
      .doesNotHaveAttribute('role', 'a layout, with no role of its own')
    assert
      .dom(attachment.media)
      .hasTagName('div')
      .hasClass('jn-attachment-media')
      .hasClass('jn-attachment-media-variant-icon')
      .hasAttribute('data-slot', 'attachment-media')
      .hasAttribute('data-variant', 'icon')
    assert
      .dom(attachment.content)
      .hasClass('jn-attachment-content')
      .hasAttribute('data-slot', 'attachment-content')
    assert
      .dom(attachment.titleElement)
      .hasTagName('span')
      .hasClass('jn-attachment-title')
      .hasAttribute('data-slot', 'attachment-title')
    assert
      .dom(attachment.descriptionElement)
      .hasTagName('span')
      .hasClass('jn-attachment-description')
      .hasAttribute('data-slot', 'attachment-description')
    assert
      .dom(attachment.actionsElement)
      .hasClass('jn-attachment-actions')
      .hasAttribute('data-slot', 'attachment-actions')
    const [remove] = attachment.actions
    assert
      .dom(remove!.element)
      .hasTagName('button')
      .hasClass('jn-button')
      .hasClass('jn-attachment-action')
      .hasClass('jn-button-variant-ghost', "upstream's default variant")
      .hasClass('jn-button-size-icon-xs', "upstream's default size")
      .hasAttribute('data-slot', 'attachment-action')
      .hasAttribute('data-variant', 'ghost')
      .hasAttribute('data-size', 'icon-xs')
      .doesNotHaveAttribute('type', 'as upstream, and Button: it sets none')
    assert
      .dom(attachment.trigger)
      .hasTagName('button')
      .hasClass('jn-attachment-trigger')
      .hasAttribute('data-slot', 'attachment-trigger')
      .hasAttribute('type', 'button')
    assert.strictEqual(attachment.title, 'sales-dashboard.pdf')
    assert.strictEqual(attachment.description, 'PDF · 2.4 MB')
    assert.strictEqual(attachment.mediaVariant, 'icon')
    assert.deepEqual(attachment.actionLabels, ['Remove sales-dashboard.pdf'])
    assert.strictEqual(attachment.triggerLabel, 'Open sales-dashboard.pdf')
    assert.true(attachment.hasTrigger)
    assert.false(attachment.isBusy)
    await a11yAudit()
  })

  test('every size renders its classes, and the style sheet sizes each', async function (assert) {
    await render(
      <template>
        <div style="width: 384px; display: flex; flex-direction: column; gap: 12px">
          {{#each SIZES as |size|}}
            <Attachment @size={{size}} @name={{size}} style="width: 100%" as |at|>
              <at.Media><Icon @icon={{FileText}} /></at.Media>
              <at.Content>
                <at.Title>The {{size}} attachment</at.Title>
                <at.Description>PDF · 2.4 MB</at.Description>
              </at.Content>
            </Attachment>
          {{/each}}
        </div>
      </template>,
    )
    const styles = (size: string) => {
      const attachment = new AttachmentHarness(size)
      return {
        root: getComputedStyle(attachment.element),
        media: getComputedStyle(attachment.media),
        icon: getComputedStyle(attachment.media.querySelector('svg')!),
      }
    }
    for (const size of SIZES) {
      const attachment = new AttachmentHarness(size)
      assert.strictEqual(attachment.size, size)
      assert.dom(attachment.element).hasClass(`jn-attachment-size-${size}`)
    }
    // Nova: rounded-xl, w-10 media with a size-4 icon, gap-2 and p-2, text-sm.
    const standard = styles('default')
    assert.strictEqual(standard.root.display, 'flex')
    assert.strictEqual(standard.root.alignItems, 'center', 'horizontal: items-center')
    assert.strictEqual(standard.root.borderTopWidth, '1px', 'border')
    assert.strictEqual(standard.root.borderTopStyle, 'solid', 'done: a solid border')
    assert.strictEqual(standard.root.borderTopLeftRadius, '14px', 'rounded-xl')
    assert.strictEqual(standard.root.columnGap, '8px', 'gap-2')
    assert.strictEqual(standard.root.paddingTop, '8px', 'has media: p-2')
    assert.strictEqual(standard.root.fontSize, '14px', 'text-sm')
    assert.strictEqual(standard.media.width, '40px', 'w-10')
    assert.strictEqual(standard.media.height, '40px', 'aspect-square')
    assert.strictEqual(standard.media.borderTopLeftRadius, '10px', 'rounded-lg')
    assert.strictEqual(standard.icon.width, '16px', 'size-4')
    assert.strictEqual(styles('sm').media.width, '32px', 'w-8')
    assert.strictEqual(styles('sm').root.fontSize, '12px', 'text-xs')
    assert.strictEqual(styles('sm').root.columnGap, '10px', 'gap-2.5')
    assert.strictEqual(styles('xs').media.width, '28px', 'w-7')
    assert.strictEqual(styles('xs').media.borderTopLeftRadius, '8px', 'rounded-md')
    assert.strictEqual(styles('xs').icon.width, '14px', 'size-3.5')
    assert.strictEqual(styles('xs').root.borderTopLeftRadius, '10px', 'rounded-lg')

    const title = getComputedStyle(new AttachmentHarness('default').titleElement)
    assert.strictEqual(title.fontWeight, '500', 'font-medium')
    assert.strictEqual(title.textOverflow, 'ellipsis', 'truncate')
    assert.strictEqual(title.whiteSpace, 'nowrap')
    const description = getComputedStyle(new AttachmentHarness('default').descriptionElement)
    assert.strictEqual(description.fontSize, '12px', 'text-xs')
    assert.strictEqual(description.marginTop, '2px', 'mt-0.5')
    assert.notStrictEqual(description.color, title.color, 'text-muted-foreground')
    await a11yAudit()
  })

  test('a vertical attachment stacks its media on top, and its actions over the corner', async function (assert) {
    await render(
      <template>
        <Attachment @orientation="vertical" @name="image" as |at|>
          <at.Media @variant="image"><img src={{IMAGE}} alt="Workspace" /></at.Media>
          <at.Content>
            <at.Title>workspace.png</at.Title>
            <at.Description>PNG · 820 KB</at.Description>
          </at.Content>
          <at.Actions>
            <at.Action aria-label="Remove workspace.png"><Icon @icon={{X}} /></at.Action>
          </at.Actions>
        </Attachment>
        <Attachment @orientation="vertical" @name="bare" as |at|>
          <at.Media @variant="image"><img src={{IMAGE}} alt="Desk" /></at.Media>
        </Attachment>
      </template>,
    )
    const image = new AttachmentHarness('image')
    assert.strictEqual(image.orientation, 'vertical')
    assert.strictEqual(image.mediaVariant, 'image')
    assert.strictEqual(image.imageAlt, 'Workspace')
    const root = getComputedStyle(image.element)
    assert.strictEqual(root.flexDirection, 'column', 'flex-col')
    assert.strictEqual(root.width, '120px', 'with content: w-30')
    assert.strictEqual(
      getComputedStyle(new AttachmentHarness('bare').element).width,
      '96px',
      'media alone: w-24',
    )
    const media = image.media.getBoundingClientRect()
    const content = image.content.getBoundingClientRect()
    assert.true(media.bottom <= content.top + 1, 'the media is above the content')
    const photo = getComputedStyle(image.image!)
    assert.strictEqual(photo.objectFit, 'cover', 'object-cover')
    assert.strictEqual(px(photo.width), px(photo.height), 'aspect-square')

    const actions = getComputedStyle(image.actionsElement)
    assert.strictEqual(actions.position, 'absolute')
    assert.strictEqual(actions.top, '12px', 'top-3')
    assert.strictEqual(actions.insetInlineEnd, '12px', 'end-3')
    assert.strictEqual(actions.zIndex, '20', 'above a trigger')
    await a11yAudit()
  })

  test('each state renders, and the style sheet shows it', async function (assert) {
    await render(
      <template>
        <div style="width: 384px; display: flex; flex-direction: column; gap: 8px">
          {{#each STATES as |state|}}
            <Attachment @state={{state}} @name={{state}} style="width: 100%" as |at|>
              <at.Media><Icon @icon={{FileText}} /></at.Media>
              <at.Content>
                <at.Title>{{state}}.pdf</at.Title>
                <at.Description>The {{state}} state</at.Description>
              </at.Content>
            </Attachment>
          {{/each}}
          <Attachment @state="uploading" @orientation="vertical" @name="image-uploading" as |at|>
            <at.Media @variant="image"><img src={{IMAGE}} alt="Uploading" /></at.Media>
          </Attachment>
          <Attachment @orientation="vertical" @name="image-done" as |at|>
            <at.Media @variant="image"><img src={{IMAGE}} alt="Done" /></at.Media>
          </Attachment>
        </div>
      </template>,
    )
    const root = (name: string) => getComputedStyle(new AttachmentHarness(name).element)
    const title = (name: string) => getComputedStyle(new AttachmentHarness(name).titleElement)
    for (const state of STATES) {
      assert.strictEqual(new AttachmentHarness(state).state, state)
    }
    assert.strictEqual(root('idle').borderTopStyle, 'dashed', 'idle: border-dashed')
    assert.strictEqual(root('done').borderTopStyle, 'solid')
    assert.notStrictEqual(
      root('error').borderTopColor,
      root('done').borderTopColor,
      'error: border-destructive/30',
    )
    const errorMedia = getComputedStyle(new AttachmentHarness('error').media)
    const doneMedia = getComputedStyle(new AttachmentHarness('done').media)
    assert.notStrictEqual(
      errorMedia.backgroundColor,
      doneMedia.backgroundColor,
      'bg-destructive/10',
    )
    assert.notStrictEqual(errorMedia.color, doneMedia.color, 'text-destructive')
    assert.notStrictEqual(
      getComputedStyle(new AttachmentHarness('error').descriptionElement).color,
      getComputedStyle(new AttachmentHarness('done').descriptionElement).color,
      'text-destructive/80',
    )
    for (const busy of ['uploading', 'processing']) {
      assert.true(new AttachmentHarness(busy).isBusy)
      assert.strictEqual(title(busy).animationName, 'tw-shimmer', `${busy}: the title shimmers`)
    }
    for (const still of ['idle', 'error', 'done']) {
      assert.false(new AttachmentHarness(still).isBusy)
      assert.strictEqual(title(still).animationName, 'none', `${still}: no shimmer`)
    }
    assert.true(new AttachmentHarness('error').isError)
    const opacity = (name: string) => getComputedStyle(new AttachmentHarness(name).media).opacity
    assert.strictEqual(opacity('image-uploading'), '0.6', 'an uploading image is dimmed')
    assert.strictEqual(opacity('image-done'), '1')
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_ERROR_TEXT, { runOnly: ['color-contrast'] })
  })

  test('@state, @size and @orientation update in place', async function (assert) {
    class State {
      @tracked state: AttachmentState = 'uploading'
      @tracked size: AttachmentSize = 'default'
      @tracked orientation: AttachmentOrientation = 'horizontal'
    }
    const current = new State()
    await render(
      <template>
        <Attachment
          @state={{current.state}}
          @size={{current.size}}
          @orientation={{current.orientation}}
          as |at|
        >
          <at.Media><Spinner /></at.Media>
          <at.Content><at.Title>design-system.zip</at.Title></at.Content>
        </Attachment>
      </template>,
    )
    const attachment = new AttachmentHarness()
    assert.strictEqual(attachment.state, 'uploading')
    current.state = 'done'
    current.size = 'xs'
    current.orientation = 'vertical'
    await settled()
    assert.strictEqual(attachment.state, 'done')
    assert.strictEqual(attachment.size, 'xs')
    assert.strictEqual(attachment.orientation, 'vertical')
    assert
      .dom(attachment.element)
      .hasClass('jn-attachment-size-xs')
      .hasClass('jn-attachment-orientation-vertical')
      .doesNotHaveClass('jn-attachment-size-default')
    await a11yAudit()
  })

  test('actions are Buttons: they take a variant and size, and a click', async function (assert) {
    let retried = 0
    const retry = () => retried++
    await render(
      <template>
        <Attachment @state="error" as |at|>
          <at.Media><Icon @icon={{FileText}} /></at.Media>
          <at.Content>
            <at.Title>financial-model.xlsx</at.Title>
            <at.Description>Upload failed. Try again.</at.Description>
          </at.Content>
          <at.Actions>
            <at.Action aria-label="Retry upload" {{on "click" retry}}>
              <Icon @icon={{RefreshCw}} />
            </at.Action>
            <at.Action
              @variant="secondary"
              @size="icon-sm"
              @name="remove"
              type="button"
              aria-label="Remove financial-model.xlsx"
            ><Icon @icon={{X}} /></at.Action>
          </at.Actions>
        </Attachment>
      </template>,
    )
    const attachment = new AttachmentHarness()
    assert.deepEqual(attachment.actionLabels, ['Retry upload', 'Remove financial-model.xlsx'])
    await attachment.action('Retry upload').click()
    assert.strictEqual(retried, 1)
    const remove = new ButtonHarness('remove')
    assert.strictEqual(remove.variant, 'secondary')
    assert.strictEqual(remove.size, 'icon-sm')
    assert.dom(remove.element).hasAttribute('type', 'button')
    assert.strictEqual(getComputedStyle(remove.element).width, '28px', 'icon-sm: size-7')
    assert.strictEqual(
      getComputedStyle(attachment.action('Retry upload').element).width,
      '24px',
      'icon-xs: size-6',
    )
    assert.throws(() => attachment.action('Download'), /no action "Download"/)
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_ERROR_TEXT, { runOnly: ['color-contrast'] })
  })

  test('the trigger covers the card, below its actions: both stay clickable', async function (assert) {
    let opened = 0
    let removed = 0
    const open = () => opened++
    const remove = () => removed++
    await render(
      <template>
        <div style="width: 384px">
          <Attachment style="width: 100%" as |at|>
            <at.Media><Icon @icon={{FileText}} /></at.Media>
            <at.Content>
              <at.Title>research-summary.pdf</at.Title>
              <at.Description>Open preview dialog</at.Description>
            </at.Content>
            <at.Actions>
              <at.Action aria-label="Remove research-summary.pdf" {{on "click" remove}}>
                <Icon @icon={{X}} />
              </at.Action>
            </at.Actions>
            <at.Trigger aria-label="Preview research-summary.pdf" {{on "click" open}} />
          </Attachment>
        </div>
      </template>,
    )
    const attachment = new AttachmentHarness()
    const trigger = getComputedStyle(attachment.trigger)
    assert.strictEqual(trigger.position, 'absolute', 'absolute inset-0')
    assert.strictEqual(trigger.zIndex, '10', 'z-10, below the actions')
    assert.strictEqual(
      attachment.trigger.offsetWidth,
      attachment.element.clientWidth,
      'it fills the card across',
    )
    assert.strictEqual(attachment.trigger.offsetHeight, attachment.element.clientHeight, 'and down')
    assert.strictEqual(
      hitAt(attachment.titleElement),
      attachment.trigger,
      'a press on the title opens it',
    )
    const action = attachment.action('Remove research-summary.pdf').element
    assert.true(action.contains(hitAt(action)), 'a press on an action hits the action')

    await attachment.open()
    assert.strictEqual(opened, 1)
    await attachment.action('Remove research-summary.pdf').click()
    assert.strictEqual(removed, 1)
    assert.strictEqual(opened, 1, 'the action does not open it')
    await a11yAudit()
  })

  test('keyboard: Tab reaches each action, then the trigger, and Enter presses it', async function (assert) {
    let opened = 0
    const open = () => opened++
    await render(
      <template>
        <Attachment as |at|>
          <at.Media><Icon @icon={{FileText}} /></at.Media>
          <at.Content><at.Title>research-summary.pdf</at.Title></at.Content>
          <at.Actions>
            <at.Action aria-label="Copy link"><Icon @icon={{FileText}} /></at.Action>
            <at.Action aria-label="Remove research-summary.pdf"><Icon @icon={{X}} /></at.Action>
          </at.Actions>
          <at.Trigger aria-label="Preview research-summary.pdf" {{on "click" open}} />
        </Attachment>
      </template>,
    )
    const attachment = new AttachmentHarness()
    const [copy, remove] = attachment.actions
    await tab()
    assert.dom(copy!.element).isFocused()
    await tab()
    assert.dom(remove!.element).isFocused()
    await tab()
    assert.dom(attachment.trigger).isFocused('the trigger, last')
    assert.notStrictEqual(
      getComputedStyle(attachment.element).boxShadow,
      'none',
      'focus-within: the card shows a ring',
    )
    // A native <button>: the browser presses it on Enter and Space, which a test can't send.
    assert.dom(attachment.trigger).hasTagName('button')
    await click(attachment.trigger)
    assert.strictEqual(opened, 1)
    await a11yAudit()
  })

  test('the trigger as a link, and as a dialog trigger', async function (assert) {
    await render(
      <template>
        <Attachment @orientation="vertical" @name="link" as |at|>
          <at.Media @variant="image"><img src={{IMAGE}} alt="Workspace" /></at.Media>
          <at.Trigger
            @as="a"
            href="#workspace"
            target="_blank"
            rel="noreferrer"
            aria-label="Open workspace.png"
          />
        </Attachment>
        <Dialog @name="preview" as |d|>
          <Attachment @name="dialog" as |at|>
            <at.Media><Icon @icon={{FileText}} /></at.Media>
            <at.Content><at.Title>research-summary.pdf</at.Title></at.Content>
            <at.Trigger aria-label="Preview research-summary.pdf" {{d.trigger}} />
          </Attachment>
          <d.Content>
            <d.Header>
              <d.Title>research-summary.pdf</d.Title>
              <d.Description>A preview of the file.</d.Description>
            </d.Header>
          </d.Content>
        </Dialog>
      </template>,
    )
    const link = new AttachmentHarness('link')
    assert.dom(link.trigger).hasTagName('a').doesNotHaveAttribute('type')
    assert.strictEqual(link.href, '#workspace')
    assert.strictEqual(link.triggerLabel, 'Open workspace.png')

    const withDialog = new AttachmentHarness('dialog')
    const dialog = new DialogHarness('preview')
    assert.dom(withDialog.trigger).hasAttribute('aria-haspopup', 'dialog')
    assert.false(dialog.isOpen)
    await withDialog.open()
    assert.true(dialog.isOpen, 'the trigger opens the dialog')
    await dialog.close()
    assert.dom(withDialog.trigger).isFocused('focus goes back to the card')
    await a11yAudit()
  })

  test('the modifiers render what the components do', async function (assert) {
    await render(
      <template>
        <Attachment @name="components" as |at|>
          <at.Media @variant="image"><img src={{IMAGE}} alt="Workspace" /></at.Media>
          <at.Content><at.Title>a</at.Title><at.Description>b</at.Description></at.Content>
          <at.Actions><at.Action aria-label="Remove">x</at.Action></at.Actions>
          <at.Trigger aria-label="Open" />
        </Attachment>
        <Attachment @name="modifiers" as |at|>
          <figure {{at.media variant="image"}}><img src={{IMAGE}} alt="Workspace" /></figure>
          <div {{at.content}}><b {{at.title}}>a</b><i {{at.description}}>b</i></div>
          <div {{at.actions}}><button
              type="button"
              {{at.action}}
              aria-label="Remove"
            >x</button></div>
          <a href="#open" {{at.trigger}} aria-label="Open"></a>
        </Attachment>
      </template>,
    )
    const components = new AttachmentHarness('components')
    const modifiers = new AttachmentHarness('modifiers')
    const describe = (element: HTMLElement) => ({
      classes: [...element.classList].sort(),
      slot: element.getAttribute('data-slot'),
      part: element.getAttribute('data-test-jn-part'),
      variant: element.getAttribute('data-variant'),
      size: element.getAttribute('data-size'),
    })
    for (const read of [
      (h: AttachmentHarness) => h.media,
      (h: AttachmentHarness) => h.content,
      (h: AttachmentHarness) => h.titleElement,
      (h: AttachmentHarness) => h.descriptionElement,
      (h: AttachmentHarness) => h.actionsElement,
      (h: AttachmentHarness) => h.actions[0]!.element,
      (h: AttachmentHarness) => h.trigger,
    ]) {
      assert.deepEqual(describe(read(modifiers)), describe(read(components)))
    }
    assert.strictEqual(modifiers.title, 'a')
    assert.deepEqual(modifiers.actionLabels, ['Remove'])
    await a11yAudit()
  })

  test('every part takes @as', async function (assert) {
    await render(
      <template>
        <ul>
          <Attachment @as="li" as |at|>
            <at.Media @as="figure"><Icon @icon={{FileText}} /></at.Media>
            <at.Content @as="section">
              <at.Title @as="strong">notes.txt</at.Title>
              <at.Description @as="small">TXT · 1 KB</at.Description>
            </at.Content>
            <at.Actions @as="span">
              <at.Action @as="a" href="#download" aria-label="Download">d</at.Action>
            </at.Actions>
          </Attachment>
        </ul>
      </template>,
    )
    const attachment = new AttachmentHarness()
    assert.dom(attachment.element).hasTagName('li')
    assert.dom(attachment.media).hasTagName('figure')
    assert.dom(attachment.content).hasTagName('section')
    assert.dom(attachment.titleElement).hasTagName('strong')
    assert.dom(attachment.descriptionElement).hasTagName('small')
    assert.dom(attachment.actionsElement).hasTagName('span')
    assert.dom(attachment.actions[0]!.element).hasTagName('a').hasAttribute('href', '#download')
    await a11yAudit()
  })

  test('a group lays attachments out in a row that scrolls across and snaps', async function (assert) {
    const NAMES = ['briefing-notes.pdf', 'workspace.png', 'customers.csv', 'renderer.tsx']
    await render(
      <template>
        <div style="width: 384px">
          <AttachmentGroup style="width: 100%">
            {{#each NAMES as |name|}}
              <Attachment style="width: 256px" as |at|>
                <at.Media><Icon @icon={{FileText}} /></at.Media>
                <at.Content><at.Title>{{name}}</at.Title></at.Content>
                <at.Actions>
                  <at.Action aria-label="Remove {{name}}"><Icon @icon={{X}} /></at.Action>
                </at.Actions>
              </Attachment>
            {{/each}}
          </AttachmentGroup>
        </div>
      </template>,
    )
    const group = new AttachmentGroupHarness()
    assert
      .dom(group.element)
      .hasClass('jn-attachment-group')
      .hasAttribute('data-slot', 'attachment-group')
    assert.deepEqual(group.titles, NAMES)
    const style = getComputedStyle(group.element)
    assert.strictEqual(style.display, 'flex')
    assert.strictEqual(style.overflowX, 'auto', 'overflow-x-auto')
    assert.strictEqual(style.scrollSnapType, 'x mandatory', 'snap-x snap-mandatory')
    assert.strictEqual(style.scrollbarWidth, 'none', 'scrollbar-none')
    assert.strictEqual(style.overscrollBehaviorX, 'contain')
    assert.strictEqual(style.columnGap, '12px', 'gap-3')
    const [first] = group.attachments
    const item = getComputedStyle(first!.element)
    assert.strictEqual(item.flexShrink, '0', 'flex-none')
    assert.strictEqual(item.scrollSnapAlign, 'start', 'snap-start')
    assert.strictEqual(item.width, '256px', 'its own width: it does not shrink')
    assert.true(group.isScrollable)
    assert.strictEqual(group.scrollOffset, 0)

    // Tabbing to an attachment out of sight scrolls the row to it.
    const last = group.attachments.at(-1)!
    await last.actions[0]!.focus()
    await settled()
    assert.true(group.scrollOffset > 0, 'the row scrolled to the focused action')
    await a11yAudit()
  })

  test('RTL: the media sits on the right, and a vertical card has its actions at the top left', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <div style="width: 384px; display: flex; flex-direction: column; gap: 12px">
            <Attachment @name="row" style="width: 100%" as |at|>
              <at.Media><Icon @icon={{FileText}} /></at.Media>
              <at.Content><at.Title>تقرير-المبيعات.pdf</at.Title></at.Content>
              <at.Actions>
                <at.Action aria-label="إزالة"><Icon @icon={{X}} /></at.Action>
              </at.Actions>
            </Attachment>
            <Attachment @orientation="vertical" @name="card" as |at|>
              <at.Media @variant="image"><img src={{IMAGE}} alt="مساحة العمل" /></at.Media>
              <at.Actions>
                <at.Action aria-label="إزالة الصورة"><Icon @icon={{X}} /></at.Action>
              </at.Actions>
            </Attachment>
          </div>
        </DirectionProvider>
      </template>,
    )
    const row = new AttachmentHarness('row')
    const media = row.media.getBoundingClientRect()
    const content = row.content.getBoundingClientRect()
    const actions = row.actionsElement.getBoundingClientRect()
    assert.true(media.left > content.right - 1, 'the media is right of the content')
    assert.true(actions.right < content.left + 1, 'the actions are left of the content')

    const card = new AttachmentHarness('card')
    const box = card.element.getBoundingClientRect()
    const corner = card.actionsElement.getBoundingClientRect()
    // end-3 from the padding box, inside its 1px border.
    assert.true(
      Math.abs(corner.left - box.left - 13 * scaleOf(card.element)) < 0.6,
      'end-3: the actions at the top left',
    )
    await a11yAudit()
  })

  test('the harness throws for a missing part, and reads what is absent as empty', async function (assert) {
    await render(
      <template>
        <Attachment @name="bare" as |at|>
          <at.Content><at.Title>bare.txt</at.Title></at.Content>
        </Attachment>
      </template>,
    )
    const bare = new AttachmentHarness('bare')
    assert.strictEqual(bare.description, '')
    assert.strictEqual(bare.mediaVariant, null)
    assert.strictEqual(bare.image, null)
    assert.false(bare.hasTrigger)
    assert.strictEqual(bare.triggerLabel, '')
    assert.strictEqual(bare.href, null)
    assert.throws(() => bare.media, /no "media" part/)
    assert.throws(() => bare.trigger, /no "trigger" part/)
    assert.throws(() => new AttachmentGroupHarness().element, /no attachment-group found/)
    await a11yAudit()
  })
})
