import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { modifier } from 'ember-modifier'
import { viewport } from '@ember-joinery/primitives/viewport'

/** Pauses a (pretend) video while it is scrolled out of view, with the app's shared observer. */
export default class ViewportVisibility extends Component {
  @tracked visible = false

  onChange = (entry: IntersectionObserverEntry) => (this.visible = entry.isIntersecting)

  watch = modifier((element: Element) => {
    const observers = viewport(this)
    observers.observe(element, this.onChange, { threshold: 0.5 })
    return () => observers.unobserve(element, this.onChange)
  })

  <template>
    <div
      data-test-jn="feed"
      tabindex="0"
      aria-label="A feed"
      style="height: 10rem; overflow: auto; border: 1px solid; padding: 0 1rem; border-radius: 0.5rem;"
    >
      <p data-test-jn-part="top">Scroll the video in and out of view.</p>
      <p style="height: 12rem;">A post.</p>
      <div
        data-test-jn-part="video"
        style="height: 5rem; display: grid; place-items: center; border: 1px dashed;"
        {{this.watch}}
      >
        <span data-test-jn-part="status">{{if this.visible "Playing" "Paused"}}</span>
      </div>
      <p style="height: 12rem;">Another post.</p>
    </div>
  </template>
}
