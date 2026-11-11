/*
 * How a chart's parts reach the chart. Glimmer has no context, so a chart yields its parts
 * (`<c.XAxis>`, `<c.Area>`) curried with itself, and each part registers on construction. The
 * chart's block renders before the marks inside its `<svg>`, so every part has registered by
 * the time the chart lays them out in the same render.
 *
 * Glimmer's debug build forbids changing tracked state that the same render has already read
 * ("You attempted to update `revision`… but it had already been used previously in the same
 * computation"). A registration sets `revision`, so nothing may read `items` earlier in a render
 * than the block that registers: not in the first render, and not in a later one, where a part
 * the block adds inside an `{{#if}}` registers while the render revalidates the template in
 * order. The chart reads its parts only after its `{{yield}}` (an attribute on the wrapper, which
 * is evaluated before the block, would trip it). And a registration never reads what it writes:
 * the list is a plain array, and `add()` and `remove()` only set the revision.
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
