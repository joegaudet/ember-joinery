import Helper from '@ember/component/helper'
import { tracked } from '@glimmer/tracking'
import type { GrammarState } from 'shiki/core'
import { loadHighlighter, plainLines, type CodeHighlighter, type CodeLine } from './highlighter.ts'

export interface HighlightedCodeSignature {
  Args: {
    /** The code, and its language: a name or alias from the list, or `ansi`. */
    Positional: [code: string, language: string]
  }
  /** One line each, to render with `<b.Line @code={{line}} />`. */
  Return: CodeLine[]
}

/** The complete lines highlighted so far, and the grammar's state after them. */
interface Done {
  highlighter: CodeHighlighter | null
  text: string
  lines: CodeLine[]
  state?: GrammarState
}

/**
 * Highlights code with Shiki, as upstream's `useHighlightedCode` hook does, and gives one
 * `CodeLine` per line for `<b.Line @code>`:
 *
 *   <b.Content>
 *     {{#each (highlightedCode this.code "ts") as |line|}}<b.Line @code={{line}} />{{/each}}
 *   </b.Content>
 *
 * Until the language has loaded, and for a language that isn't in the list, the lines are
 * plain. A trailing newline is ignored. While the code streams in, each new piece starts from
 * the grammar's state at the end of the last complete line, so only the new lines are
 * tokenized, and the lines before keep the same objects (and their rendered DOM). The last
 * line is still being written, so it is tokenized again each time.
 *
 * Each place it is used keeps its own progress, as a hook would: it is a class-based helper.
 */
class HighlightedCode extends Helper<HighlightedCodeSignature> {
  /** The highlighter for the language asked for last, once it has loaded (`null`: not listed). */
  @tracked loaded: { language: string; highlighter: CodeHighlighter | null } | undefined

  #requested: string | undefined
  #done: Done = { highlighter: null, text: '', lines: [] }

  compute([value, language]: HighlightedCodeSignature['Args']['Positional']): CodeLine[] {
    // A trailing newline would render as an extra empty line.
    const code = value.endsWith('\n') ? value.slice(0, -1) : value
    if (this.#requested !== language) {
      this.#requested = language
      this.#load(language)
    }
    const loaded = this.loaded
    const highlighter = loaded?.language === language ? loaded.highlighter : null

    // The complete lines, highlighted. While the code streams, only the new lines are
    // tokenized, starting from the grammar state of the last one.
    let next = this.#done
    if (next.highlighter !== highlighter || !code.startsWith(next.text)) {
      next = { highlighter, text: '', lines: [] }
    }
    const end = code.lastIndexOf('\n') + 1
    if (highlighter && end > next.text.length) {
      const result = highlighter.highlight(code.slice(next.text.length, end - 1), next.state)
      next = {
        highlighter,
        text: code.slice(0, end),
        lines: [...next.lines, ...result.lines],
        state: result.state,
      }
    }
    this.#done = next

    if (!highlighter) return plainLines(code)
    // The last line is still being written, so it is tokenized every time.
    const tail = code.slice(end)
    return [...next.lines, highlighter.highlight(tail, next.state).lines[0] ?? []]
  }

  #load(language: string): void {
    loadHighlighter(language)
      .then(highlighter => {
        if (this.isDestroying || this.#requested !== language) return
        this.loaded = { language, highlighter }
      })
      .catch(() => {
        // The code stays plain.
      })
  }
}

/** The `highlightedCode` helper: see `HighlightedCode`. */
export const highlightedCode = HighlightedCode
