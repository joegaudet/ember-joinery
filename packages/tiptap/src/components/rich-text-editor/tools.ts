import type { ChainedCommands, Editor } from '@tiptap/core'
import type { Node as ProseMirrorNode } from '@tiptap/pm/model'
import {
  Bold,
  Code,
  Italic,
  List,
  ListOrdered,
  Redo2,
  SquareCode,
  Strikethrough,
  TextQuote,
  Underline,
  Undo2,
} from 'lucide'
import type { IconNode } from '@ember-joinery/ember/components/icon'
import { translate } from '@ember-joinery/primitives/i18n'
import { messages } from '../../messages.ts'

/**
 * A toolbar control, by name: the text style menu (`block-type`), a toggle for a mark or a
 * block, or a history button.
 */
export type RichTextTool =
  | 'block-type'
  | 'bold'
  | 'italic'
  | 'underline'
  | 'strike'
  | 'code'
  | 'bullet-list'
  | 'ordered-list'
  | 'blockquote'
  | 'code-block'
  | 'undo'
  | 'redo'

/** A toggle: a mark or a block a press turns on or off. */
export type RichTextToggle = Exclude<RichTextTool, 'block-type' | 'undo' | 'redo'>

/** A history button. */
export type RichTextAction = 'undo' | 'redo'

/** A heading level StarterKit's Heading takes. */
export type HeadingLevel = 1 | 2 | 3 | 4 | 5 | 6

/** A text style the menu offers: a paragraph, or a heading of one level. */
export type BlockType = 'paragraph' | `heading-${HeadingLevel}`

/** The names of the toolbar's controls and the text styles, each an argument with an English default. */
export interface RichTextLabels {
  /** The toolbar's accessible name. Default `Formatting`. */
  toolbar: string
  /** What the text style menu is for, before the style in its name. Default `Text style`. */
  blockType: string
  paragraph: string
  /** A heading's name, given its level. Default `Heading 2`. */
  heading: (level: HeadingLevel) => string
  bold: string
  italic: string
  underline: string
  strike: string
  code: string
  'bullet-list': string
  'ordered-list': string
  blockquote: string
  'code-block': string
  undo: string
  redo: string
}

/** The labels in the words of `context`'s translator (English without one). */
export function defaultLabels(context: object): RichTextLabels {
  const say = (message: (typeof messages)[keyof typeof messages]) => translate(context, message)
  return {
    toolbar: say(messages.toolbar),
    blockType: say(messages.blockType),
    paragraph: say(messages.paragraph),
    heading: level => translate(context, messages.heading, { level }),
    bold: say(messages.bold),
    italic: say(messages.italic),
    underline: say(messages.underline),
    strike: say(messages.strike),
    code: say(messages.code),
    'bullet-list': say(messages.bulletList),
    'ordered-list': say(messages.orderedList),
    blockquote: say(messages.blockquote),
    'code-block': say(messages.codeBlock),
    undo: say(messages.undo),
    redo: say(messages.redo),
  }
}

/** A key of a shortcut, as ProseMirror's keymaps name it: `Mod` is ⌘ on Apple's systems, Ctrl elsewhere. */
type Key = 'Mod' | 'Shift' | 'Alt' | string

/** Whether `Mod` means ⌘ here, as ProseMirror's keymap decides it. */
export function isApple(): boolean {
  return typeof navigator !== 'undefined' && /Mac|iP(hone|[oa]d)/.test(navigator.platform)
}

/** How a shortcut's keys are shown, one `<Kbd>` each: `["Ctrl", "Shift", "S"]`, or `["⌘", "⇧", "S"]`. */
export function shortcutKeys(keys: readonly Key[], apple = isApple()): string[] {
  return keys.map(key => {
    if (key === 'Mod') return apple ? '⌘' : 'Ctrl'
    if (key === 'Shift') return apple ? '⇧' : 'Shift'
    if (key === 'Alt') return apple ? '⌥' : 'Alt'
    return key.toUpperCase()
  })
}

/** A shortcut as `aria-keyshortcuts` writes it: `Control+Shift+S`, or `Meta+Shift+S`. */
export function ariaShortcut(keys: readonly Key[], apple = isApple()): string {
  return keys
    .map(key => {
      if (key === 'Mod') return apple ? 'Meta' : 'Control'
      return key.length === 1 ? key.toUpperCase() : key
    })
    .join('+')
}

/** What a toggle or button does, and how it reads the editor. */
export interface ToolSpec {
  name: Exclude<RichTextTool, 'block-type'>
  icon: IconNode
  /** Tiptap's keyboard shortcut for it (StarterKit's), shown in its tooltip. */
  shortcut: readonly Key[]
  /** Runs it on a chain that already has (or deliberately lacks) `focus()`. */
  run: (chain: ChainedCommands) => ChainedCommands
  /** Whether its mark or block is active at the cursor (a toggle's pressed state). */
  isActive: (editor: Editor) => boolean
  /** Whether it can run now (only the history buttons can't, with nothing to undo or redo). */
  can: (editor: Editor) => boolean
}

const always = (): boolean => true
const never = (): boolean => false

export const TOOLS: Record<Exclude<RichTextTool, 'block-type'>, ToolSpec> = {
  bold: {
    name: 'bold',
    icon: Bold,
    shortcut: ['Mod', 'B'],
    run: chain => chain.toggleBold(),
    isActive: editor => editor.isActive('bold'),
    can: always,
  },
  italic: {
    name: 'italic',
    icon: Italic,
    shortcut: ['Mod', 'I'],
    run: chain => chain.toggleItalic(),
    isActive: editor => editor.isActive('italic'),
    can: always,
  },
  underline: {
    name: 'underline',
    icon: Underline,
    shortcut: ['Mod', 'U'],
    run: chain => chain.toggleUnderline(),
    isActive: editor => editor.isActive('underline'),
    can: always,
  },
  strike: {
    name: 'strike',
    icon: Strikethrough,
    shortcut: ['Mod', 'Shift', 'S'],
    run: chain => chain.toggleStrike(),
    isActive: editor => editor.isActive('strike'),
    can: always,
  },
  code: {
    name: 'code',
    icon: Code,
    shortcut: ['Mod', 'E'],
    run: chain => chain.toggleCode(),
    isActive: editor => editor.isActive('code'),
    can: always,
  },
  'bullet-list': {
    name: 'bullet-list',
    icon: List,
    shortcut: ['Mod', 'Shift', '8'],
    run: chain => chain.toggleBulletList(),
    isActive: editor => editor.isActive('bulletList'),
    can: always,
  },
  'ordered-list': {
    name: 'ordered-list',
    icon: ListOrdered,
    shortcut: ['Mod', 'Shift', '7'],
    run: chain => chain.toggleOrderedList(),
    isActive: editor => editor.isActive('orderedList'),
    can: always,
  },
  blockquote: {
    name: 'blockquote',
    icon: TextQuote,
    shortcut: ['Mod', 'Shift', 'B'],
    run: chain => chain.toggleBlockquote(),
    isActive: editor => editor.isActive('blockquote'),
    can: always,
  },
  'code-block': {
    name: 'code-block',
    icon: SquareCode,
    shortcut: ['Mod', 'Alt', 'C'],
    run: chain => chain.toggleCodeBlock(),
    isActive: editor => editor.isActive('codeBlock'),
    can: always,
  },
  undo: {
    name: 'undo',
    icon: Undo2,
    shortcut: ['Mod', 'Z'],
    run: chain => chain.undo(),
    isActive: never,
    can: editor => editor.can().undo(),
  },
  redo: {
    name: 'redo',
    icon: Redo2,
    shortcut: ['Mod', 'Shift', 'Z'],
    run: chain => chain.redo(),
    isActive: never,
    can: editor => editor.can().redo(),
  },
}

/** The toolbar's groups, in order, with a Separator between each two that show. */
export const GROUPS = {
  blockType: ['block-type'],
  marks: ['bold', 'italic', 'underline', 'strike', 'code'],
  blocks: ['bullet-list', 'ordered-list', 'blockquote', 'code-block'],
  history: ['undo', 'redo'],
} as const satisfies Record<string, readonly RichTextTool[]>

/** Every control, the default `@toolbar`. */
export const DEFAULT_TOOLBAR: readonly RichTextTool[] = Object.values(GROUPS).flat()

/** The heading levels the text style menu offers by default. */
export const DEFAULT_HEADING_LEVELS: readonly HeadingLevel[] = [1, 2, 3]

/** Tiptap's shortcut for a text style: `Mod-Alt-0` for a paragraph, `Mod-Alt-<level>` for a heading. */
export function blockTypeShortcut(type: BlockType): Key[] {
  return ['Mod', 'Alt', type === 'paragraph' ? '0' : type.slice('heading-'.length)]
}

/** A textblock's text style, or `null` for one that has none (a code block). */
function blockTypeOf(node: ProseMirrorNode): BlockType | null {
  if (node.type.name === 'paragraph') return 'paragraph'
  if (node.type.name === 'heading') return `heading-${node.attrs['level'] as HeadingLevel}`
  return null
}

/**
 * The text style at the cursor, or of every block the selection covers: a paragraph, a heading
 * of a level, or `null` in a code block or across blocks of different styles. Empty blocks in a
 * selection (StarterKit's last empty paragraph, after Ctrl+A) don't count, unless all are empty.
 */
export function currentBlockType(editor: Editor): BlockType | null {
  const { selection, doc } = editor.state
  if (selection.empty) return blockTypeOf(selection.$from.parent)
  const blocks: ProseMirrorNode[] = []
  doc.nodesBetween(selection.from, selection.to, node => {
    if (!node.isTextblock) return true
    blocks.push(node)
    return false
  })
  const filled = blocks.filter(block => block.content.size > 0)
  const types = new Set((filled.length ? filled : blocks).map(blockTypeOf))
  return types.size === 1 ? [...types][0]! : null
}

/** Applies a text style to the blocks at the cursor. */
export function setBlockType(chain: ChainedCommands, type: BlockType): ChainedCommands {
  if (type === 'paragraph') return chain.setParagraph()
  const level = Number(type.slice('heading-'.length)) as HeadingLevel
  return chain.setHeading({ level })
}
