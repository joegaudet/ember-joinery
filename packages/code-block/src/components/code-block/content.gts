import Component from '@glimmer/component'
import { htmlSafe, type SafeString } from '@ember/template'
import { modifier } from 'ember-modifier'
import CodeBlockLine from './line.gts'

export interface CodeBlockContentSignature {
  Args: {
    /**
     * The code, as a string (upstream's string child). It renders as one text node, so it stays
     * cheap while output streams; with `@lineNumbers`, it is split into lines. Without it, the
     * content shows its block: `<b.Line>`s, one per line.
     */
    code?: string
    /** Wrap long lines instead of scrolling. Default `false`. */
    wrap?: boolean
    /** Number each line. Default `false`. A `@code` string is split into lines. */
    lineNumbers?: boolean
    /** The number of the first line, with `@lineNumbers`. Default 1. */
    startLine?: number
  }
  Blocks: {
    /** The lines, as `<b.Line>`s, when there is no `@code`. */
    default: []
  }
  Element: HTMLPreElement
}

/**
 * Keeps the line counter's start on the element's own style, so a `style` of the caller's
 * (which replaces the rendered one) still numbers from `@startLine`, as upstream merges its
 * `counterReset` into the caller's `style`.
 */
const counterReset = modifier((element: HTMLElement, [value]: [string]) => {
  element.style.setProperty('counter-reset', value)
})

/**
 * The code (upstream's `CodeBlockContent`): a `pre`, with a `code` inside, that scrolls, or wraps
 * with `@wrap`. It is always left to right (`dir="ltr"`), and it is in the tab order
 * (`tabindex="0"`) so a keyboard can scroll it; give it `tabindex="-1"` to take it out. Cap its
 * height with a class (`max-h-48`) or CSS of your own; its edges fade as it scrolls.
 */
export default class CodeBlockContent extends Component<CodeBlockContentSignature> {
  get counter(): string {
    return `line ${(this.args.startLine ?? 1) - 1}`
  }

  get style(): SafeString {
    return htmlSafe(`counter-reset: ${this.counter}`)
  }

  /** `@code`, split into lines, without the empty line a trailing newline would add. */
  get lines(): string[] {
    return (this.args.code ?? '').replace(/\n$/, '').split('\n')
  }

  get splits(): boolean {
    return Boolean(this.args.lineNumbers) && typeof this.args.code === 'string'
  }

  get isText(): boolean {
    return typeof this.args.code === 'string'
  }

  <template>
    <pre
      class="jn-code-block-content"
      data-slot="code-block-content"
      data-wrap={{if @wrap "true"}}
      data-numbered={{if @lineNumbers "true"}}
      dir="ltr"
      tabindex="0"
      style={{this.style}}
      data-test-jn-part="content"
      ...attributes
      {{counterReset this.counter}}
    ><code class="jn-code-block-code" data-slot="code-block-code">
        {{~#if this.splits~}}
          {{~#each this.lines as |line|~}}
            <CodeBlockLine @code={{line}} />
          {{~/each~}}
        {{~else if this.isText~}}
          {{@code}}
        {{~else~}}
          {{yield}}
        {{~/if~}}
      </code></pre>
  </template>
}
