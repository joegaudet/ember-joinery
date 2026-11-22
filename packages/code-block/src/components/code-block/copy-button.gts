import Component from '@glimmer/component'
import { on } from '@ember/modifier'
import { Check, Copy } from 'lucide'
import { VisuallyHidden } from '@ember-joinery/primitives/visually-hidden'
import Button, { type ButtonSize, type ButtonVariant } from '@ember-joinery/ember/components/button'
import Icon, { type IconNode } from '@ember-joinery/ember/components/icon'
import { translate } from '@ember-joinery/primitives/i18n'
import { messages } from '../../messages.ts'
import { copyMachine } from '../../-private/copy-machine.ts'

export interface CodeBlockCopyButtonSignature {
  Args: {
    /** The text it copies. Required. */
    value: string
    /** The Button's `@variant`. Default `ghost`. */
    variant?: ButtonVariant
    /** The Button's `@size`. Default `icon-xs`. */
    size?: ButtonSize
    /** Its label before it copies. Default `Copy`. */
    copyLabel?: string
    /** Its label once it has copied, which a live region also announces. Default `Copied`. */
    copiedLabel?: string
    /** The icon before it copies: a `lucide` icon. Default lucide's `copy`. */
    copyIcon?: IconNode
    /** The icon once it has copied. Default lucide's `check`. */
    copiedIcon?: IconNode
    /** Its name, for `ButtonHarness` (`data-test-jn-name`). */
    name?: string
  }
  /** A `<button>` (Joinery's Button, whose element type also allows a link). */
  Element: HTMLButtonElement | HTMLAnchorElement
}

/**
 * A ghost icon button that copies `@value` to the clipboard (upstream's `CodeBlockCopyButton`).
 * Once it has, it is labelled "Copied" and shows a check for two seconds, and a polite live
 * region announces it. It is a Joinery `Button`, so it takes `disabled` and listeners of your
 * own, which run before it copies.
 *
 *   <b.CopyButton @value={{this.code}} />
 *   <b.CopyButton @value={{this.code}} disabled={{this.streaming}} />
 */
export default class CodeBlockCopyButton extends Component<CodeBlockCopyButtonSignature> {
  machine = copyMachine(this)

  get copied(): boolean {
    return this.machine.isCopied
  }

  get copiedLabel(): string {
    return this.args.copiedLabel ?? translate(this, messages.copied)
  }

  get label(): string {
    return this.copied ? this.copiedLabel : (this.args.copyLabel ?? translate(this, messages.copy))
  }

  get status(): string {
    return this.copied ? this.copiedLabel : ''
  }

  get icon(): IconNode {
    return this.copied ? (this.args.copiedIcon ?? Check) : (this.args.copyIcon ?? Copy)
  }

  copy = (): void => this.machine.copy(this.args.value)

  <template>
    <Button
      @variant={{if @variant @variant "ghost"}}
      @size={{if @size @size "icon-xs"}}
      @name={{@name}}
      class="jn-code-block-copy-button"
      data-slot="code-block-copy-button"
      data-copied={{if this.copied "true"}}
      aria-label={{this.label}}
      data-test-jn-part="copy-button"
      ...attributes
      {{on "click" this.copy}}
    ><Icon @icon={{this.icon}} /></Button>
    <VisuallyHidden
      aria-live="polite"
      data-test-jn-part="copy-status"
    >{{this.status}}</VisuallyHidden>
  </template>
}
