/*
 * How a chart's parts reach the chart. Glimmer has no context, so a chart yields its parts
 * (`<c.XAxis>`, `<c.Area>`) curried with itself, and each part registers on construction. The
 * chart's block renders before the marks inside its `<svg>`, so every part has registered by
 * the time the chart lays them out in the same render.
 *
 * A registration must not read what it writes: Glimmer forbids changing tracked state that the
 * same render has already read. So the list is a plain array, and a tracked revision is only
 * ever set, never read, by `register()`.
 */
import { tracked } from '@glimmer/tracking'

export class Registry<T> {
  #items: T[] = []
  #counter = 0
  @tracked private revision = 0

  /** Every registered item, in the order the parts were constructed. */
  get items(): readonly T[] {
    void this.revision
    return this.#items
  }

  add(item: T): void {
    this.#items = [...this.#items, item]
    this.revision = ++this.#counter
  }

  remove(item: T): void {
    if (!this.#items.includes(item)) return
    this.#items = this.#items.filter(other => other !== item)
    this.revision = ++this.#counter
  }
}
