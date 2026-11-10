import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, rerender, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { array, hash } from '@ember/helper'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import type { Editor, JSONContent } from '@tiptap/core'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Field, FieldDescription, FieldLabel } from '@ember-joinery/ember'
import { tab } from '@ember-joinery/test-support'
import { RichTextEditor, toPlainText, type RichTextValue } from '@ember-joinery/tiptap'
import { RichTextEditorHarness } from '@ember-joinery/tiptap/test-support'

/** What a test changes between renders, and what the editor sent. */
class State {
  @tracked value: RichTextValue | undefined = undefined
  @tracked disabled = false
  @tracked readonly = false
  @tracked invalid = false
  sent: RichTextValue[] = []
  onValueChange = (value: RichTextValue) => {
    this.sent.push(value)
  }
  /** Controlled: keeps what the editor sends, as an app's tracked property does. */
  keep = (value: RichTextValue) => {
    this.sent.push(value)
    this.value = value
  }
}

const ALL_TOOLS = [
  'block-type',
  'bold',
  'italic',
  'underline',
  'strike',
  'code',
  'bullet-list',
  'ordered-list',
  'blockquote',
  'code-block',
  'undo',
  'redo',
]

const isApple = /Mac|iP(hone|[oa]d)/.test(navigator.platform)
const MOD = isApple ? 'Meta' : 'Control'

module('Integration | components | rich-text-editor', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders an Input Group with a toolbar addon above a textbox', async function (assert) {
    await render(<template><RichTextEditor @name="body" @label="Body" class="custom" /></template>)
    const body = new RichTextEditorHarness('body')

    assert
      .dom(body.element)
      .hasClass('jn-rich-text-editor')
      .hasClass('jn-input-group')
      .hasClass('group/input-group')
      .hasClass('custom', '...attributes adds a class')
      .hasAttribute('data-slot', 'rich-text-editor')
      .hasAttribute('data-test-jn', 'rich-text-editor')
      .hasAttribute('data-test-jn-name', 'body')

    const toolbar = body.toolbar!
    assert
      .dom(toolbar)
      .hasAttribute('role', 'toolbar')
      .hasAttribute('aria-label', 'Formatting')
      .hasAttribute('aria-orientation', 'horizontal')
      .hasAttribute('aria-controls', body.content.id)
      .hasAttribute('data-slot', 'rich-text-editor-toolbar')
      .hasAttribute('data-align', 'block-start')
      .hasClass('jn-input-group-addon')
      .hasClass('jn-input-group-addon-align-block-start')
      .hasClass('border-b')

    assert
      .dom(body.content)
      .hasAttribute('role', 'textbox')
      .hasAttribute('aria-multiline', 'true')
      .hasAttribute('aria-label', 'Body')
      .hasAttribute('contenteditable', 'true')
      .hasAttribute('data-slot', 'input-group-control')
      .hasClass('jn-rich-text-editor-document')
    assert
      .dom(body.content.parentElement)
      .hasAttribute('data-slot', 'rich-text-editor-content')
      .hasClass('jn-input-group-textarea')
      .hasClass('jn-textarea')

    assert.deepEqual(body.tools, ALL_TOOLS, 'every control, in its groups')
    assert.strictEqual(body.separators, 3, 'a Separator between each two groups')
    assert.dom('[data-test-jn-part="separator"]').hasAttribute('data-orientation', 'vertical')
    await a11yAudit()
  })

  test("the style sheet styles it as shadcn's input group, toggles and buttons", async function (assert) {
    await render(<template><RichTextEditor @label="Body" style="width: 640px" /></template>)
    const body = new RichTextEditorHarness()
    const root = getComputedStyle(body.element)
    assert.strictEqual(root.borderTopWidth, '1px', "the group's border")
    assert.strictEqual(root.flexDirection, 'column', 'the toolbar sits above the document')
    assert.strictEqual(getComputedStyle(body.toolbar!).borderBottomWidth, '1px')
    assert.strictEqual(getComputedStyle(body.toolbar!).flexWrap, 'wrap')
    assert.strictEqual(
      getComputedStyle(body.tool('bold')).height,
      '28px',
      "a small toggle (Nova's h-7)",
    )
    assert.strictEqual(getComputedStyle(body.tool('undo')).width, '28px', 'an icon-sm button')
    assert.strictEqual(getComputedStyle(body.tool('block-type')).height, '28px', 'a sm button')
    assert.true(
      ['pre-wrap', 'break-spaces'].includes(getComputedStyle(body.content).whiteSpace),
      'spaces and line breaks show as typed',
    )
    assert.strictEqual(
      getComputedStyle(body.content.parentElement!).minHeight,
      '64px',
      "the document's box is a textarea's (min-h-16)",
    )
    assert.strictEqual(root.boxShadow, 'none')
    await body.focus()
    assert.notStrictEqual(
      getComputedStyle(body.element).boxShadow,
      'none',
      "the group's focus ring, while the document has focus",
    )
    await a11yAudit()
  })

  test('it stores HTML, and an empty document as an empty string', async function (assert) {
    const state = new State()
    await render(
      <template>
        <RichTextEditor
          @label="Body"
          @defaultValue="<p>Hello</p>"
          @onValueChange={{state.onValueChange}}
        />
      </template>,
    )
    const body = new RichTextEditorHarness()
    assert.strictEqual(body.html, '<p>Hello</p>', 'it starts with @defaultValue')
    assert.strictEqual(body.text, 'Hello')

    await body.typeText(' world')
    assert.deepEqual(state.sent, ['<p>Hello world</p>'])

    await body.setContent('')
    assert.strictEqual(state.sent.at(-1), '', 'an empty document stores ""')
    assert.true(body.isEmpty)

    await body.setContent('<ul><li><p>One</p></li></ul>')
    assert.strictEqual(
      state.sent.at(-1),
      '<ul><li><p>One</p></li></ul>',
      'the empty paragraph after a last list is not stored',
    )
    await a11yAudit()
  })

  test('with @output="json" it stores Tiptap\'s JSON, and an empty document as null', async function (assert) {
    const state = new State()
    await render(
      <template>
        <RichTextEditor @label="Body" @output="json" @onValueChange={{state.onValueChange}} />
      </template>,
    )
    const body = new RichTextEditorHarness()
    await body.typeText('Looks good')
    assert.deepEqual(state.sent.at(-1), {
      type: 'doc',
      content: [{ type: 'paragraph', content: [{ type: 'text', text: 'Looks good' }] }],
    })
    await body.setContent('')
    assert.strictEqual(state.sent.at(-1), null)
    await a11yAudit()
  })

  test('controlled, a new @value replaces the document without a change; its own value back changes nothing', async function (assert) {
    const state = new State()
    state.value = '<p>First</p>'
    await render(
      <template>
        <RichTextEditor @label="Body" @value={{state.value}} @onValueChange={{state.keep}} />
      </template>,
    )
    const body = new RichTextEditorHarness()
    assert.strictEqual(body.html, '<p>First</p>')

    await body.moveCursor('end')
    await body.typeText('!')
    assert.deepEqual(state.sent, ['<p>First!</p>'])
    assert.strictEqual(state.value, '<p>First!</p>')
    assert.strictEqual(body.html, '<p>First!</p>', 'its own value, back, leaves the document be')

    state.value = '<h2>Reset</h2>'
    await rerender()
    assert.strictEqual(body.html, '<h2>Reset</h2>', 'a value from outside replaces it')
    assert.strictEqual(state.sent.length, 1, '...without a change')

    state.value = ''
    await rerender()
    assert.true(body.isEmpty)
    await a11yAudit()
  })

  test('the toggles turn marks and blocks on and off, and read them at the cursor', async function (assert) {
    const state = new State()
    await render(
      <template>
        <RichTextEditor
          @label="Body"
          @defaultValue="<p>Shipping today</p>"
          @onValueChange={{state.onValueChange}}
        />
      </template>,
    )
    const body = new RichTextEditorHarness()
    const bold = body.tool('bold')
    assert
      .dom(bold)
      .hasAttribute('aria-pressed', 'false')
      .hasAttribute('data-state', 'off')
      .hasAttribute('aria-label', 'Bold')
      .hasAttribute('aria-keyshortcuts', `${MOD}+B`)
      .hasClass('jn-toggle-group-item')
      .hasClass('jn-toggle')
      .hasClass('jn-toggle-size-sm')

    await body.selectAll()
    await body.press('bold')
    assert.true(body.isActive('bold'), 'bold')
    assert.dom(bold).hasAttribute('data-state', 'on')
    assert.strictEqual(state.sent.at(-1), '<p><strong>Shipping today</strong></p>')
    assert.true(body.isFocused, 'a press keeps the document focused, with its selection')

    await body.press('italic')
    await body.press('underline')
    await body.press('strike')
    assert.deepEqual(body.active, ['bold', 'italic', 'underline', 'strike'])
    assert.strictEqual(body.html, '<p><strong><em><s><u>Shipping today</u></s></em></strong></p>')
    await body.press('bold')
    assert.false(body.isActive('bold'))

    await body.press('bullet-list')
    await body.moveCursor('start')
    assert.true(body.isActive('bullet-list'), 'a bulleted list, at the cursor')
    assert.strictEqual(body.html, '<ul><li><p><em><s><u>Shipping today</u></s></em></p></li></ul>')
    await body.press('ordered-list')
    assert.deepEqual(
      body.active.filter(tool => tool.endsWith('list')),
      ['ordered-list'],
      'one list at a time',
    )
    await body.press('ordered-list')
    await body.press('blockquote')
    assert.true(body.isActive('blockquote'), 'a quote')
    await body.press('blockquote')

    await body.setContent('<p>let x</p>')
    await body.selectAll()
    await body.press('code')
    assert.strictEqual(body.html, '<p><code>let x</code></p>')
    await body.press('code')
    await body.press('code-block')
    assert.strictEqual(body.html, '<pre><code>let x</code></pre>')
    await body.moveCursor('start')
    assert.true(body.isActive('code-block'), 'a code block, at the cursor')
    assert.strictEqual(body.blockType, 'Text style', 'a code block has no text style')
    await a11yAudit()
  })

  test('undo and redo, aria-disabled with nothing to undo or redo', async function (assert) {
    await render(<template><RichTextEditor @label="Body" /></template>)
    const body = new RichTextEditorHarness()
    assert.true(body.isToolDisabled('undo'), 'nothing to undo yet')
    assert.dom(body.tool('undo')).hasAttribute('aria-disabled', 'true').isNotDisabled()
    assert.true(body.isToolDisabled('redo'))

    await body.typeText('Draft')
    assert.false(body.isToolDisabled('undo'))
    assert.dom(body.tool('undo')).doesNotHaveAttribute('aria-disabled')
    await body.press('undo')
    assert.true(body.isEmpty)
    assert.false(body.isToolDisabled('redo'))
    await body.press('redo')
    assert.strictEqual(body.text, 'Draft')

    await body.press('redo')
    assert.strictEqual(body.text, 'Draft', 'a press with nothing to redo does nothing')
    await a11yAudit()
  })

  test('the text style menu sets a paragraph or a heading, and shows the one at the cursor', async function (assert) {
    await render(
      <template>
        <RichTextEditor @label="Body" @defaultValue="<p>Release notes</p>" />
      </template>,
    )
    const body = new RichTextEditorHarness()
    assert.strictEqual(body.blockType, 'Paragraph')
    assert.dom(body.tool('block-type')).hasAttribute('aria-label', 'Text style: Paragraph')

    assert.deepEqual(await body.blockTypes(), ['Paragraph', 'Heading 1', 'Heading 2', 'Heading 3'])
    await body.moveCursor('end')
    await body.setBlockType('Heading 2')
    assert.strictEqual(body.html, '<h2>Release notes</h2>')
    assert.strictEqual(body.blockType, 'Heading 2')
    assert.dom(body.tool('block-type')).hasAttribute('aria-label', 'Text style: Heading 2')
    assert.true(body.isFocused, 'after a choice, focus goes back to the document')

    const menu = body.blockTypeMenu
    await menu.open()
    assert.true(menu.isChecked('Heading 2'), 'the menu checks the style at the cursor')
    assert.strictEqual(menu.shortcut('Heading 2'), isApple ? '⌘⌥2' : 'CtrlAlt2')
    await menu.pressEscape()
    assert.dom(body.tool('block-type')).isFocused('Escape sends focus back to the trigger')

    await body.setBlockType('Paragraph')
    assert.strictEqual(body.html, '<p>Release notes</p>')
    await a11yAudit()
  })

  test('@headingLevels picks the headings the menu offers', async function (assert) {
    await render(
      <template><RichTextEditor @label="Body" @headingLevels={{array 2 3 4}} /></template>,
    )
    const body = new RichTextEditorHarness()
    assert.deepEqual(await body.blockTypes(), ['Paragraph', 'Heading 2', 'Heading 3', 'Heading 4'])
    await body.setBlockType('Heading 4')
    assert.strictEqual(body.blockType, 'Heading 4')
    await body.setContent('<h1>Pasted</h1>')
    assert.strictEqual(body.blockType, 'Heading 1', 'a level it does not offer is still named')
    await a11yAudit()
  })

  test("WAI-ARIA's toolbar pattern: one tab stop, the arrow keys, Home and End", async function (assert) {
    await render(
      <template>
        <button type="button">Before</button>
        <RichTextEditor @label="Body" @defaultValue="<p>Hello</p>" />
      </template>,
    )
    const body = new RichTextEditorHarness()
    await click('button')
    await tab()
    assert.strictEqual(body.focusedTool, 'block-type', 'Tab enters on the first control')

    await body.pressKey('ArrowRight')
    assert.strictEqual(body.focusedTool, 'bold', 'the arrows cross from group to group')
    await body.pressKey('ArrowRight')
    assert.strictEqual(body.focusedTool, 'italic')
    await body.pressKey('End')
    assert.strictEqual(body.focusedTool, 'redo')
    await body.pressKey('ArrowRight')
    assert.strictEqual(body.focusedTool, 'block-type', 'and wrap round')
    await body.pressKey('ArrowLeft')
    assert.strictEqual(body.focusedTool, 'redo')
    await body.pressKey('Home')
    assert.strictEqual(body.focusedTool, 'block-type')

    await body.focusTool('italic')
    assert.strictEqual(body.tabStop, 'italic', 'the tab stop follows focus')
    await tab()
    assert.true(body.isFocused, 'Tab leaves the toolbar for the document')
    await tab({ shift: true })
    assert.strictEqual(body.focusedTool, 'italic', 'and Shift+Tab comes back to where it was')

    await body.selectAll()
    await body.focusTool('bold')
    assert.strictEqual(body.focusedTool, 'bold')
    // Space or Enter on a focused button is a click, which a test sends as one.
    await click(body.tool('bold'))
    assert.strictEqual(body.focusedTool, 'bold', 'a toggle pressed from the toolbar keeps focus')
    assert.true(body.isActive('bold'), 'and applies to the selection')
    assert.strictEqual(body.html, '<p><strong>Hello</strong></p>')
    await a11yAudit()
  })

  test("the keyboard shortcuts are Tiptap's, and the toggles follow them", async function (assert) {
    await render(
      <template>
        <RichTextEditor @label="Body" @defaultValue="<p>Hi</p>" />
      </template>,
    )
    const body = new RichTextEditorHarness()
    await body.selectAll()
    await body.pressShortcut('b')
    assert.true(body.isActive('bold'))
    await body.pressShortcut('i')
    assert.true(body.isActive('italic'))
    await body.pressShortcut('z')
    assert.false(body.isActive('italic'), 'undo')
    assert.strictEqual(body.toolShortcut('strike'), `${MOD}+Shift+S`)
    assert.strictEqual(body.toolShortcut('redo'), `${MOD}+Shift+Z`)
    await a11yAudit()
  })

  test('each control has a tooltip with its name and shortcut, and a toggle keeps its state under it', async function (assert) {
    await render(
      <template>
        <RichTextEditor @label="Body" @defaultValue="<p><strong>Hi</strong></p>" />
      </template>,
    )
    const body = new RichTextEditorHarness()
    await body.moveCursor('end')
    assert.true(body.isActive('bold'))

    await body.hoverTool('bold')
    assert.strictEqual(body.tooltip('bold'), isApple ? 'Bold ⌘ B' : 'Bold Ctrl B')
    assert
      .dom(body.tool('bold'))
      .hasAttribute('data-state', 'on', "the toggle's state, not the tooltip's")
      .hasAttribute('aria-pressed', 'true')
    assert.dom('[data-slot="tooltip-content"] [data-slot="kbd"]').exists({ count: 2 })
    await body.unhoverTool('bold')
    assert.strictEqual(body.tooltip('bold'), '')
    assert.dom(body.tool('bold')).hasAttribute('data-state', 'on')

    await body.hoverTool('undo')
    assert.strictEqual(body.tooltip('undo'), isApple ? 'Undo ⌘ Z' : 'Undo Ctrl Z')
    await body.unhoverTool('undo')
    await a11yAudit()
  })

  test('@toolbar picks the controls; false hides the toolbar', async function (assert) {
    const tools = ['bold', 'italic', 'bullet-list'] as const
    await render(
      <template>
        <RichTextEditor @name="comment" @label="Comment" @toolbar={{tools}} />
        <RichTextEditor @name="plain" @label="Plain" @toolbar={{false}} />
      </template>,
    )
    const comment = new RichTextEditorHarness('comment')
    assert.deepEqual(comment.tools, ['bold', 'italic', 'bullet-list'])
    assert.strictEqual(comment.separators, 1)

    const plain = new RichTextEditorHarness('plain')
    assert.strictEqual(plain.toolbar, null)
    assert.deepEqual(plain.tools, [])
    assert.strictEqual(getComputedStyle(plain.element).flexDirection, 'column')
    assert.true(plain.element.getBoundingClientRect().height > 32, 'it still grows')
    await a11yAudit()
  })

  test('disabled, it can neither be edited nor focused, and its toolbar is disabled', async function (assert) {
    const state = new State()
    state.disabled = true
    await render(
      <template>
        <RichTextEditor @label="Body" @defaultValue="<p>Hi</p>" @disabled={{state.disabled}} />
      </template>,
    )
    const body = new RichTextEditorHarness()
    assert.true(body.isDisabled)
    assert.false(body.isEditable)
    assert.dom(body.element).hasAttribute('data-disabled', 'true')
    for (const tool of body.tools) assert.true(body.isToolDisabled(tool), `${tool} is disabled`)
    assert.dom(body.tool('bold')).isDisabled()
    assert.dom(body.toolbar).hasAttribute('tabindex', '-1', 'Tab skips the toolbar')
    assert.strictEqual(getComputedStyle(body.element).opacity, '0.5')

    state.disabled = false
    await rerender()
    assert.false(body.isDisabled)
    assert.true(body.isEditable)
    assert.dom(body.tool('bold')).isNotDisabled()
    await a11yAudit()
  })

  test('read-only, it shows the document without a toolbar', async function (assert) {
    const state = new State()
    state.readonly = true
    await render(
      <template>
        <RichTextEditor @label="Body" @defaultValue="<p>Hi</p>" @readonly={{state.readonly}} />
      </template>,
    )
    const body = new RichTextEditorHarness()
    assert.true(body.isReadonly)
    assert.false(body.isEditable)
    assert.strictEqual(body.toolbar, null)

    state.readonly = false
    await rerender()
    assert.true(body.isEditable)
    assert.deepEqual(body.tools, ALL_TOOLS)
    await a11yAudit()
  })

  test('a FieldLabel names it, a press on the label focuses it, and @describedBy describes it', async function (assert) {
    await render(
      <template>
        <Field>
          <FieldLabel for="post-body">Body</FieldLabel>
          <RichTextEditor @id="post-body" @describedBy="post-body-hint" />
          <FieldDescription id="post-body-hint">Markdown shortcuts work too.</FieldDescription>
        </Field>
      </template>,
    )
    const body = new RichTextEditorHarness()
    assert.strictEqual(body.content.id, 'post-body')
    assert.strictEqual(body.label, 'Body')
    assert.dom(body.content).hasAttribute('aria-labelledby', 'post-body-label')
    assert.strictEqual(body.description, 'Markdown shortcuts work too.')

    await click('label')
    assert.true(body.isFocused)
    await a11yAudit()
  })

  test('the placeholder shows while the document is empty, and @invalid and @required are announced', async function (assert) {
    const state = new State()
    state.invalid = true
    await render(
      <template>
        <RichTextEditor
          @label="Comment"
          @placeholder="Leave a comment"
          @invalid={{state.invalid}}
          @required={{true}}
        />
      </template>,
    )
    const body = new RichTextEditorHarness()
    assert.strictEqual(body.placeholder, 'Leave a comment')
    assert.true(body.isEmpty)
    assert.strictEqual(getComputedStyle(body.content, '::before').content, '"Leave a comment"')
    assert.dom(body.content).hasAttribute('aria-required', 'true')
    assert.true(body.isInvalid)
    const destructive = getComputedStyle(body.element).borderTopColor
    state.invalid = false
    await rerender()
    assert.notStrictEqual(
      getComputedStyle(body.element).borderTopColor,
      destructive,
      'invalid, the border is --destructive',
    )

    await body.typeText('Hi')
    assert.false(body.isEmpty)
    assert.strictEqual(getComputedStyle(body.content, '::before').content, 'none')
    await a11yAudit()
  })

  test('every string is an argument', async function (assert) {
    const labels = {
      toolbar: 'Mise en forme',
      blockType: 'Style',
      paragraph: 'Paragraphe',
      heading: (level: number) => `Titre ${level}`,
      bold: 'Gras',
      undo: 'Annuler',
    }
    await render(<template><RichTextEditor @label="Texte" @labels={{labels}} /></template>)
    const body = new RichTextEditorHarness()
    assert.strictEqual(body.toolbarLabel, 'Mise en forme')
    assert.strictEqual(body.toolLabel('bold'), 'Gras')
    assert.strictEqual(body.toolLabel('italic'), 'Italic', 'the rest keep their English')
    assert.strictEqual(body.toolLabel('undo'), 'Annuler')
    assert.strictEqual(body.blockType, 'Paragraphe')
    assert.strictEqual(body.toolLabel('block-type'), 'Style: Paragraphe')
    assert.deepEqual(await body.blockTypes(), ['Paragraphe', 'Titre 1', 'Titre 2', 'Titre 3'])
    await a11yAudit()
  })

  test('right to left, the arrow keys flip and the document runs from the right', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <div dir="rtl">
            <RichTextEditor @label="المحتوى" @placeholder="اكتب شيئًا" style="width: 640px" />
          </div>
        </DirectionProvider>
      </template>,
    )
    const body = new RichTextEditorHarness()
    assert.strictEqual(getComputedStyle(body.content).direction, 'rtl')
    const bold = body.tool('bold').getBoundingClientRect()
    const italic = body.tool('italic').getBoundingClientRect()
    assert.true(italic.right <= bold.left, 'the controls run right to left')

    await body.focusTool('bold')
    await body.pressKey('ArrowLeft')
    assert.strictEqual(body.focusedTool, 'italic', 'the left arrow moves forward')
    await body.pressKey('ArrowRight')
    assert.strictEqual(body.focusedTool, 'bold')

    const placeholder = getComputedStyle(body.content, '::before')
    assert.strictEqual(placeholder.content, '"اكتب شيئًا"')
    await a11yAudit()
  })

  test('@extensions and @starterKit configure Tiptap, and @onCreate hands over the editor', async function (assert) {
    let created: Editor | undefined
    const onCreate = (editor: Editor) => (created = editor)
    const starterKit = { heading: { levels: [2] as (1 | 2 | 3 | 4 | 5 | 6)[] } }
    await render(
      <template>
        <RichTextEditor
          @label="Body"
          @starterKit={{starterKit}}
          @headingLevels={{array 2}}
          @onCreate={{onCreate}}
        />
      </template>,
    )
    const body = new RichTextEditorHarness()
    assert.strictEqual(created, body.editor, 'the harness reaches the same editor')
    await body.setContent('<h1>One</h1>')
    assert.strictEqual(body.html, '<p>One</p>', 'StarterKit was told to take level 2 only')
    await a11yAudit()
  })

  test('the harness reads the document as HTML, JSON and text', async function (assert) {
    await render(
      <template>
        <RichTextEditor @name="post" @label="Post" @defaultValue="<h2>Hi</h2><p>there</p>" />
      </template>,
    )
    const post = new RichTextEditorHarness('post')
    assert.strictEqual(post.html, '<h2>Hi</h2><p>there</p>')
    assert.strictEqual(post.text, 'Hi\n\nthere')
    const json: JSONContent = post.json
    assert.strictEqual(json.content?.[0]?.type, 'heading')
    assert.false(post.isFocused)
    await post.focus()
    assert.true(post.isFocused)
    await post.blur()
    assert.false(post.isFocused)
    assert.strictEqual(post.label, 'Post')
    await settled()
    await a11yAudit()
  })

  test('toPlainText reads HTML and JSON alike', async function (assert) {
    assert.strictEqual(toPlainText('<h2>Hi</h2><p>there <strong>you</strong></p>'), 'Hi there you')
    assert.strictEqual(toPlainText(''), '')
    assert.strictEqual(toPlainText(null), '')
    assert.strictEqual(
      toPlainText({
        type: 'doc',
        content: [
          { type: 'paragraph', content: [{ type: 'text', text: 'a' }] },
          { type: 'paragraph', content: [{ type: 'text', text: 'b' }] },
        ],
      }),
      'a b',
    )
    await render(<template><RichTextEditor @label="Body" /></template>)
    await a11yAudit()
  })

  test('the classes and attributes the toolbar renders hold with a hash of labels', async function (assert) {
    await render(
      <template><RichTextEditor @label="Body" @labels={{hash toolbar="Tools"}} /></template>,
    )
    assert.strictEqual(new RichTextEditorHarness().toolbarLabel, 'Tools')
    await a11yAudit()
  })
})
