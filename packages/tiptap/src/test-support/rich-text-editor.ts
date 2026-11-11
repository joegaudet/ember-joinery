import { blur, click, focus, settled } from '@ember/test-helpers'
import type { Editor, JSONContent } from '@tiptap/core'
import {
  DropdownMenuHarness,
  Harness,
  hover,
  pressKey,
  unhover,
  type KeyModifiers,
} from '@ember-joinery/test-support'

const collapse = (value: string | null | undefined): string =>
  (value ?? '').replace(/\s+/g, ' ').trim()

/** The text of the elements an `aria-labelledby` or `aria-describedby` names, in order. */
function textOfIds(element: Element, attribute: string): string {
  return (element.getAttribute(attribute) ?? '')
    .split(/\s+/)
    .map(id => (id ? element.ownerDocument.getElementById(id) : null))
    .filter((found): found is HTMLElement => Boolean(found))
    .map(found => collapse(found.textContent))
    .join(' ')
}

/** Where a command moves the cursor before it runs: the end, when the document isn't focused. */
type FocusPosition = 'start' | 'end' | 'all' | number | null

/**
 * Drives a `<RichTextEditor>` from `@ember-joinery/tiptap`. It reads the document (as HTML,
 * JSON or text) and its state through ARIA (`aria-disabled`, `aria-invalid`, its name), and the
 * toolbar's controls by name (`bold`, `bullet-list`, `undo`, `block-type`) through theirs
 * (`aria-pressed`, `aria-disabled`); it presses them as a user does.
 *
 *   const body = new RichTextEditorHarness('body') // <RichTextEditor @name="body">
 *   await body.typeText('Shipping today')
 *   await body.selectAll()
 *   await body.press('bold')
 *   assert.true(body.isActive('bold'))
 *   assert.strictEqual(body.html, '<p><strong>Shipping today</strong></p>')
 *   await body.setBlockType('Heading 2')
 *
 * Text goes in through Tiptap's commands, since ProseMirror doesn't type what synthetic key
 * events ask for; a keyboard shortcut (`pressShortcut('b')`) is a real key press, which
 * ProseMirror's keymaps hear.
 */
export class RichTextEditorHarness extends Harness {
  static override component = 'rich-text-editor'

  // ----- The document -------------------------------------------------------------------

  /** The editable element: the `textbox` Tiptap renders, with the `@id`. */
  get content(): HTMLElement {
    return this.part('content')
  }

  /** The Tiptap editor behind it, for anything this harness doesn't cover. */
  get editor(): Editor {
    const editor = (this.content as HTMLElement & { editor?: Editor }).editor
    if (!editor) throw new Error(`Joinery harness: no editor is mounted in ${this}`)
    return editor
  }

  /**
   * The document as HTML, as the editor stores it: Tiptap's, without the empty paragraph
   * StarterKit keeps after a last heading or list (somewhere to type, not content).
   */
  get html(): string {
    return this.editor.getHTML().replace(/(<p><\/p>)+$/, '')
  }

  /** The document as Tiptap's JSON, as Tiptap writes it (with that last empty paragraph). */
  get json(): JSONContent {
    return this.editor.getJSON()
  }

  /** The document's text, blocks separated by blank lines. */
  get text(): string {
    return this.editor.getText()
  }

  /** Whether the document is empty (one empty line), as its placeholder shows. */
  get isEmpty(): boolean {
    return this.content.hasAttribute('data-empty')
  }

  /** The placeholder an empty document shows (`aria-placeholder`). */
  get placeholder(): string | null {
    return this.content.getAttribute('aria-placeholder')
  }

  /** The document's accessible name: its `aria-label`, or what `aria-labelledby` names. */
  get label(): string {
    const label = this.content.getAttribute('aria-label')
    return label ? label.trim() : textOfIds(this.content, 'aria-labelledby')
  }

  /** What describes the document (`aria-describedby`), such as a FieldDescription. */
  get description(): string {
    return textOfIds(this.content, 'aria-describedby')
  }

  /** Whether the document can be changed now (`contenteditable`). */
  get isEditable(): boolean {
    return this.content.getAttribute('contenteditable') === 'true'
  }

  /** Whether it is disabled (`aria-disabled` on the document). */
  get isDisabled(): boolean {
    return this.content.getAttribute('aria-disabled') === 'true'
  }

  /** Whether it is read-only (`aria-readonly`). */
  get isReadonly(): boolean {
    return this.content.getAttribute('aria-readonly') === 'true'
  }

  /** Whether its value is invalid (`aria-invalid`). */
  get isInvalid(): boolean {
    return this.content.getAttribute('aria-invalid') === 'true'
  }

  /** Whether the document has focus. */
  get isFocused(): boolean {
    return this.content.contains(document.activeElement)
  }

  /** Focuses the document, as a click or Tab would. */
  async focus(): Promise<void> {
    await focus(this.content)
  }

  /** Takes focus off the document. */
  async blur(): Promise<void> {
    await blur(this.content)
  }

  /** Puts text in at the cursor, or at the end when the document isn't focused. */
  async typeText(text: string): Promise<void> {
    this.#chain(this.editor.isFocused ? null : 'end')
      .insertContent(text)
      .run()
    await settled()
  }

  /** Replaces the whole document, as a paste over all of it does; the cursor ends at the end. */
  async setContent(html: string): Promise<void> {
    this.#chain('end').setContent(html).focus('end').run()
    await settled()
  }

  /** Selects the whole document, as Ctrl+A (⌘A) does, before pressing a toggle. */
  async selectAll(): Promise<void> {
    this.#chain(null).selectAll().run()
    await settled()
  }

  /** Puts the cursor at a place in the document: `start`, `end`, or a ProseMirror position. */
  async moveCursor(to: 'start' | 'end' | number): Promise<void> {
    this.#chain(to).run()
    await settled()
  }

  /**
   * Presses a keyboard shortcut on the document, as ProseMirror's keymaps hear it: `Mod` is ⌘
   * on Apple's systems and Ctrl elsewhere, as theirs is. `pressShortcut('b')` is bold,
   * `pressShortcut('z', { shiftKey: true })` redo.
   */
  async pressShortcut(key: string, modifiers: KeyModifiers = {}): Promise<void> {
    if (!this.isFocused) await this.focus()
    const apple = /Mac|iP(hone|[oa]d)/.test(navigator.platform)
    await pressKey(key, { ...(apple ? { metaKey: true } : { ctrlKey: true }), ...modifiers })
  }

  /**
   * A command chain on the focused document. Tiptap's `focus()` waits for an animation frame
   * when the document isn't focused, which `settled()` doesn't wait for, so the view is
   * focused first, at once.
   */
  #chain(position: FocusPosition) {
    this.editor.view.focus()
    return this.editor.chain().focus(position ?? undefined)
  }

  // ----- The toolbar --------------------------------------------------------------------

  /** The toolbar, or `null` when it shows none (`@toolbar={{false}}`, or read-only). */
  get toolbar(): HTMLElement | null {
    return this.queryPart('toolbar')
  }

  /** The toolbar's accessible name (`Formatting`). */
  get toolbarLabel(): string {
    return this.toolbar?.getAttribute('aria-label') ?? ''
  }

  /** The toolbar's controls, by name, in order: `block-type`, `bold`, …, `redo`. */
  get tools(): string[] {
    return this.#tools().map(tool => tool.getAttribute('data-test-jn-value')!)
  }

  /** How many Separators the toolbar draws between its groups. */
  get separators(): number {
    return this.toolbar?.querySelectorAll('[data-test-jn-part="separator"]').length ?? 0
  }

  /** A toolbar control by name: `bold`, `bullet-list`, `undo`, `block-type`. Throws without one. */
  tool(name: string): HTMLElement {
    const tool = this.#tools().find(element => element.getAttribute('data-test-jn-value') === name)
    if (!tool) throw new Error(`Joinery harness: no "${name}" control in the toolbar of ${this}`)
    return tool
  }

  /** A control's accessible name (`Bold`). */
  toolLabel(name: string): string {
    const tool = this.tool(name)
    return tool.getAttribute('aria-label')?.trim() || collapse(tool.textContent)
  }

  /** A control's keyboard shortcut, as `aria-keyshortcuts` writes it (`Control+B`). */
  toolShortcut(name: string): string | null {
    return this.tool(name).getAttribute('aria-keyshortcuts')
  }

  /** Whether a toggle is pressed (`aria-pressed`): its mark or block is active at the cursor. */
  isActive(name: string): boolean {
    return this.tool(name).getAttribute('aria-pressed') === 'true'
  }

  /** The toggles pressed now, in order. */
  get active(): string[] {
    return this.tools.filter(name => this.isActive(name))
  }

  /** Whether a control can't be pressed now: disabled, or `aria-disabled` (nothing to undo). */
  isToolDisabled(name: string): boolean {
    const tool = this.tool(name)
    return (tool as HTMLButtonElement).disabled || tool.getAttribute('aria-disabled') === 'true'
  }

  /** Presses a control, as a click does: a toggle turns its mark or block on or off. */
  async press(name: string): Promise<void> {
    await click(this.tool(name))
  }

  /** The control Tab lands on in the toolbar (its roving tab stop), by name. */
  get tabStop(): string | null {
    const tool = this.#tools().find(element => element.getAttribute('tabindex') === '0')
    return tool?.getAttribute('data-test-jn-value') ?? null
  }

  /** The control that has focus, by name, or `null` when focus isn't in the toolbar. */
  get focusedTool(): string | null {
    const active = document.activeElement
    const tool = this.#tools().find(element => element === active)
    return tool?.getAttribute('data-test-jn-value') ?? null
  }

  /** Focuses a control, as Tab into the toolbar or a script would. */
  async focusTool(name: string): Promise<void> {
    await focus(this.tool(name))
  }

  /** Presses a key on the focused control: `'ArrowRight'`, `'Home'`, `' '`. */
  async pressKey(key: string, modifiers?: KeyModifiers): Promise<void> {
    await pressKey(key, modifiers)
  }

  /** Rests the pointer on a control, which opens its tooltip. */
  async hoverTool(name: string): Promise<void> {
    await hover(this.tool(name))
  }

  /** Moves the pointer off a control, away from its tooltip, which closes it. */
  async unhoverTool(name: string): Promise<void> {
    const tool = this.tool(name)
    const tooltip = (tool.getAttribute('aria-describedby') ?? '')
      .split(/\s+/)
      .map(id => (id ? document.getElementById(id) : null))
      .find((found): found is HTMLElement => Boolean(found))
    await unhover(tool, tooltip ? { away: tooltip } : {})
  }

  /**
   * A control's tooltip text while it is open, as its `aria-describedby` names it (`Bold Ctrl
   * B`), or `''` while it is closed.
   */
  tooltip(name: string): string {
    return textOfIds(this.tool(name), 'aria-describedby')
  }

  // ----- The text style menu ------------------------------------------------------------

  /** The text style menu, a Dropdown Menu. */
  get blockTypeMenu(): DropdownMenuHarness {
    return this.find(DropdownMenuHarness)
  }

  /** The text style at the cursor, as the menu's trigger shows it: `Paragraph`, `Heading 2`. */
  get blockType(): string {
    return collapse(this.tool('block-type').textContent)
  }

  /** The text styles the menu offers, in order. */
  async blockTypes(): Promise<string[]> {
    const menu = this.blockTypeMenu
    await menu.open()
    const items = menu.items
    await menu.pressEscape()
    return items
  }

  /** Applies a text style to the blocks at the cursor, through the menu: `Heading 2`. */
  async setBlockType(label: string): Promise<void> {
    const menu = this.blockTypeMenu
    await menu.open()
    await menu.select(label)
  }

  #tools(): HTMLElement[] {
    const toolbar = this.toolbar
    if (!toolbar) return []
    return [...toolbar.querySelectorAll<HTMLElement>('button[data-test-jn-value]')]
  }
}
