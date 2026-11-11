import type { TOC } from '@ember/component/template-only'
import type { ComponentLike } from '@glint/template'
import { As, type TagName } from '@ember-joinery/primitives/as'
import type { PartModifier } from '@ember-joinery/primitives/part'
import {
  staticPart,
  staticPartModifier,
  type StaticPartSignature,
} from '../../-private/static-part.gts'
import CodeBlockContent from './content.gts'
import CodeBlockCopyButton from './copy-button.gts'
import CodeBlockLine from './line.gts'

export type { CodeBlockContentSignature } from './content.gts'
export type { CodeBlockCopyButtonSignature } from './copy-button.gts'
export type { CodeBlockLineSignature, CodeBlockLineVariant } from './line.gts'
export type { StaticPartSignature as CodeBlockPartSignature } from '../../-private/static-part.gts'

/** The tone of a block: `destructive` for errors and failed output. */
export type CodeBlockVariant = 'default' | 'destructive'

/** How roomy a block is: `sm` has tighter padding and `text-xs` code, for tool output. */
export type CodeBlockSize = 'default' | 'sm'

const HEADER = { class: 'jn-code-block-header', slot: 'code-block-header', part: 'header' } as const
const TITLE = { class: 'jn-code-block-title', slot: 'code-block-title', part: 'title' } as const
const ACTIONS = {
  class: 'jn-code-block-actions',
  slot: 'code-block-actions',
  part: 'actions',
} as const
const FOOTER = { class: 'jn-code-block-footer', slot: 'code-block-footer', part: 'footer' } as const

/** What a code block yields: its parts, as components, and modifiers for your own elements. */
export interface CodeBlockParts {
  /** A row above the content, for a title and actions. */
  Header: ComponentLike<StaticPartSignature>
  /** A filename or a label, with an optional icon. It truncates. */
  Title: ComponentLike<StaticPartSignature>
  /**
   * Buttons, at the end of the header. As a direct child of the block (with no header), they
   * float at its top end, and show when it is hovered or has focus (always, on touch screens).
   */
  Actions: ComponentLike<StaticPartSignature>
  /** A ghost icon button that copies its `@value`. */
  CopyButton: typeof CodeBlockCopyButton
  /** The `pre` that scrolls or wraps: `@code` as a string, or `<b.Line>`s. */
  Content: typeof CodeBlockContent
  /** One line of code, inside the content: `@code` and `@variant`. */
  Line: typeof CodeBlockLine
  /** A row below the content, such as for a Show More button. */
  Footer: ComponentLike<StaticPartSignature>
  /** Makes your own element the header. */
  header: PartModifier<HTMLElement>
  /** Makes your own element or component the title. */
  title: PartModifier<HTMLElement>
  /** Makes your own element the actions' container. */
  actions: PartModifier<HTMLElement>
  /** Makes your own element the footer. */
  footer: PartModifier<HTMLElement>
}

const PARTS: CodeBlockParts = {
  Header: staticPart(HEADER),
  Title: staticPart(TITLE),
  Actions: staticPart(ACTIONS),
  CopyButton: CodeBlockCopyButton,
  Content: CodeBlockContent,
  Line: CodeBlockLine,
  Footer: staticPart(FOOTER),
  header: staticPartModifier(HEADER),
  title: staticPartModifier(TITLE),
  actions: staticPartModifier(ACTIONS),
  footer: staticPartModifier(FOOTER),
}

export interface CodeBlockSignature {
  Args: {
    /** Default `default`. `destructive` for errors and failed output. */
    variant?: CodeBlockVariant
    /** Default `default`. `sm` has tighter padding and `text-xs` code, for tool output. */
    size?: CodeBlockSize
    /** The tag to render instead of `div`, such as `figure`. */
    as?: TagName
    /** The block's name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** The block's parts: a header, floating actions, the content, a footer. */
    default: [CodeBlockParts]
  }
  Element: HTMLElement
}

/**
 * Displays code, terminal output and diffs with an optional header, line numbers and a copy
 * button: shadcn's Code Block.
 *
 *   <CodeBlock as |b|>
 *     <b.Header>
 *       <b.Title>Terminal</b.Title>
 *       <b.Actions><b.CopyButton @value={{this.output}} /></b.Actions>
 *     </b.Header>
 *     <b.Content @code={{this.output}} />
 *   </CodeBlock>
 *
 * For syntax highlighting, render each line from `highlightedCode`:
 *
 *   <b.Content @lineNumbers={{true}}>
 *     {{#each (highlightedCode this.code "ts") as |line|}}<b.Line @code={{line}} />{{/each}}
 *   </b.Content>
 */
const CodeBlock: TOC<CodeBlockSignature> = <template>
  <As
    @as={{@as}}
    class="jn-code-block group/code-block jn-code-block-variant-{{if @variant @variant 'default'}}"
    data-slot="code-block"
    data-variant={{if @variant @variant "default"}}
    data-size={{if @size @size "default"}}
    data-test-jn="code-block"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield PARTS}}</As>
</template>

export default CodeBlock
