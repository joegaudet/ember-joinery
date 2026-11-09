import Component from '@glimmer/component'
import { registerDestructor } from '@ember/destroyable'
import type Owner from '@ember/owner'
import { resizeObserver } from '@ember-joinery/primitives/resize-observer'

/**
 * The app's one ResizeObserver, used from JavaScript: the component makes its own element,
 * observes it, and stops when it goes. Drag the corner to resize it.
 */
export default class ResizeObserverDemo extends Component {
  #resizeObserver = resizeObserver(this)
  element = document.createElement('div')

  constructor(owner: Owner, args: object) {
    super(owner, args)
    this.element.dataset.testJn = 'resizable'
    this.element.style.cssText =
      'border: 2px dashed; resize: both; overflow: auto; padding: 0.5rem; width: 14rem; height: 5rem; box-sizing: border-box;'

    this.#resizeObserver.observe(this.element, this.handleResize)
    registerDestructor(this, () => {
      this.#resizeObserver.unobserve(this.element, this.handleResize)
    })
  }

  handleResize = (entry: ResizeObserverEntry) => {
    const { width, height } = entry.contentRect
    this.element.textContent = `( ${width} x ${height} )`
  }

  <template>{{this.element}}</template>
}
