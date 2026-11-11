import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { uniqueId } from '@ember/helper'
import { on } from '@ember/modifier'
import { FocusScope } from '@ember-joinery/primitives/focus-scope'

export default class FocusScopeTrap extends Component {
  @tracked open = false
  @tracked name = 'Ada Lovelace'
  @tracked username = 'ada'

  show = () => (this.open = true)
  hide = () => (this.open = false)

  save = (event: SubmitEvent) => {
    event.preventDefault()
    const data = new FormData(event.currentTarget as HTMLFormElement)
    this.name = String(data.get('name'))
    this.username = String(data.get('username'))
    this.hide()
  }

  <template>
    <div class="focus-scope-example" data-test-jn="profile-editor">
      <p data-test-jn-part="summary">{{this.name}} (@{{this.username}})</p>
      <button type="button" data-test-jn-part="edit" {{on "click" this.show}}>Edit profile</button>
      {{#if this.open}}
        {{#let (uniqueId) as |titleId|}}
          <FocusScope
            @trapped={{true}}
            @loop={{true}}
            class="focus-scope-panel"
            role="dialog"
            aria-labelledby={{titleId}}
            data-test-jn-part="panel"
          >
            <form {{on "submit" this.save}}>
              <h3 id={{titleId}}>Edit profile</h3>
              <label>
                Name
                <input name="name" value={{this.name}} data-test-jn-part="name" />
              </label>
              <label>
                Username
                <input name="username" value={{this.username}} data-test-jn-part="username" />
              </label>
              <div class="focus-scope-actions">
                <button type="button" data-test-jn-part="cancel" {{on "click" this.hide}}>
                  Cancel
                </button>
                <button type="submit" data-test-jn-part="save">Save</button>
              </div>
            </form>
          </FocusScope>
        {{/let}}
      {{/if}}
    </div>
    <style>
      .focus-scope-example {
        display: grid;
        gap: 0.75rem;
        justify-items: start;
      }
      .focus-scope-example p {
        margin: 0;
      }
      .focus-scope-panel form {
        display: grid;
        gap: 0.75rem;
        padding: 1rem;
        border: 1px solid color-mix(in oklab, currentColor 20%, transparent);
        border-radius: 0.5rem;
      }
      .focus-scope-panel h3 {
        margin: 0;
        font-size: 1rem;
      }
      .focus-scope-panel label {
        display: grid;
        gap: 0.25rem;
      }
      .focus-scope-actions {
        display: flex;
        gap: 0.5rem;
        justify-content: end;
      }
    </style>
  </template>
}
