import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import type { TOC } from '@ember/component/template-only'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { controllable, type ControllableArgs } from '@ember-joinery/primitives/controllable-state'
import { idFor } from '@ember-joinery/primitives/id'
import { part, type PartModifier } from '@ember-joinery/primitives/part'

interface TriggerSignature {
  Args: { part: PartModifier; as?: TagName }
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

/** The trigger part: a button, or `@as`, with the part's attributes and listeners. */
const Trigger: TOC<TriggerSignature> = <template>
  <As @as={{@as}} @tag="button" ...attributes {{@part}}>{{yield}}</As>
</template>

interface CollapsibleSignature {
  Args: ControllableArgs<'open', boolean>
  Blocks: {
    default: [
      {
        Trigger: WithBoundArgs<typeof Trigger, 'part'>
        trigger: PartModifier
        isOpen: boolean
        contentId: string
      },
    ]
  }
}

/** A collapsible written the way Joinery's components are: each part is a modifier too. */
class Collapsible extends Component<CollapsibleSignature> {
  open = controllable(this, 'open', false)

  trigger = part(() => ({
    attributes: {
      'aria-expanded': String(this.open.value),
      'aria-controls': idFor(this, 'content'),
      'data-state': this.open.value ? 'open' : 'closed',
    },
    on: { click: () => this.open.set(open => !open) },
  }))

  <template>
    {{yield
      (hash
        Trigger=(component Trigger part=this.trigger)
        trigger=this.trigger
        isOpen=this.open.value
        contentId=(idFor this "content")
      )
    }}
  </template>
}

<template>
  <Collapsible as |c|>
    {{! The part's own component, rendered as a <button> }}
    <c.Trigger type="button">Show the details</c.Trigger>
    {{! The same part on an element of your own }}
    <a href="#details" {{c.trigger}}>or this link</a>
    <p id={{c.contentId}} hidden={{if c.isOpen false true}}>The details.</p>
  </Collapsible>
</template>
