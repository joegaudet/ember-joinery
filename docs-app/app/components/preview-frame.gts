import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { modifier } from 'ember-modifier'
import { waitForPromise } from '@ember/test-waiters'

interface PreviewFrameSignature {
  Args: {
    /** The viewport's width, in CSS pixels. */
    width: number
    /** What the frame is, for assistive technology. */
    title: string
  }
  Blocks: { default: [] }
  Element: HTMLIFrameElement
}

/** Puts a copy of the page's style sheets in the frame's document. */
function copyStyles(into: Document): void {
  for (const sheet of document.querySelectorAll('style, link[rel="stylesheet"]')) {
    into.head.append(into.importNode(sheet, true))
  }
}

/**
 * An example at a given viewport width. The preview renders inside an `<iframe>` that wide, so
 * the example's breakpoints (`sm:`, `md:`) and its components' respond to that width, as they
 * would on a phone or a tablet. The block renders into the frame's body (Glimmer's
 * `in-element`), with a copy of the page's style sheets, and the frame grows to its height.
 */
export default class PreviewFrame extends Component<PreviewFrameSignature> {
  @tracked body: HTMLElement | undefined

  setup = modifier((iframe: HTMLIFrameElement) => {
    let observer: ResizeObserver | undefined
    let done: () => void = () => {}
    const loaded = new Promise<void>(resolve => (done = resolve))
    const ready = () => {
      const doc = iframe.contentDocument
      if (!doc || this.isDestroying) return done()
      doc.documentElement.lang = document.documentElement.lang || 'en'
      copyStyles(doc)
      doc.body.style.margin = '0'
      observer = new ResizeObserver(() => {
        iframe.style.height = `${doc.documentElement.scrollHeight}px`
      })
      observer.observe(doc.body)
      this.body = doc.body
      done()
    }
    iframe.addEventListener('load', ready, { once: true })
    void waitForPromise(loaded)
    return () => {
      iframe.removeEventListener('load', ready)
      observer?.disconnect()
      done()
    }
  })

  <template>
    <iframe
      class="preview-frame"
      title={{@title}}
      width={{@width}}
      srcdoc="<!doctype html><html><head><meta charset='utf-8'></head><body></body></html>"
      {{this.setup}}
      ...attributes
    ></iframe>
    {{#if this.body}}
      {{#in-element this.body}}
        {{yield}}
      {{/in-element}}
    {{/if}}
  </template>
}
