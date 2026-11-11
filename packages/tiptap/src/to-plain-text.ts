import type { JSONContent } from '@tiptap/core'
import type { RichTextValue } from './components/rich-text-editor/index.gts'

const isBlank = (value: unknown) => value === null || value === undefined || value === ''

/**
 * The plain text of a rich-text value (HTML or Tiptap's JSON), blocks separated by a space:
 * for a check that a document says something, a preview, or a search index.
 *
 *   toPlainText('<h2>Hi</h2><p>there</p>') // 'Hi there'
 */
export function toPlainText(value: RichTextValue | undefined): string {
  if (isBlank(value)) return ''
  if (typeof value === 'string') {
    // Blocks end in a space, so "<p>a</p><p>b</p>" reads "a b", not "ab".
    const spaced = value.replace(/<\/(p|h[1-6]|li|blockquote|pre)>|<br\s*\/?>/gi, '$& ')
    const text = new DOMParser().parseFromString(spaced, 'text/html').body.textContent ?? ''
    return text.replace(/\s+/g, ' ').trim()
  }
  const words: string[] = []
  const walk = (node: JSONContent) => {
    if (node.text) words.push(node.text)
    node.content?.forEach(walk)
    if (node.type !== 'text') words.push(' ')
  }
  walk(value as JSONContent)
  return words.join('').replace(/\s+/g, ' ').trim()
}
