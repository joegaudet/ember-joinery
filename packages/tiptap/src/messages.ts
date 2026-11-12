import type { Message } from '@ember-joinery/primitives/i18n'

/**
 * Every string `@ember-joinery/tiptap` shows or announces itself, in English, for a translation
 * catalog. `@labels` still beats each one.
 */
export const messages = {
  toolbar: { id: 'joinery.rich-text-editor.toolbar', message: 'Formatting' },
  blockType: { id: 'joinery.rich-text-editor.blockType', message: 'Text style' },
  blockTypeName: {
    id: 'joinery.rich-text-editor.blockTypeName',
    message: '{name}: {style}',
    description:
      'The text style menu\'s name: {name} is "Text style", {style} the one at the cursor.',
  },
  paragraph: { id: 'joinery.rich-text-editor.paragraph', message: 'Paragraph' },
  heading: { id: 'joinery.rich-text-editor.heading', message: 'Heading {level}' },
  bold: { id: 'joinery.rich-text-editor.bold', message: 'Bold' },
  italic: { id: 'joinery.rich-text-editor.italic', message: 'Italic' },
  underline: { id: 'joinery.rich-text-editor.underline', message: 'Underline' },
  strike: { id: 'joinery.rich-text-editor.strike', message: 'Strikethrough' },
  code: { id: 'joinery.rich-text-editor.code', message: 'Code' },
  bulletList: { id: 'joinery.rich-text-editor.bulletList', message: 'Bulleted list' },
  orderedList: { id: 'joinery.rich-text-editor.orderedList', message: 'Numbered list' },
  blockquote: { id: 'joinery.rich-text-editor.blockquote', message: 'Quote' },
  codeBlock: { id: 'joinery.rich-text-editor.codeBlock', message: 'Code block' },
  undo: { id: 'joinery.rich-text-editor.undo', message: 'Undo' },
  redo: { id: 'joinery.rich-text-editor.redo', message: 'Redo' },
  keyCtrl: {
    id: 'joinery.rich-text-editor.keyCtrl',
    message: 'Ctrl',
    description: 'The Control key, as a shortcut shows it off Apple’s systems.',
  },
  keyShift: { id: 'joinery.rich-text-editor.keyShift', message: 'Shift' },
  keyAlt: { id: 'joinery.rich-text-editor.keyAlt', message: 'Alt' },
} satisfies Record<string, Message>
