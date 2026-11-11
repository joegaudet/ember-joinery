import { click, focus } from '@ember/test-helpers'
import { Harness } from '@ember-joinery/test-support'

/** One line of a code block, as its harness reads it. */
export interface CodeBlockLineInfo {
  /** Its text, as a selection copies it: no line number or diff marker. */
  text: string
  /** Its `@variant`: `default`, `added`, `removed` or `highlighted`. */
  variant: string
  /** Its line number, with `@lineNumbers`; otherwise `null`. */
  number: number | null
}

/** One highlighted token: its text and the colour it is drawn in now. */
export interface CodeBlockTokenInfo {
  text: string
  color: string
}

const collapse = (value: string | null | undefined): string =>
  (value ?? '').replace(/\s+/g, ' ').trim()

/**
 * Drives a `<CodeBlock>` from `@ember-joinery/code-block`: reads its title, its code line by
 * line (with each line's variant and number), whether it wraps, and its copy button, and copies.
 * Pair it with `setupClipboard()` to check what was copied.
 *
 *   const block = new CodeBlockHarness('route') // <CodeBlock @name="route">
 *   assert.strictEqual(block.title, 'app/api/chat/route.ts')
 *   assert.deepEqual(block.highlightedLines, [5, 6, 7, 8, 9])
 *   await block.copy()
 *   assert.true(block.isCopied)
 */
export class CodeBlockHarness extends Harness {
  static override component = 'code-block'

  /** Its `@variant`: `default` or `destructive`. */
  get variant(): string | null {
    return this.element.getAttribute('data-variant')
  }

  /** Its `@size`: `default` or `sm`. */
  get size(): string | null {
    return this.element.getAttribute('data-size')
  }

  /** The header, or `null` without one. */
  get header(): HTMLElement | null {
    return this.queryPart('header')
  }

  /** The title's text, whitespace collapsed, or `null` without a title. */
  get title(): string | null {
    const title = this.queryPart('title')
    return title ? collapse(title.textContent) : null
  }

  /** The actions' container, in the header or floating. `null` without one. */
  get actions(): HTMLElement | null {
    return this.queryPart('actions')
  }

  /** Whether the actions float: they are a direct child of the block, with no header. */
  get hasFloatingActions(): boolean {
    return this.actions?.parentElement === this.element
  }

  /** The footer, or `null` without one. */
  get footer(): HTMLElement | null {
    return this.queryPart('footer')
  }

  /** The `pre` that holds the code. */
  get content(): HTMLPreElement {
    return this.part<HTMLPreElement>('content')
  }

  /** Whether long lines wrap (`@wrap`) instead of scrolling. */
  get isWrapped(): boolean {
    return this.content.hasAttribute('data-wrap')
  }

  /** Whether its lines are numbered (`@lineNumbers`). */
  get isNumbered(): boolean {
    return this.content.hasAttribute('data-numbered')
  }

  /** The number of the first line (`@startLine`), read from the content's line counter. */
  get startLine(): number {
    const reset = this.content.style.getPropertyValue('counter-reset')
    const match = /line\s+(-?\d+)/.exec(reset)
    return match ? Number(match[1]) + 1 : 1
  }

  /**
   * Its lines: each `<b.Line>` (and each line of a `@code` string with `@lineNumbers`). A
   * `@code` string shown as one text node gives its lines split at each newline, as `default`.
   */
  get lines(): CodeBlockLineInfo[] {
    const numbered = this.isNumbered
    const start = this.startLine
    const lines = this.parts('line')
    if (lines.length) {
      return lines.map((line, index) => {
        const content = line.querySelector('[data-slot="code-block-line-content"]')
        const text = content?.textContent ?? ''
        return {
          text: text === '\n' ? '' : text,
          variant: line.getAttribute('data-variant') ?? 'default',
          number: numbered ? start + index : null,
        }
      })
    }
    const text = this.content.textContent ?? ''
    return text.split('\n').map((line, index) => ({
      text: line,
      variant: 'default',
      number: numbered ? start + index : null,
    }))
  }

  /** The code it shows, as copying all of it would give: its lines, joined with newlines. */
  get code(): string {
    return this.lines.map(line => line.text).join('\n')
  }

  /** The indices (from 0) of the lines with `@variant="highlighted"`. */
  get highlightedLines(): number[] {
    return this.#indicesOf('highlighted')
  }

  /** The indices of the lines a diff adds. */
  get addedLines(): number[] {
    return this.#indicesOf('added')
  }

  /** The indices of the lines a diff removes. */
  get removedLines(): number[] {
    return this.#indicesOf('removed')
  }

  /** Whether any line has highlighted tokens: the highlighter has run. */
  get isHighlighted(): boolean {
    return this.parts('line').some(line => line.querySelector('.jn-code-block-token'))
  }

  /** The highlighted tokens of line `index` (from 0), with the colour each is drawn in. */
  tokens(index: number): CodeBlockTokenInfo[] {
    const line = this.parts('line')[index]
    if (!line) return []
    return [...line.querySelectorAll<HTMLElement>('.jn-code-block-token')].map(token => ({
      text: token.textContent ?? '',
      color: getComputedStyle(token).color,
    }))
  }

  /** The copy button, or `null` without one. */
  get copyButton(): HTMLButtonElement | null {
    return this.queryPart<HTMLButtonElement>('copy-button')
  }

  #copyButton(): HTMLButtonElement {
    return this.part<HTMLButtonElement>('copy-button')
  }

  /** The copy button's accessible name: `Copy`, then `Copied` once it has copied. */
  get copyLabel(): string {
    return this.#copyButton().getAttribute('aria-label') ?? collapse(this.#copyButton().textContent)
  }

  /** Whether the copy button has just copied (for two seconds after). */
  get isCopied(): boolean {
    return this.#copyButton().hasAttribute('data-copied')
  }

  /** Whether the copy button can be used: it isn't `disabled`. */
  get canCopy(): boolean {
    return !this.#copyButton().disabled
  }

  /** What the copy button's live region announces: `Copied` after a copy, else nothing. */
  get status(): string {
    return collapse(this.queryPart('copy-status')?.textContent)
  }

  /** Clicks the copy button, as a user would, and waits for the clipboard. */
  async copy(): Promise<void> {
    await click(this.#copyButton())
  }

  /** Moves focus to the content, as tabbing to it would, so the keyboard scrolls it. */
  async focusContent(): Promise<void> {
    await focus(this.content)
  }

  #indicesOf(variant: string): number[] {
    return this.lines.flatMap((line, index) => (line.variant === variant ? [index] : []))
  }
}
