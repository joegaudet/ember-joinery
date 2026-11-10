import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { modifier } from 'ember-modifier'
import { waitForPromise } from '@ember/test-waiters'

interface PreviewFrameSignature {
  Args: {
    /** The viewport's width, in CSS pixels. Without it, the frame is as wide as its container. */
    width?: number
    /**
     * The viewport's height, in CSS pixels, for a whole screen (an Example's `@block`). Without
     * it, the frame grows to the height of what it shows.
     */
    height?: number
    /** What the frame is, for assistive technology. */
    title: string
  }
  Blocks: { default: [] }
  Element: HTMLIFrameElement
}

/**
 * Puts a copy of the page's style sheets in the frame's document. A copied `<link>` loads its
 * sheet again (from the cache), so this resolves once every one has loaded, or failed to.
 */
function copyStyles(into: Document): Promise<void> {
  const loads: Promise<void>[] = []
  for (const sheet of document.querySelectorAll('style, link[rel="stylesheet"]')) {
    const copy = into.importNode(sheet, true) as HTMLElement
    if (copy.tagName === 'LINK') {
      loads.push(
        new Promise(resolve => {
          copy.addEventListener('load', () => resolve(), { once: true })
          copy.addEventListener('error', () => resolve(), { once: true })
        }),
      )
    }
    into.head.append(copy)
  }
  return Promise.all(loads).then(() => undefined)
}

/**
 * Keeps the frame on its page when a form in the example submits to nowhere. A form with no
 * `action` submits to its document's address, which for the frame is `about:srcdoc`: the frame
 * would navigate away and show nothing. Upstream's block pages, each in a frame of their own
 * address, reload instead, so a login form's submit leaves the block as it was; this does the
 * same for the guide's. A form with an `action`, or `method="dialog"`, goes on as it would.
 */
function stayPut(event: Event): void {
  // The frame's own HTMLFormElement, which `instanceof` on the page's wouldn't recognise.
  const form = event.target as HTMLFormElement | null
  if (!form || form.hasAttribute('action') || form.method === 'dialog') return
  event.preventDefault()
}

/**
 * An example at a given viewport width. The preview renders inside an `<iframe>` that wide, so
 * the example's breakpoints (`sm:`, `md:`) and its components' respond to that width, as they
 * would on a phone or a tablet. The block renders into the frame's body (Glimmer's
 * `in-element`) once a copy of the page's style sheets has loaded there, and the frame grows to
 * its height.
 */
export default class PreviewFrame extends Component<PreviewFrameSignature> {
  @tracked body: HTMLElement | undefined

  setup = modifier((iframe: HTMLIFrameElement) => {
    let observer: ResizeObserver | undefined
    let done: () => void = () => {}
    const loaded = new Promise<void>(resolve => (done = resolve))
    const ready = async () => {
      const doc = iframe.contentDocument
      if (!doc || this.isDestroying) return done()
      doc.documentElement.lang = document.documentElement.lang || 'en'
      doc.body.style.margin = '0'
      // Render once the styles are in, so the preview never shows unstyled.
      await copyStyles(doc)
      if (this.isDestroying || iframe.contentDocument !== doc) return done()
      if (this.args.height) {
        iframe.style.height = `${this.args.height}px`
      } else {
        observer = new ResizeObserver(() => {
          iframe.style.height = `${doc.documentElement.scrollHeight}px`
        })
        observer.observe(doc.body)
      }
      doc.addEventListener('submit', stayPut)
      this.body = doc.body
      done()
    }
    const onLoad = () => void ready()
    iframe.addEventListener('load', onLoad, { once: true })
    void waitForPromise(loaded)
    return () => {
      iframe.removeEventListener('load', onLoad)
      iframe.contentDocument?.removeEventListener('submit', stayPut)
      observer?.disconnect()
      done()
    }
  })

  <template>
    <iframe
      class="preview-frame"
      title={{@title}}
      width={{@width}}
      data-fill={{if @width undefined "true"}}
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
