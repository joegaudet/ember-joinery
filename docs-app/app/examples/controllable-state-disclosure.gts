import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { controllable, type ControllableArgs } from '@ember-joinery/primitives/controllable-state'
import { idFor } from '@ember-joinery/primitives/id'

interface DisclosureSignature {
  Args: ControllableArgs<'open', boolean> & { label: string }
  Blocks: { default: [] }
}

/** A disclosure whose open state the caller can leave to it, or control. */
class Disclosure extends Component<DisclosureSignature> {
  open = controllable(this, 'open', false)

  toggle = () => this.open.set(open => !open)

  <template>
    <div class="cs-disclosure">
      <button
        type="button"
        aria-expanded={{if this.open.value "true" "false"}}
        aria-controls={{idFor this "content"}}
        {{on "click" this.toggle}}
      >{{@label}}</button>
      <div id={{idFor this "content"}} hidden={{if this.open.value false true}}>{{yield}}</div>
    </div>
  </template>
}

export default class ControllableStateDisclosure extends Component {
  @tracked open = false

  setOpen = (open: boolean) => (this.open = open)
  close = () => (this.open = false)

  <template>
    {{! Uncontrolled: the disclosure keeps its own state, starting open. }}
    <Disclosure @label="Uncontrolled" @defaultOpen={{true}}>It keeps its own state.</Disclosure>

    {{! Controlled: the state is ours, and the disclosure asks us to change it. }}
    <Disclosure @label="Controlled" @open={{this.open}} @onOpenChange={{this.setOpen}}>
      Its state lives in the parent.
    </Disclosure>
    <p>The controlled one is <output>{{if this.open "open" "closed"}}</output>.</p>
    <button type="button" {{on "click" this.close}}>Close it from outside</button>
  </template>
}
