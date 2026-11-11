import { module, test } from 'qunit'

/**
 * A page's `<Example @previewClass="…" @overflow="visible">` is upstream's
 * `<ComponentPreview previewClassName="…" className="overflow-visible">`, which
 * upstream/inventory.json records for each example. These check that a page passes what the
 * inventory has, and that examples.css compiles each class it passes (it scans the examples,
 * not the pages).
 */
const pages = import.meta.glob<string>('../../app/templates/**/*.md', {
  query: '?raw',
  import: 'default',
  eager: true,
})
const examplesCss = Object.values(
  import.meta.glob<string>('../../app/styles/examples.css', {
    query: '?raw',
    import: 'default',
    eager: true,
  }),
)[0]!

interface InventoryExample {
  name: string
  previewClassName?: string
  className?: string
}
interface Inventory {
  pages: Record<string, { examples: InventoryExample[] }>
}
const inventory = Object.values(
  import.meta.glob<Inventory>('../../../upstream/inventory.json', {
    import: 'default',
    eager: true,
  }),
)[0]!

const upstream = new Map<string, InventoryExample>()
for (const page of Object.values(inventory.pages)) {
  for (const example of page.examples) upstream.set(example.name, example)
}

interface FrameArgs {
  page: string
  name: string
  previewClass: string | undefined
  overflow: string | undefined
}

/** Every `<Example>` a page shows that sets `@previewClass` or `@overflow`. */
function framesWithPreviewArgs(): FrameArgs[] {
  const frames: FrameArgs[] = []
  for (const [path, source] of Object.entries(pages)) {
    for (const [tag] of source.matchAll(/<Example\b[^>]*>/g)) {
      const arg = (name: string) => new RegExp(`@${name}="([^"]*)"`).exec(tag)?.[1]
      const previewClass = arg('previewClass')
      const overflow = arg('overflow')
      if (previewClass === undefined && overflow === undefined) continue
      frames.push({
        page: path.replace('../../app/templates/', ''),
        name: arg('name') ?? '',
        previewClass,
        overflow,
      })
    }
  }
  return frames
}

/** The classes examples.css's `@source inline(…)` lines compile. */
function inlineClasses(): Set<string> {
  const classes = new Set<string>()
  for (const [, list] of examplesCss.matchAll(/@source\s+inline\(\s*['"]([^'"]*)['"]\s*\)/g)) {
    for (const name of list!.split(/\s+/).filter(Boolean)) classes.add(name)
  }
  return classes
}

module('Unit | preview classes', function () {
  test("a page's @previewClass and @overflow are upstream's, from the inventory", function (assert) {
    const frames = framesWithPreviewArgs()
    assert.ok(frames.length > 0, 'the Navigation Menu page passes them')
    for (const { page, name, previewClass, overflow } of frames) {
      const example = upstream.get(name)
      assert.ok(example, `${page}: ${name} is an upstream example`)
      if (previewClass !== undefined) {
        assert.strictEqual(
          previewClass,
          example?.previewClassName,
          `${page}: ${name}'s @previewClass is upstream's previewClassName`,
        )
      }
      if (overflow !== undefined) {
        assert.strictEqual(overflow, 'visible', `${page}: ${name}'s @overflow`)
        assert.ok(
          example?.className?.split(/\s+/).includes('overflow-visible'),
          `${page}: ${name}'s frame is overflow-visible upstream`,
        )
      }
    }
  })

  test('examples.css compiles every class a page passes as @previewClass', function (assert) {
    const compiled = inlineClasses()
    const missing = framesWithPreviewArgs()
      .flatMap(({ page, previewClass }) =>
        (previewClass ?? '')
          .split(/\s+/)
          .filter(Boolean)
          .map(name => ({ page, name })),
      )
      .filter(({ name }) => !compiled.has(name))
      .map(({ page, name }) => `${page}: ${name}`)
    assert.deepEqual(missing, [], "add these to examples.css's @source inline()")
  })
})
