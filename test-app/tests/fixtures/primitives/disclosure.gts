// A disclosure built the way Joinery's components are built on the primitives: controllable
// state, ids, and part modifiers with `@as`. The primitives' tests drive it; it is not a
// component Joinery ships.
import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import { click } from '@ember/test-helpers'
import type { TOC } from '@ember/component/template-only'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { controllable, type ControllableArgs } from '@ember-joinery/primitives/controllable-state'
import { idFor } from '@ember-joinery/primitives/id'
import { part, type PartModifier } from '@ember-joinery/primitives/part'
import { Harness } from '@ember-joinery/test-support'

interface TriggerSignature {
  Args: { part: PartModifier; as?: TagName }
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

/** The caller's attributes first, then the part's, so the part's ARIA wins. */
const Trigger: TOC<TriggerSignature> = <template>
  <As @as={{@as}} @tag="button" type="button" ...attributes {{@part}}>{{yield}}</As>
</template>

interface ContentSignature {
  Args: { part: PartModifier; open: boolean; as?: TagName }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

const Content: TOC<ContentSignature> = <template>
  {{#if @open}}
    <As @as={{@as}} @tag="div" ...attributes {{@part}}>{{yield}}</As>
  {{/if}}
</template>

export interface FxPrimitiveDisclosureSignature {
  Args: ControllableArgs<'open', boolean> & { name?: string }
  Blocks: {
    default: [
      {
        Trigger: WithBoundArgs<typeof Trigger, 'part'>
        Content: WithBoundArgs<typeof Content, 'part' | 'open'>
        trigger: PartModifier
        isOpen: boolean
      },
    ]
  }
  Element: HTMLDivElement
}

export class FxPrimitiveDisclosure extends Component<FxPrimitiveDisclosureSignature> {
  open = controllable(this, 'open', false)

  get id() {
    return idFor(this)
  }

  get contentId() {
    return idFor(this, 'content')
  }

  get state() {
    return this.open.value ? 'open' : 'closed'
  }

  toggle = () => this.open.set(open => !open)

  trigger = part(() => ({
    attributes: {
      'aria-expanded': String(this.open.value),
      'aria-controls': this.open.value ? this.contentId : undefined,
      'data-state': this.state,
      'data-slot': 'disclosure-trigger',
      'data-test-jn-part': 'trigger',
    },
    on: { click: this.toggle },
  }))

  content = part(() => ({
    attributes: {
      id: this.contentId,
      'data-state': this.state,
      'data-slot': 'disclosure-content',
      'data-test-jn-part': 'content',
    },
  }))

  <template>
    <div
      id={{this.id}}
      data-test-jn="fx-primitive-disclosure"
      data-test-jn-name={{@name}}
      ...attributes
    >
      {{yield
        (hash
          Trigger=(component Trigger part=this.trigger)
          Content=(component Content part=this.content open=this.open.value)
          trigger=this.trigger
          isOpen=this.open.value
        )
      }}
    </div>
  </template>
}

export class FxPrimitiveDisclosureHarness extends Harness {
  static override component = 'fx-primitive-disclosure'

  get trigger(): HTMLElement {
    return this.part('trigger')
  }

  get content(): HTMLElement | null {
    return this.queryPart('content')
  }

  get isOpen(): boolean {
    return this.trigger.getAttribute('aria-expanded') === 'true'
  }

  async toggle(): Promise<void> {
    await click(this.trigger)
  }
}
