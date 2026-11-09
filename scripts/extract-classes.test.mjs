import { test } from 'node:test'
import assert from 'node:assert/strict'
import {
  exclusive,
  extractClasses,
  findOverrides,
  overrides,
  renderCss,
  sheetRules,
  splitClasses,
} from './extract-classes.mjs'

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

const BADGE = `
const badgeVariants = cva(
  "cn-badge group/badge inline-flex min-w-0 focus-visible:ring-[3px] focus-visible:ring-ring/50",
  {
    variants: {
      variant: {
        default: "cn-badge-variant-default",
        destructive: "cn-badge-variant-destructive",
        outline: "cn-badge-variant-outline border-border",
      },
      size: { lg: "cn-badge-size-lg" },
    },
    compoundVariants: [{ variant: "outline", size: "lg", className: "border-2" }],
  }
)
`

/** Two styles' sheets, as upstream writes them (wrapped in `.style-<name>`). */
const SHEETS = {
  nova: sheetRules(`.style-nova {
  .cn-badge {
    @apply h-5 min-w-4 rounded-4xl;
  }

  .cn-badge-variant-default {
    @apply bg-primary border-transparent;
  }

  .cn-badge-variant-destructive {
    @apply bg-destructive/10 focus-visible:ring-destructive/20;
  }

  .cn-badge-variant-outline {
    @apply border-input min-w-8;
  }

  .cn-badge-size-lg:has(> svg) {
    @apply min-w-10;
  }
}
`),
  lyra: sheetRules(`.style-lyra {
  .cn-badge-variant-destructive {
    @apply focus-visible:ring-destructive/40;
  }

  .cn-badge-variant-outline {
    @apply border-input;
  }
}
`),
}

test('sheetRules maps each plain rule to its utilities, renamed jn-', () => {
  assert.deepEqual(
    [...SHEETS.nova.keys()],
    [
      'jn-badge',
      'jn-badge-variant-default',
      'jn-badge-variant-destructive',
      'jn-badge-variant-outline',
    ],
  )
  assert.deepEqual(SHEETS.nova.get('jn-badge'), ['h-5', 'min-w-4', 'rounded-4xl'])
})

test("overrides asks tailwind-merge, as upstream's cn, which of two classes survives", () => {
  assert.equal(overrides('focus-visible:ring-ring/50', 'focus-visible:ring-destructive/20'), true)
  assert.equal(overrides('focus-visible:ring-[3px]', 'focus-visible:ring-destructive/20'), false)
  assert.equal(overrides('min-w-0', 'min-w-40'), true)
  assert.equal(overrides('min-w-0', 'min-w-0'), false)
  assert.equal(overrides('ring-ring/50', 'focus-visible:ring-destructive/20'), false)
})

test('exclusive tells strings that never apply together', () => {
  const entries = extractClasses(BADGE)
  const [base, , destructive, outline, lg, compound] = entries
  assert.equal(exclusive(destructive, outline), true, 'two options of one variant')
  assert.equal(exclusive(base, destructive), false)
  assert.equal(exclusive(outline, lg), false, 'options of two variants')
  assert.equal(exclusive(destructive, compound), true, 'the compound wants variant="outline"')
  assert.equal(exclusive(outline, compound), false)
  assert.equal(exclusive({ condition: 'a && open' }, { condition: '!(open)' }), true)
  assert.equal(exclusive({ condition: 'open' }, { condition: 'size === "sm"' }), false)
})

test('findOverrides finds inline utilities a later class of the same call overrides', () => {
  const entries = findOverrides(extractClasses(BADGE), SHEETS)
  assert.deepEqual(entries[0].overriddenBy, [
    {
      utility: 'focus-visible:ring-ring/50',
      by: 'jn-badge-variant-destructive',
      with: ['focus-visible:ring-destructive/20', 'focus-visible:ring-destructive/40'],
      styles: ['nova', 'lyra'],
      every: true,
    },
    {
      utility: 'min-w-0',
      by: 'jn-badge-variant-outline',
      with: ['min-w-8'],
      styles: ['nova'],
      every: false,
    },
  ])
  assert.equal(entries[3].overriddenBy, undefined, 'options of one variant never meet')
})

test('renderCss keeps an overridden utility off the elements whose later class overrides it', () => {
  const css = renderCss(findOverrides(extractClasses(BADGE), SHEETS), { name: 'badge' })
  assert.match(css, /They go after the style sheet's rules/)
  assert.match(
    css,
    /:where\(\.jn-badge\) \{\n {2}@apply inline-flex min-w-0 focus-visible:ring-\[3px\];\n\}/,
    'the base rule loses the utility that every style overrides',
  )
  assert.match(
    css,
    /NOTE: upstream's later \.jn-badge-variant-outline overrides min-w-0 in nova, which this rule can't express; handle it in that style\./,
  )
  assert.match(
    css,
    /upstream's later \.jn-badge-variant-destructive overrides this in every style \*\/\n:where\(\.jn-badge:not\(\.jn-badge-variant-destructive\)\) \{\n {2}@apply focus-visible:ring-ring\/50;\n\}/,
  )
  assert.match(
    renderCss(extractClasses(BADGE), { name: 'badge', sheets: null }),
    /The style sheets were missing, so later classes were not checked\./,
  )
})

test('String.raw strings, cn() strings after the semantic one, and props like classNames', () => {
  const source = `
function Calendar({ className }) {
  return (
    <DayPicker
      className={cn("cn-calendar bg-background", String.raw\`rtl:**:[.rdp-button\\_next>svg]:rotate-180\`, className)}
      classNames={{ months: cn("relative flex", defaultClassNames.months) }}
    />
  )
}
`
  const entries = extractClasses(source)
  assert.deepEqual(entries[1].utilities, ['rtl:**:[.rdp-button\\_next>svg]:rotate-180'])
  assert.equal(entries[1].call, entries[0].call)
  assert.equal(entries[2].prop, 'classNames.months')
  assert.equal(entries[2].element, 'DayPicker')
  const css = renderCss(entries, { name: 'calendar' })
  assert.match(
    css,
    /:where\(\.jn-calendar\) \{\n {2}@apply rtl:\*\*:\[\.rdp-button\\_next>svg\]:rotate-180;\n\}/,
    'a later string of the call styles the same element',
  )
  assert.match(
    css,
    /DayPicker classNames\.months in Calendar, no slot to attach it to: relative flex/,
  )
})
