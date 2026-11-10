import { test } from 'node:test'
import assert from 'node:assert/strict'
import { existsSync } from 'node:fs'
import {
  TAILWIND_SETUP,
  exclusive,
  extractClasses,
  findOverrides,
  overrides,
  partClassFor,
  renderCss,
  sheetRules,
  sizeMarker,
  splitClasses,
  unknownUtilities,
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

test("an icon sized by a class keeps a size- marker, so upstream's svg:not([class*='size-']) rules skip it", () => {
  const code = `
function Spinner({ className }) {
  return <IconPlaceholder lucide="Loader2Icon" data-slot="spinner" className={cn("size-4 animate-spin", className)} />
}
function Chevron() {
  return <ChevronDownIcon className="pointer-events-none md:size-3 opacity-50" />
}
function Box() {
  return <div data-slot="box" className="size-8 [&_svg:not([class*='size-'])]:size-4" />
}
`
  const entries = extractClasses(code)
  const [spinner, chevron, box] = entries
  assert.strictEqual(sizeMarker(spinner, entries), 'jn-size-4')
  assert.strictEqual(sizeMarker(chevron, entries), 'jn-size-own', 'a size behind a variant')
  assert.strictEqual(sizeMarker(box, entries), undefined, 'the rules look for icons only')
  const css = renderCss(entries, { name: 'spinner' })
  assert.match(
    css,
    /data-slot="spinner" in Spinner; keep on the element: jn-size-4 \*\/\n:where\(\.jn-spinner\)/,
  )

  // A semantic class of the element that already says size- is enough.
  const sized = extractClasses(
    'const v = cva("cn-x size-4", { variants: { size: { sm: "cn-x-size-sm" } } })\n',
  ).map(entry => ({ ...entry, element: 'svg' }))
  assert.strictEqual(sizeMarker(sized[0], sized), undefined)
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

test('renderCss makes physical sides logical, for both directions', () => {
  const css = renderCss(
    extractClasses('const x = cva("cn-x pl-2 text-left translate-x-1/2", { variants: {} })\n'),
    { name: 'x' },
  )
  assert.match(css, /@apply ps-2 text-start translate-x-1\/2 rtl:-translate-x-1\/2;/)
})

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

test("cn() puts every plain string's style rule first, as transformStyle does, so none overrides an inline utility", () => {
  // In a cn() call, transformStyle merges the style rules of every plain string's semantic
  // classes into the first string, ahead of its inline utilities: min-w-0 beats
  // .jn-badge-variant-outline's min-w-8 here, where in a cva it would lose.
  const source = `
function Tag({ className }) {
  return <span data-slot="tag" className={cn("cn-badge min-w-0", "cn-badge-variant-outline", className)} />
}
`
  const entries = findOverrides(extractClasses(source), SHEETS)
  assert.equal(entries[0].overriddenBy, undefined)
  assert.equal(entries[1].unresolved, undefined)
  const css = renderCss(entries, { name: 'tag', sheets: SHEETS })
  assert.match(css, /:where\(\.jn-badge\) \{\n {2}@apply min-w-0;\n\}/)
  assert.doesNotMatch(css, /:where\([^)]*:not\(|NOTE/)
})

test('a NOTE marks each semantic class the registry build never resolves', () => {
  const source = `
const badgeVariants = cva("cn-badge inline-flex", {
  variants: { size: { lg: "cn-badge-size-lg" } },
  compoundVariants: [{ size: "lg", className: "cn-badge-compound border-2" }],
})

function Calendar({ open, className }) {
  return (
    <DayPicker
      className={cn("cn-calendar p-2", open && "cn-calendar-open ring-2", open && "cn-rtl-flip", className)}
      classNames={{ dropdown_root: cn("cn-calendar-dropdown-root relative", defaultClassNames.dropdown_root) }}
    >
      <span data-slot="badge" className={cn("cn-badge px-1")} />
    </DayPicker>
  )
}
`
  const entries = extractClasses(source)
  const unresolved = Object.fromEntries(
    entries
      .filter(entry => entry.unresolved)
      .map(entry => [entry.unresolved.classes.join(' '), entry.unresolved.why]),
  )
  assert.deepEqual(unresolved, {
    'jn-badge-compound': 'it is in a cva compound variant',
    'jn-calendar-open': 'it is behind a condition',
    'jn-calendar-dropdown-root': 'its cn() call is in classNames, not a className',
    'jn-badge': 'a cva string of this file resolved it already',
  })
  assert.equal(
    entries.find(entry => entry.semantic.includes('jn-rtl-flip')).unresolved,
    undefined,
    'a class transformStyle keeps for its other transforms is not flagged',
  )
  assert.equal(entries.find(entry => entry.semantic.includes('jn-calendar')).unresolved, undefined)
  const css = renderCss(entries, { name: 'calendar', sheets: null })
  assert.match(
    css,
    /\/\* NOTE: upstream's registry build never resolves \.jn-calendar-dropdown-root here \(its cn\(\) call is in classNames, not a className\), so on ui\.shadcn\.com its style rule applies nowhere; to match, keep that class off this element, or its rule from reaching it\. \*\//,
  )
  assert.match(css, /never resolves \.jn-calendar-open here \(it is behind a condition\)/)
  assert.match(css, /never resolves \.jn-badge-compound here \(it is in a cva compound variant\)/)

  // A className that isn't the attribute itself but sits inside one is resolved, as upstream's
  // `className={open ? cn(…) : undefined}` is.
  const nested = extractClasses(
    `<div className={open ? cn("cn-panel p-2") : undefined} containerClassName={cn("cn-otp gap-1")} />`,
  )
  assert.equal(nested[0].unresolved, undefined)
  assert.equal(nested[1].unresolved.why, 'its cn() call is in containerClassName, not a className')
})

test("a <part>ClassName prop's rule goes on the part's own class, as Input OTP's container", () => {
  const entries = extractClasses(`
function InputOTP({ className, containerClassName, ...props }) {
  return (
    <OTPInput
      data-slot="input-otp"
      containerClassName={cn("cn-input-otp flex items-center", containerClassName)}
      className={cn("cn-input-otp-input disabled:cursor-not-allowed", className)}
    />
  )
}
`)
  assert.equal(partClassFor(entries[0]), 'jn-input-otp-container')
  assert.equal(partClassFor(entries[1]), undefined, 'a className is resolved')
  const css = renderCss(entries, { name: 'input-otp' })
  assert.match(css, /:where\(\.jn-input-otp-container\) \{\n {2}@apply flex items-center;\n\}/)
  assert.doesNotMatch(css, /:where\(\.jn-input-otp\)/)
  assert.match(
    css,
    /NOTE: upstream's registry build never resolves \.jn-input-otp here \(its cn\(\) call is in containerClassName, not a className\), so on ui\.shadcn\.com its style rule applies nowhere; this rule is on \.jn-input-otp-container instead, so give the element that class, and not \.jn-input-otp\./,
  )
  assert.match(css, /:where\(\.jn-input-otp-input\) \{/)
})

test("a NOTE marks a cn() string whose rule moves ahead of an earlier argument that isn't a string", () => {
  const source = `
function Next({ size, className }) {
  return <button data-slot="next" className={cn(buttonVariants({ size }), "cn-badge-variant-outline col-start-3", className)} />
}
`
  const entries = extractClasses(source)
  assert.deepEqual(entries[0].ahead, ['buttonVariants({ size })'])
  assert.match(
    renderCss(entries, { name: 'next', sheets: SHEETS }),
    /NOTE: upstream's registry build moves \.jn-badge-variant-outline's style rule to the front of this cn\(\) call, ahead of buttonVariants\(\{ size \}\), whose classes then beat it/,
  )
  // With no rule for the class in any style, there is nothing to move, and nothing to say.
  const bare = extractClasses(source.replace('cn-badge-variant-outline', 'cn-next'))
  assert.doesNotMatch(renderCss(bare, { name: 'next', sheets: SHEETS }), /NOTE/)
})

test('an element whose only semantic classes are kept ones gets its rule inside the nearest enclosing part', () => {
  // transformStyle keeps cn-rtl-flip on every icon it marks (Breadcrumb's separators, Pagination's
  // arrows, a sub-trigger's chevron), so a rule on .jn-rtl-flip alone would move all of them.
  const source = `
function SubTrigger({ className, children }) {
  return (
    <Primitive.SubTrigger data-slot="menu-sub-trigger" className={cn("cn-menu-sub-trigger flex", className)}>
      {children}
      <ChevronRightIcon className="cn-rtl-flip ml-auto size-4" />
    </Primitive.SubTrigger>
  )
}
function Nested() {
  return (
    <div data-slot="nested">
      <Wrapper>
        <ChevronRightIcon className={cn("cn-rtl-flip pl-1", open && "cn-rtl-flip pr-1")} />
      </Wrapper>
    </div>
  )
}
function Alone() {
  return <ChevronRightIcon className={cn("cn-rtl-flip size-4")} />
}
function Separator() {
  return (
    <li data-slot="separator" className="cn-separator">
      <ChevronRightIcon className="cn-rtl-flip" />
    </li>
  )
}
function Title() {
  return <h2 className="cn-font-heading cn-title text-pretty" />
}
`
  const entries = extractClasses(source)
  const kept = entries.filter(entry => entry.semantic[0] === 'jn-rtl-flip')
  assert.deepEqual(
    kept.map(entry => entry.within),
    [
      { class: 'jn-menu-sub-trigger', child: true },
      { class: 'jn-nested', child: false },
      { class: 'jn-nested', child: false },
      undefined,
      { class: 'jn-separator', child: true },
    ],
  )
  assert.equal(
    entries.find(entry => entry.semantic.includes('jn-title')).within,
    undefined,
    'an element with a class of its own needs no scope',
  )

  const css = renderCss(entries, { name: 'menu' })
  assert.match(
    css,
    /\/\* in SubTrigger; keep on the element: jn-size-4; inside \.jn-menu-sub-trigger only, since other parts share \.jn-rtl-flip \*\/\n:where\(\.jn-menu-sub-trigger\) > :where\(\.jn-rtl-flip\) \{\n {2}@apply ms-auto size-4;\n\}/,
    'a direct child, with its physical side made logical',
  )
  assert.match(css, /\n:where\(\.jn-nested\) :where\(\.jn-rtl-flip\) \{\n {2}@apply ps-1;\n\}/)
  assert.match(css, /only when open: pr-1/)
  assert.match(
    css,
    /in Alone, no slot to attach it to: size-4; keep on the element: jn-size-4 \*\//,
    'with no enclosing part, nothing to attach it to',
  )
  assert.match(
    css,
    /:where\(\.jn-title\) \{\n {2}@apply text-pretty;\n\}/,
    'the own class is the subject',
  )
  assert.match(css, /in Title; also: jn-font-heading \*\//)
  assert.doesNotMatch(css, /^:where\(\.jn-rtl-flip\)/m, 'no rule moves every jn-rtl-flip icon')
  assert.doesNotMatch(css, /jn-separator\)/, 'an icon with no utilities needs no rule')
})

test("renderCss leaves out a class Tailwind doesn't know, under a NOTE, so the file stays whole", () => {
  const entries = extractClasses(
    'const x = cva("cn-x relative origin-top-center mt-1 hover:origin-top-center", { variants: {} })\n',
  )
  const css = renderCss(entries, {
    name: 'x',
    unknown: new Set(['origin-top-center', 'hover:origin-top-center']),
  })
  assert.match(css, /:where\(\.jn-x\) \{\n {2}@apply relative mt-1;\n\}/)
  assert.match(
    css,
    /\/\* NOTE: upstream's list also has origin-top-center, hover:origin-top-center, which Tailwind has no utility for: they style nothing on ui\.shadcn\.com, [^*]*they are left out\. \*\//,
  )
  assert.doesNotMatch(css, /@apply[^;]*origin-top-center/, 'never @applied: the build would fail')

  const all = renderCss(entries, { name: 'x' })
  assert.match(all, /@apply relative origin-top-center mt-1 hover:origin-top-center;/, 'unchecked')
})

test(
  "unknownUtilities asks Tailwind, with the build's own setup, which classes it has no utility for",
  { skip: !existsSync(TAILWIND_SETUP.tailwind) && 'install the packages first' },
  async () => {
    const unknown = await unknownUtilities([
      'origin-top-center',
      'origin-top',
      'data-open:bg-muted/50',
      'group-data-[viewport=false]/navigation-menu:top-full',
      'bg-popover',
      'h-(--radix-navigation-menu-viewport-height)',
      'no-scrollbar',
      'zoom-in-90',
      'ps-2',
    ])
    assert.deepEqual([...unknown], ['origin-top-center'])
  },
)
