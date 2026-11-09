import Component from '@glimmer/component'
import { on } from '@ember/modifier'
import { StickyFooter } from '@ember-joinery/primitives/sticky-footer'
import { Content } from './sticky-footer/content.ts'

// Upstream's list is a module's; each example here has its own.
export default class StickyFooterExample extends Component {
  content = new Content()

  <template>
    {{! The data-test-jn attributes, which upstream's demo doesn't have, are what its test's
        harness finds the demo and its controls by. }}
    <div class="fake-window" data-test-jn="sticky-footer-demo">
      <StickyFooter>
        <:content>
          <button
            type="button"
            data-test-jn-part="add-content"
            {{on "click" this.content.addContent}}
          >Add Content</button>
          <button
            type="button"
            data-test-jn-part="remove-content"
            {{on "click" this.content.removeContent}}
          >Remove Content</button>
          <br />

          {{#each this.content.paragraphs as |paragraph|}}
            {{paragraph}}
          {{/each}}
        </:content>
        <:footer>
          <footer>
            This is the footer
          </footer>
        </:footer>
      </StickyFooter>
    </div>
    <style>
      /* styles for demo, not required */
      .fake-window footer {
        border: 1px solid;
      }
      .fake-window {
        height: 200px;
        border: 1px solid;
        overflow: auto;
        padding: 1rem;
      }
    </style>
  </template>
}
