import { test } from 'node:test'
import assert from 'node:assert/strict'
import { extractClasses, renderCss, splitClasses } from './extract-classes.mjs'

const BUTTON = `
import { cva } from "class-variance-authority"
import { cn } from "cn"

const buttonVariants = cva(
  "cn-button group/button inline-flex shrink-0 items-center [&_svg]:shrink-0",
  {
    variants: {
      variant: {
        default: "cn-button-variant-default",
        link: "cn-button-variant-link underline-offset-4",
      },
      size: { sm: "cn-button-size-sm" },
    },
    compoundVariants: [{ variant: "link", size: "sm", className: "px-0" }],
    defaultVariants: { variant: "default" },
  }
)

function Card({ className, size }) {
  return (
    <div
      data-slot="card"
      className={cn("cn-card cn-font-heading group/card flex flex-col", className)}
    >
      <span className="sr-only">Close</span>
      <div data-slot="card-header" className={cn("grid", size === "sm" && "gap-1", open ? "p-2" : "p-4")} />
    </div>
  )
}
`

test('splitClasses separates semantic classes, markers and utilities', () => {
  assert.deepEqual(
    splitClasses('cn-card group/card group peer/x flex  @container/card-header p-[1px]'),
    {
      semantic: ['jn-card'],
      markers: ['group/card', 'group', 'peer/x'],
      utilities: ['flex', '@container/card-header', 'p-[1px]'],
    },
  )
})

test('extractClasses finds cva bases, variants, compounds, cn() strings and className strings', () => {
  const entries = extractClasses(BUTTON)
  const summary = entries.map(({ origin, slot, variant, condition, semantic, utilities }) => ({
    origin,
    ...(slot && { slot }),
    ...(variant && { variant }),
    ...(condition && { condition }),
    semantic,
    utilities,
  }))
  assert.deepEqual(summary, [
    {
      origin: 'cva',
      semantic: ['jn-button'],
      utilities: ['inline-flex', 'shrink-0', 'items-center', '[&_svg]:shrink-0'],
    },
    {
      origin: 'cva-variant',
      variant: 'variant.default',
      semantic: ['jn-button-variant-default'],
      utilities: [],
    },
    {
      origin: 'cva-variant',
      variant: 'variant.link',
      semantic: ['jn-button-variant-link'],
      utilities: ['underline-offset-4'],
    },
    { origin: 'cva-variant', variant: 'size.sm', semantic: ['jn-button-size-sm'], utilities: [] },
    {
      origin: 'cva-compound',
      variant: 'variant="link" size="sm"',
      semantic: [],
      utilities: ['px-0'],
    },
    {
      origin: 'cn',
      slot: 'card',
      semantic: ['jn-card', 'jn-font-heading'],
      utilities: ['flex', 'flex-col'],
    },
    { origin: 'className', semantic: [], utilities: ['sr-only'] },
    { origin: 'cn', slot: 'card-header', semantic: [], utilities: ['grid'] },
    {
      origin: 'cn',
      slot: 'card-header',
      condition: 'size === "sm"',
      semantic: [],
      utilities: ['gap-1'],
    },
    { origin: 'cn', slot: 'card-header', condition: 'open', semantic: [], utilities: ['p-2'] },
    { origin: 'cn', slot: 'card-header', condition: '!(open)', semantic: [], utilities: ['p-4'] },
  ])
  assert.equal(entries[0].function, 'buttonVariants')
  assert.deepEqual(entries[0].markers, ['group/button'])
  assert.equal(entries[5].function, 'Card')
  assert.equal(entries[5].element, 'div')
})

test('renderCss writes a rule per slot and comments for the rest', () => {
  const css = renderCss(extractClasses(BUTTON), {
    name: 'button',
    commit: '8ab27715521cbd4f87ae6886cd989cbb678f6de7',
  })
  assert.match(css, /registry\/bases\/radix\/ui\/button\.tsx \(shadcn-ui\/ui@8ab2771\)/)
  assert.match(
    css,
    /\/\* in buttonVariants; keep on the element: group\/button \*\/\n:where\(\.jn-button\) \{\n {2}@apply inline-flex shrink-0 items-center \[&_svg\]:shrink-0;\n\}/,
  )
  assert.match(css, /:where\(\.jn-button-variant-link\) \{\n {2}@apply underline-offset-4;\n\}/)
  assert.doesNotMatch(css, /:where\(\.jn-button-variant-default\)/, 'no rule without utilities')
  assert.match(
    css,
    /\/\* in buttonVariants \(cva-compound variant="link" size="sm"\), no slot to attach it to: px-0 \*\//,
  )
  assert.match(
    css,
    /data-slot="card" in Card; keep on the element: group\/card; also: jn-font-heading \*\/\n:where\(\.jn-card\)/,
  )
  assert.match(
    css,
    /:where\(\.jn-card-header\) \{\n {2}@apply grid;\n\}/,
    'a slot without a semantic class',
  )
  assert.match(css, /only when size === "sm": gap-1 \*\//)
  assert.match(css, /in Card, no slot to attach it to: sr-only/)
})
