import type { TOC } from '@ember/component/template-only'
import { htmlSafe, type SafeString } from '@ember/template'
import type { CodeLine, CodeToken } from '../../highlighter.ts'

/** A line's state: `added` and `removed` mark a diff, `highlighted` calls a line out. */
export type CodeBlockLineVariant = 'default' | 'added' | 'removed' | 'highlighted'

export interface CodeBlockLineSignature {
  Args: {
    /**
     * The line: a string, or a `CodeLine` from `highlightedCode` or `highlightCode`. Without
     * it, the line shows its block.
     */
    code?: string | CodeLine
    /** Default `default`. `added` and `removed` add a `+` or `−` marker and a tint. */
    variant?: CodeBlockLineVariant
  }
  Blocks: {
    /** The line's content, when it has no `@code`. */
    default: []
  }
  Element: HTMLSpanElement
}

/** What an empty line holds, so copying a selection keeps blank lines (as upstream's). */
const NEWLINE = '\n'

const isText = (code: string | CodeLine | undefined): code is string => typeof code === 'string'

/** Whether the line has nothing to show: no code, an empty string, or no tokens with text. */
const isEmpty = (code: string | CodeLine | undefined): boolean => {
  if (code === undefined) return false
  if (typeof code === 'string') return code === ''
  return code.every(token => token.content === '')
}

const tokensOf = (code: string | CodeLine | undefined): CodeLine =>
  code === undefined || typeof code === 'string' ? [] : code

/** A token's colours, from Shiki's own output: trusted. */
const styleOf = (token: CodeToken): SafeString | undefined =>
  token.style ? htmlSafe(token.style) : undefined

/**
 * One line of code (upstream's `CodeBlockLine`), inside a `<b.Content>`. Its line number, and
 * a diff's `+` or `−`, are CSS, so a selection doesn't copy them. A highlighted token is a
 * `span.jn-code-block-token` with Shiki's colours in its style.
 *
 *   <b.Line @code="const a = 1" @variant="highlighted" />
 *   <b.Line @code={{line}} />          {{! a CodeLine from highlightedCode }}
 *
 * Its template keeps whitespace out of the line (a `pre` shows every space), so write
 * `<b.Line>{{text}}</b.Line>` without spaces inside, or pass `@code`.
 */
const CodeBlockLine: TOC<CodeBlockLineSignature> = <template>
  <span
    class="jn-code-block-line jn-code-block-line-variant-{{if @variant @variant 'default'}}"
    data-slot="code-block-line"
    data-variant={{if @variant @variant "default"}}
    data-test-jn-part="line"
    ...attributes
  ><span class="jn-code-block-line-content" data-slot="code-block-line-content">
      {{~#if (isEmpty @code)~}}
        {{NEWLINE}}
      {{~else if (isText @code)~}}
        {{@code}}
      {{~else if @code~}}
        {{~#each (tokensOf @code) as |token|~}}
          {{~#if token.style~}}
            <span class="jn-code-block-token" style={{styleOf token}}>{{token.content}}</span>
          {{~else~}}
            {{token.content}}
          {{~/if~}}
        {{~/each~}}
      {{~else~}}
        {{yield}}
      {{~/if~}}
    </span></span>
</template>

export default CodeBlockLine
