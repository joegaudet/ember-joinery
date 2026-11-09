// Small components that render the data-test-jn attributes the way Joinery's components do,
// for testing the harness base (tests/integration/harness-test.gts) without depending on any
// real component.
import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { guidFor } from '@ember/object/internals'
import type { TOC } from '@ember/component/template-only'

interface FxToggleSignature {
  Args: { name?: string }
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

/** A toggle button. Its root is the <button>, and its state is `aria-pressed`. */
export class FxToggle extends Component<FxToggleSignature> {
  @tracked pressed = false

  toggle = () => (this.pressed = !this.pressed)

  <template>
    <button
      type="button"
      data-test-jn="fx-toggle"
      data-test-jn-name={{@name}}
      aria-pressed={{if this.pressed "true" "false"}}
      {{on "click" this.toggle}}
      ...attributes
    >{{yield}}</button>
  </template>
}

interface FxToolbarSignature {
  Args: { name?: string; label: string }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** A labelled group of controls. */
export const FxToolbar: TOC<FxToolbarSignature> = <template>
  <div
    role="group"
    aria-label={{@label}}
    data-test-jn="fx-toolbar"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield}}</div>
</template>

interface FxListSignature {
  Args: { name?: string; items: string[] }
  Blocks: { default: [item: string] }
  Element: HTMLUListElement
}

/** A list whose items are `item` parts keyed by `data-test-jn-value`. */
export const FxList: TOC<FxListSignature> = <template>
  <ul data-test-jn="fx-list" data-test-jn-name={{@name}} ...attributes>
    {{#each @items as |item|}}
      <li data-test-jn-part="item" data-test-jn-value={{item}}>{{item}}{{yield item}}</li>
    {{/each}}
  </ul>
</template>

interface FxDisclosureSignature {
  Args: {
    name?: string
    label: string
    /**
     * Where the content renders: inside the root (the default), in the top layer through the
     * Popover API, or portalled to the end of <body>. Outside the root, the content names the
     * root in `data-test-jn-owner`.
     */
    layer?: 'inline' | 'popover' | 'portal'
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** A trigger that shows and hides its content: `trigger` and `content` parts. */
export class FxDisclosure extends Component<FxDisclosureSignature> {
  id = guidFor(this)
  contentId = `${this.id}-content`

  @tracked open = false

  toggle = () => (this.open = !this.open)

  /** The Popover API fires `beforetoggle` synchronously, as the popover opens or closes. */
  sync = (event: ToggleEvent) => (this.open = event.newState === 'open')

  get layer() {
    return this.args.layer ?? 'inline'
  }

  get inPopover() {
    return this.layer === 'popover'
  }

  get inPortal() {
    return this.layer === 'portal'
  }

  get portalTarget() {
    return document.body
  }

  <template>
    <div id={{this.id}} data-test-jn="fx-disclosure" data-test-jn-name={{@name}} ...attributes>
      {{#if this.inPopover}}
        {{! The button opens the popover itself (popovertarget); the content stays rendered. }}
        <button
          type="button"
          data-test-jn-part="trigger"
          aria-expanded={{if this.open "true" "false"}}
          popovertarget={{this.contentId}}
        >{{@label}}</button>
        <div
          id={{this.contentId}}
          popover="manual"
          data-test-jn-part="content"
          data-test-jn-owner={{this.id}}
          {{on "beforetoggle" this.sync}}
        >
          {{yield}}
        </div>
      {{else}}
        <button
          type="button"
          data-test-jn-part="trigger"
          aria-expanded={{if this.open "true" "false"}}
          aria-controls={{if this.open this.contentId}}
          {{on "click" this.toggle}}
        >{{@label}}</button>
        {{#if this.open}}
          {{#if this.inPortal}}
            {{#in-element this.portalTarget insertBefore=null}}
              <div id={{this.contentId}} data-test-jn-part="content" data-test-jn-owner={{this.id}}>
                {{yield}}
              </div>
            {{/in-element}}
          {{else}}
            <div id={{this.contentId}} data-test-jn-part="content">{{yield}}</div>
          {{/if}}
        {{/if}}
      {{/if}}
    </div>
  </template>
}
