import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { registerDestructor } from '@ember/destroyable'
import { waitForPromise } from '@ember/test-waiters'
import { Check, Copy } from 'lucide'
import { VisuallyHidden } from '@ember-joinery/primitives/visually-hidden'
import Button, { type ButtonSize, type ButtonVariant } from '@ember-joinery/ember/components/button'
import Icon, { type IconNode } from '@ember-joinery/ember/components/icon'

/** How long the button shows that it copied, in milliseconds, as upstream's. */
const COPIED_FOR = 2000

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
  @tracked copied = false

  #timer: ReturnType<typeof setTimeout> | undefined

  constructor(owner: unknown, args: CodeBlockCopyButtonSignature['Args']) {
    super(owner as never, args)
    registerDestructor(this, () => clearTimeout(this.#timer))
  }

  get label(): string {
    return this.copied ? (this.args.copiedLabel ?? 'Copied') : (this.args.copyLabel ?? 'Copy')
  }

  get status(): string {
    return this.copied ? (this.args.copiedLabel ?? 'Copied') : ''
  }

  get icon(): IconNode {
    return this.copied ? (this.args.copiedIcon ?? Check) : (this.args.copyIcon ?? Copy)
  }

  copy = (): void => {
    const value = this.args.value
    // As upstream's: a clipboard that refuses (or a page without one) leaves the button as it
    // was. Tests wait for the write.
    void waitForPromise(
      Promise.resolve()
        .then(() => navigator.clipboard.writeText(value))
        .then(() => {
          if (this.isDestroying) return
          this.copied = true
          clearTimeout(this.#timer)
          this.#timer = setTimeout(() => {
            if (!this.isDestroying) this.copied = false
          }, COPIED_FOR)
        })
        .catch(() => undefined),
    )
  }

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
