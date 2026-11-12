import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import type Owner from '@ember/owner'
import { on } from '@ember/modifier'
import { modifier } from 'ember-modifier'
import {
  Editor,
  type ChainedCommands,
  type Content,
  type Extensions,
  type JSONContent,
} from '@tiptap/core'
import type { EditorState } from '@tiptap/pm/state'
import StarterKit, { type StarterKitOptions } from '@tiptap/starter-kit'
import { idFor } from '@ember-joinery/primitives/id'
import RichTextToolbar from './toolbar.gts'
import {
  DEFAULT_HEADING_LEVELS,
  defaultLabels,
  DEFAULT_TOOLBAR,
  type BlockType,
  type HeadingLevel,
  type RichTextLabels,
  type RichTextTool,
} from './tools.ts'

export { DEFAULT_TOOLBAR }
export type { BlockType, HeadingLevel, RichTextLabels, RichTextTool }

/** What the editor stores: HTML (a string), or Tiptap's JSON document; empty is `''` or `null`. */
export type RichTextValue = string | JSONContent | null

/** What the document is stored as: an HTML string, or Tiptap's JSON. */
export type RichTextOutput = 'html' | 'json'

export interface RichTextEditorSignature {
  Args: {
    /** The document, when the caller controls it: a new value replaces what is in the editor. */
    value?: RichTextValue
    /** The document it starts with, uncontrolled. */
    defaultValue?: RichTextValue
    /** Called with the document after each change: HTML, or JSON with `@output="json"`. */
    onValueChange?: (value: RichTextValue) => void
    /** `html` (default) stores an HTML string; `json` stores Tiptap's JSON document. */
    output?: RichTextOutput
    /** The toolbar's controls, in its order of groups; `false` hides the toolbar. */
    toolbar?: readonly RichTextTool[] | false
    /** The heading levels the text style menu offers. Default `[1, 2, 3]`. */
    headingLevels?: readonly HeadingLevel[]
    /** More Tiptap extensions, after StarterKit. Read once, when the editor is made. */
    extensions?: Extensions
    /** StarterKit's options, such as `{ link: false }`. Read once. */
    starterKit?: Partial<StarterKitOptions>
    /** What an empty document shows, as a textarea's placeholder. */
    placeholder?: string
    /** Whether it can't be edited or focused, and its toolbar is disabled. */
    disabled?: boolean
    /** Whether the document can be read and selected but not changed; it shows no toolbar. */
    readonly?: boolean
    /** Whether the value is invalid: `aria-invalid` on the document, and a destructive border. */
    invalid?: boolean
    /** Whether a value is required (`aria-required`). */
    required?: boolean
    /** The document's `id`, so a `<label for>` (a FieldLabel) names it and a press on it focuses it. */
    id?: string
    /** The document's accessible name (`aria-label`), when no label names it. */
    label?: string
    /** The ids of what names the document (`aria-labelledby`), in place of a `<label for>`. */
    labelledBy?: string
    /** The ids of what describes the document (`aria-describedby`), such as a FieldDescription. */
    describedBy?: string
    /** The toolbar's and the text styles' names, each with an English default. */
    labels?: Partial<RichTextLabels>
    /**
     * Called once with the Tiptap editor, when it is made (before it is mounted, as the component
     * is constructed), for anything the toolbar doesn't do. Keep it; don't set tracked state the
     * template has read in it.
     */
    onCreate?: (editor: Editor) => void
    /** Its name, for `RichTextEditorHarness` (`data-test-jn-name`). */
    name?: string
  }
  /** The box around the toolbar and the document: an Input Group. */
  Element: HTMLDivElement
}

/** Whether a document is a single empty textblock (a paragraph or a heading). */
function isEmptyDoc(state: EditorState): boolean {
  const { doc } = state
  return doc.childCount === 1 && doc.firstChild!.isTextblock && doc.firstChild!.content.size === 0
}

const isEmptyParagraph = (node: JSONContent) => node.type === 'paragraph' && !node.content?.length

const isBlank = (value: unknown) => value === null || value === undefined || value === ''

/**
 * A rich-text editor on Tiptap's StarterKit, in shadcn's look: an Input Group with a toolbar
 * above the document, as a block-start addon. The toolbar has a Dropdown Menu for the text style
 * (paragraph or heading), Toggle Groups for the marks (bold, italic, underline, strikethrough,
 * code) and the blocks (lists, quote, code block), and Buttons for undo and redo, each with a
 * Tooltip naming it and its shortcut, and Separators between the groups:
 *
 *   <RichTextEditor @value={{this.body}} @onValueChange={{this.setBody}} @placeholder="Write…" />
 *
 * It stores HTML, or Tiptap's JSON with `@output="json"`; an empty document is `''` (`null` for
 * JSON). The document is a `textbox` that a `<label for>` with its `@id` names; the toolbar is
 * WAI-ARIA's toolbar, one tab stop with the arrow keys between its controls. Every string is an
 * argument, and it takes its direction from the nearest `dir`.
 */
export default class RichTextEditor extends Component<RichTextEditorSignature> {
  readonly editor: Editor
  /** The value it last sent or was given, so a value coming back isn't set again. */
  #current: unknown
  /** Bumped after each transaction, so the toolbar re-reads the editor. */
  @tracked revision = 0
  #toolbar: HTMLElement | undefined

  constructor(owner: Owner, args: RichTextEditorSignature['Args']) {
    super(owner, args)
    const initial = args.value !== undefined ? args.value : args.defaultValue
    this.#current = initial
    this.editor = new Editor({
      element: null,
      content: (initial ?? '') as Content,
      editable: this.editable,
      extensions: [StarterKit.configure(args.starterKit), ...(args.extensions ?? [])],
      editorProps: {
        attributes: (state: EditorState): Record<string, string> =>
          isEmptyDoc(state) ? { 'data-empty': '' } : {},
      },
      onUpdate: () => this.#onUpdate(),
      onTransaction: () => this.#refresh(),
    })
    args.onCreate?.(this.editor)
  }

  get contentId(): string {
    return this.args.id ?? idFor(this, 'content')
  }

  get isJson(): boolean {
    return this.args.output === 'json'
  }

  get editable(): boolean {
    return !(this.args.disabled || this.args.readonly)
  }

  get labels(): RichTextLabels {
    return { ...defaultLabels(this), ...this.args.labels }
  }

  get headingLevels(): readonly HeadingLevel[] {
    return this.args.headingLevels ?? DEFAULT_HEADING_LEVELS
  }

  /** The toolbar's controls, or none: `@toolbar={{false}}`, or read-only. */
  get tools(): ReadonlySet<RichTextTool> {
    const wanted = this.args.toolbar
    if (wanted === false || this.args.readonly) return new Set()
    return new Set(wanted ?? DEFAULT_TOOLBAR)
  }

  get hasToolbar(): boolean {
    return this.tools.size > 0
  }

  /**
   * The document as it is stored. StarterKit keeps an empty paragraph after a last list or
   * heading, so there is somewhere to type; it isn't content, so it isn't stored.
   */
  serialize(): RichTextValue {
    if (this.editor.isEmpty) return this.isJson ? null : ''
    if (!this.isJson) return this.editor.getHTML().replace(/(<p><\/p>)+$/, '')
    const json = this.editor.getJSON()
    const content = [...(json.content ?? [])]
    while (content.length > 1 && isEmptyParagraph(content[content.length - 1]!)) content.pop()
    return { ...json, content }
  }

  #onUpdate(): void {
    const value = this.serialize()
    this.#current = value
    this.args.onValueChange?.(value)
  }

  /** Transactions also happen while it renders (setting content), so re-render after them. */
  #refresh(): void {
    queueMicrotask(() => {
      if (!this.isDestroying) this.revision++
    })
  }

  /**
   * Runs a command on the editor. A press on the toolbar keeps the document focused (its
   * controls don't take focus from a pointer), so the command focuses it, unless focus is in
   * the toolbar, where a keyboard user stays.
   */
  run = (command: (chain: ChainedCommands) => ChainedCommands): void => {
    if (!this.editable) return
    const inToolbar = this.#toolbar?.contains(document.activeElement) ?? false
    command(this.editor.chain()).run()
    if (!inToolbar) this.focusDocument()
  }

  /**
   * Focuses the document, keeping its selection (or putting the cursor at `position`). Tiptap's
   * own `focus()` waits for an animation frame when the document isn't focused, which nothing
   * settles; ProseMirror's view focuses at once.
   */
  focusDocument = (position?: 'start' | 'end'): void => {
    const { editor } = this
    if (editor.isDestroyed) return
    editor.view.focus()
    if (position) editor.commands.focus(position)
  }

  /** Mounts the editor on the document's element, and ties it to a `<label for>` its id names. */
  mount = modifier((element: HTMLElement) => {
    this.editor.mount({ mount: element })
    const label = element.id
      ? element.ownerDocument.querySelector<HTMLLabelElement>(
          `label[for="${CSS.escape(element.id)}"]`,
        )
      : null
    const focus = () => this.focusDocument()
    label?.addEventListener('click', focus)
    return () => {
      label?.removeEventListener('click', focus)
      this.editor.destroy()
    }
  })

  /**
   * Names the document by its `<label for>`: a label doesn't name a `div`, so the document takes
   * `aria-labelledby`, unless `@label` or `@labelledBy` name it.
   */
  labelledBy = modifier(
    (element: HTMLElement, [id, label, labelledBy]: [string, unknown, string | undefined]) => {
      if (labelledBy || label) return
      const found = element.ownerDocument.querySelector<HTMLLabelElement>(
        `label[for="${CSS.escape(id)}"]`,
      )
      if (!found) return
      if (!found.id) found.id = `${id}-label`
      element.setAttribute('aria-labelledby', found.id)
      return () => element.removeAttribute('aria-labelledby')
    },
  )

  /** A new `@value` from outside (a reset, a reload) replaces the document, without a change. */
  sync = modifier((_element: HTMLElement, [value]: [unknown]) => {
    if (value === undefined || value === this.#current) return
    this.#current = value
    if (isBlank(value) && this.editor.isEmpty) return
    const same = this.isJson
      ? JSON.stringify(value) === JSON.stringify(this.serialize())
      : value === this.serialize()
    if (!same) this.editor.commands.setContent((value ?? '') as Content, { emitUpdate: false })
  })

  setEditable = modifier((_element: HTMLElement, [editable]: [boolean]) => {
    if (this.editor.isEditable !== editable) this.editor.setEditable(editable, false)
  })

  toolbar = modifier((element: HTMLElement) => {
    this.#toolbar = element
    return () => {
      if (this.#toolbar === element) this.#toolbar = undefined
    }
  })

  /** A press on the box's padding, around the document, puts the cursor in it. */
  focusFromPadding = (event: MouseEvent): void => {
    if (event.target !== event.currentTarget || !this.editable) return
    event.preventDefault()
    this.focusDocument('end')
  }

  <template>
    <div
      class="jn-rich-text-editor jn-input-group group/input-group"
      data-slot="rich-text-editor"
      data-disabled={{if @disabled "true"}}
      data-test-jn="rich-text-editor"
      data-test-jn-name={{@name}}
      ...attributes
    >
      {{#if this.hasToolbar}}
        <RichTextToolbar
          @editor={{this.editor}}
          @revision={{this.revision}}
          @tools={{this.tools}}
          @headingLevels={{this.headingLevels}}
          @labels={{this.labels}}
          @contentId={{this.contentId}}
          @disabled={{if @disabled true false}}
          @run={{this.run}}
          @focusDocument={{this.focusDocument}}
          {{this.toolbar}}
        />
      {{/if}}
      <div
        class="jn-rich-text-editor-content jn-textarea jn-input-group-textarea"
        data-slot="rich-text-editor-content"
        {{on "mousedown" this.focusFromPadding}}
      >
        <div
          id={{this.contentId}}
          class="jn-rich-text-editor-document"
          aria-multiline="true"
          aria-label={{@label}}
          aria-labelledby={{@labelledBy}}
          aria-describedby={{@describedBy}}
          aria-invalid={{if @invalid "true"}}
          aria-required={{if @required "true"}}
          aria-readonly={{if @readonly "true"}}
          aria-disabled={{if @disabled "true"}}
          aria-placeholder={{@placeholder}}
          data-placeholder={{@placeholder}}
          data-slot="input-group-control"
          data-test-jn-part="content"
          {{this.mount}}
          {{this.labelledBy this.contentId @label @labelledBy}}
          {{this.sync @value}}
          {{this.setEditable this.editable}}
        ></div>
      </div>
    </div>
  </template>
}
