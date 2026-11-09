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
    <div class="fake-window2" data-test-jn="sticky-footer-revealing">
      <StickyFooter class="sticky-container">
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
          {{! A <div>, where upstream has a <footer>: the site-wide footer below is the page's
              one footer landmark. }}
          <div class="sticky-footer">
            This is the footer
            <br /><br />
            some information can be hidden until scrolled to.
          </div>
        </:footer>
      </StickyFooter>

      <footer class="site-footer">
        site-wide footer
      </footer>
    </div>
    <style>
      /* styles that demonstrate the UX: upstream's, inside .fake-window2 so they stay in the
         example, and .container renamed, as Tailwind has its own */
      .fake-window2 .sticky-container {
        max-height: 200px;
        overflow: auto;
        position: relative;
        padding-bottom: 60px;
      }
      .fake-window2 [data-jn-sticky-footer-footer] {
        position: sticky;
        bottom: -38px;
      }
      .fake-window2 .sticky-footer,
      .fake-window2 footer.site-footer {
        border: 1px solid;
        background: #333;
        color: #fff;
      }
      .fake-window2 footer.site-footer {
        height: 38px;
        position: absolute;
        bottom: 0;
        left: 0;
        right: 0;
      }
      .fake-window2 {
        padding-bottom: 38px;
        min-height: 150px;
        max-height: 200px;
        position: relative;
        border: 1px solid;
        padding: 1rem;
        overflow: hidden;
      }
    </style>
  </template>
}
