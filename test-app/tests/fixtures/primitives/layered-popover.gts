// A popover built the way Joinery's overlays are built on the primitives: the top layer for
// layering, the dismiss stack for Escape and pointers outside, and the anchor for placement.
// The layering, dismiss and anchor tests drive it; it is not a component Joinery ships.
import Component from '@glimmer/component'
import { array, hash } from '@ember/helper'
import { click } from '@ember/test-helpers'
import type { TOC } from '@ember/component/template-only'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { controllable, type ControllableArgs } from '@ember-joinery/primitives/controllable-state'
import { idFor } from '@ember-joinery/primitives/id'
import { part, type PartModifier } from '@ember-joinery/primitives/part'
import { topLayer, type PopoverMode } from '@ember-joinery/primitives/layer'
import {
  dismissable,
  type DismissReason,
  type FocusOutsideEvent,
  type PointerDownOutsideEvent,
} from '@ember-joinery/primitives/dismiss'
import { anchorTo, type Align, type Side } from '@ember-joinery/primitives/anchor'
import { Harness } from '@ember-joinery/test-support'

interface TriggerSignature {
  Args: { part: PartModifier; as?: TagName }
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

const Trigger: TOC<TriggerSignature> = <template>
  <As @as={{@as}} @tag="button" type="button" ...attributes {{@part}}>{{yield}}</As>
</template>

interface ContentSignature {
  Args: { popover: FxLayeredPopover }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

const Content: TOC<ContentSignature> = <template>
  {{#if @popover.open.value}}
    <div
      ...attributes
      {{@popover.content}}
      {{topLayer popover=@popover.mode source=@popover.triggerElement onHide=@popover.close}}
      {{dismissable
        onDismiss=@popover.dismiss
        onEscapeKeyDown=@popover.args.onEscapeKeyDown
        onPointerDownOutside=@popover.args.onPointerDownOutside
        onFocusOutside=@popover.args.onFocusOutside
        disableOutsidePointerEvents=@popover.args.modal
        inside=(array @popover.triggerElement)
      }}
      {{anchorTo
        @popover.triggerElement
        side=@popover.args.side
        align=@popover.args.align
        sideOffset=@popover.args.sideOffset
      }}
    >{{yield}}</div>
  {{/if}}
</template>

export interface FxLayeredPopoverSignature {
  Args: ControllableArgs<'open', boolean> & {
    name?: string
    popover?: PopoverMode
    modal?: boolean
    side?: Side
    align?: Align
    sideOffset?: number
    onDismiss?: (reason: DismissReason) => void
    onEscapeKeyDown?: (event: KeyboardEvent) => void
    onPointerDownOutside?: (event: PointerDownOutsideEvent) => void
    onFocusOutside?: (event: FocusOutsideEvent) => void
  }
  Blocks: {
    default: [
      {
        Trigger: WithBoundArgs<typeof Trigger, 'part'>
        Content: WithBoundArgs<typeof Content, 'popover'>
        close: () => void
      },
    ]
  }
  Element: HTMLDivElement
}

export class FxLayeredPopover extends Component<FxLayeredPopoverSignature> {
  open = controllable(this, 'open', false)

  /** The trigger, kept untracked: the content only renders after the trigger has. */
  triggerElement: HTMLElement | null = null

  get id() {
    return idFor(this)
  }

  get mode(): PopoverMode {
    return this.args.popover ?? 'manual'
  }

  get state() {
    return this.open.value ? 'open' : 'closed'
  }

  close = () => this.open.set(false)

  dismiss = (reason: DismissReason) => {
    this.args.onDismiss?.(reason)
    this.close()
  }

  trigger = part<HTMLElement>(() => ({
    attributes: {
      'aria-expanded': String(this.open.value),
      'aria-controls': this.open.value ? idFor(this, 'content') : undefined,
      'aria-haspopup': 'dialog',
      'data-state': this.state,
      'data-test-jn-part': 'trigger',
    },
    on: { click: () => this.open.set(open => !open) },
    element: element => {
      this.triggerElement = element
      return () => (this.triggerElement = null)
    },
  }))

  content = part(() => ({
    attributes: {
      id: idFor(this, 'content'),
      role: 'dialog',
      'aria-label': this.args.name ?? 'Popover',
      'data-state': this.state,
      'data-test-jn-part': 'content',
      'data-test-jn-owner': this.id,
    },
  }))

  <template>
    <div id={{this.id}} data-test-jn="fx-layered-popover" data-test-jn-name={{@name}} ...attributes>
      {{yield
        (hash
          Trigger=(component Trigger part=this.trigger)
          Content=(component Content popover=this)
          close=this.close
        )
      }}
    </div>
  </template>
}

export class FxLayeredPopoverHarness extends Harness {
  static override component = 'fx-layered-popover'

  get trigger(): HTMLElement {
    return this.part('trigger')
  }

  /** The content, or `null` while closed. */
  get content(): HTMLElement | null {
    return this.queryPart('content')
  }

  get isOpen(): boolean {
    return this.trigger.getAttribute('aria-expanded') === 'true'
  }

  /** Whether the content is showing in the browser's top layer. */
  get isInTopLayer(): boolean {
    return this.content?.matches(':popover-open') ?? false
  }

  /** The side the content was placed on, after any flip (`data-side`). */
  get side(): string | null {
    return this.content?.getAttribute('data-side') ?? null
  }

  /** The content's alignment along that side (`data-align`). */
  get align(): string | null {
    return this.content?.getAttribute('data-align') ?? null
  }

  async toggle(): Promise<void> {
    await click(this.trigger)
  }

  async open(): Promise<void> {
    if (!this.isOpen) await this.toggle()
  }
}
