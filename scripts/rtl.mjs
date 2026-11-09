// Makes a class list work in both text directions, the way upstream's registry build makes its
// right-to-left copies of the ui (`styles/<style>/ui-rtl`): shadcn's transformDirection, from
// the published `shadcn` package (in @shadcn/registry's transform-rtl), which the parity app
// runs as upstream's build does.
//
// Upstream ships two copies of each component, one per direction, and only for its Nova styles.
// Joinery ships one CSS for both: the physical sides become logical ones (`pl-2` → `ps-2`,
// `text-left` → `text-start`), which lay out the same left to right and flip right to left, and
// what has no logical form gets an `rtl:` twin (`translate-x-1/2` adds `rtl:-translate-x-1/2`).
// So left to right, every style renders as upstream's own, and right to left as its ui-rtl copy.
// port-styles.mjs runs this over the ported sheets and extract-classes.mjs over its rules.

/** Physical prefixes (or, without a trailing `-`, whole utilities) and their logical forms. */
export const LOGICAL = [
  ['-ml-', '-ms-'],
  ['-mr-', '-me-'],
  ['ml-', 'ms-'],
  ['mr-', 'me-'],
  ['pl-', 'ps-'],
  ['pr-', 'pe-'],
  ['-left-', '-start-'],
  ['-right-', '-end-'],
  ['left-', 'start-'],
  ['right-', 'end-'],
  ['inset-l-', 'inset-inline-start-'],
  ['inset-r-', 'inset-inline-end-'],
  ['rounded-tl-', 'rounded-ss-'],
  ['rounded-tr-', 'rounded-se-'],
  ['rounded-bl-', 'rounded-es-'],
  ['rounded-br-', 'rounded-ee-'],
  ['rounded-l-', 'rounded-s-'],
  ['rounded-r-', 'rounded-e-'],
  ['border-l-', 'border-s-'],
  ['border-r-', 'border-e-'],
  ['border-l', 'border-s'],
  ['border-r', 'border-e'],
  ['text-left', 'text-start'],
  ['text-right', 'text-end'],
  ['scroll-ml-', 'scroll-ms-'],
  ['scroll-mr-', 'scroll-me-'],
  ['scroll-pl-', 'scroll-ps-'],
  ['scroll-pr-', 'scroll-pe-'],
  ['float-left', 'float-start'],
  ['float-right', 'float-end'],
  ['clear-left', 'clear-start'],
  ['clear-right', 'clear-end'],
  ['origin-top-left', 'origin-top-start'],
  ['origin-top-right', 'origin-top-end'],
  ['origin-bottom-left', 'origin-bottom-start'],
  ['origin-bottom-right', 'origin-bottom-end'],
  ['origin-left', 'origin-start'],
  ['origin-right', 'origin-end'],
]

/** Utilities with no logical form, which get a mirrored `rtl:` twin. */
const MIRRORED_TRANSLATE = [
  ['-translate-x-', 'translate-x-'],
  ['translate-x-', '-translate-x-'],
]
const REVERSED = [
  ['space-x-', 'space-x-reverse'],
  ['divide-x-', 'divide-x-reverse'],
]
const CURSORS = [
  ['cursor-w-resize', 'cursor-e-resize'],
  ['cursor-e-resize', 'cursor-w-resize'],
]

/** Slide animations on a logical side, which become logical too. */
const SLIDES = [
  ['data-[side=inline-start]', 'slide-in-from-right', 'slide-in-from-end'],
  ['data-[side=inline-start]', 'slide-out-to-right', 'slide-out-to-end'],
  ['data-[side=inline-end]', 'slide-in-from-left', 'slide-in-from-start'],
  ['data-[side=inline-end]', 'slide-out-to-left', 'slide-out-to-start'],
]

/** The class transformStyle keeps for this transform: an icon that mirrors right to left. */
export const RTL_FLIP = 'jn-rtl-flip'

/** Positions that stay physical under a `data-[side=left|right]` variant. */
const POSITIONS = ['-left-', '-right-', 'left-', 'right-']

/**
 * A class split as upstream's transforms split one: its variants (everything before the last
 * top-level `:`), the utility, and its modifier (after the utility's last `/`).
 *
 *   splitClass('hover:bg-primary/80') // ['hover', 'bg-primary', '80']
 */
export function splitClass(name) {
  if (!name.includes('/') && !name.includes(':')) return [null, name, null]
  let colon = -1
  let depth = 0
  for (let index = name.length - 1; index >= 0; index--) {
    const char = name[index]
    if (char === ']') depth++
    else if (char === '[') depth--
    else if (char === ':' && depth === 0) {
      colon = index
      break
    }
  }
  const variants = colon === -1 ? null : name.slice(0, colon)
  const rest = colon === -1 ? name : name.slice(colon + 1)
  const slash = rest.lastIndexOf('/')
  if (slash === -1) return [variants, rest, null]
  return [variants, rest.slice(0, slash), rest.slice(slash + 1)]
}

function join(variants, utility, modifier) {
  const name = variants ? `${variants}:${utility}` : utility
  return modifier ? `${name}/${modifier}` : name
}

/** One class, as the classes that replace it. */
function logical(name) {
  if (name.startsWith('rtl:') || name.startsWith('ltr:')) return [name]
  if (name === RTL_FLIP) return ['rtl:rotate-180']
  const [variants, utility, modifier] = splitClass(name)
  if (!utility) return [name]

  for (const [from, to] of MIRRORED_TRANSLATE) {
    if (!utility.startsWith(from)) continue
    const mirrored = utility.replace(from, to)
    return [name, join(variants ? `rtl:${variants}` : 'rtl', mirrored, modifier)]
  }
  for (const [from, to] of REVERSED) {
    if (utility.startsWith(from)) return [name, join(variants ? `rtl:${variants}` : 'rtl', to)]
  }
  for (const [from, to] of CURSORS) {
    if (utility === from) return [name, join(variants ? `rtl:${variants}` : 'rtl', to)]
  }
  for (const [side, from, to] of SLIDES) {
    if (variants?.includes(side) && utility.startsWith(from)) {
      return [join(variants, utility.replace(from, to), modifier)]
    }
  }

  const physicalSide =
    variants?.includes('data-[side=left]') || variants?.includes('data-[side=right]')
  let mapped = utility
  for (const [from, to] of LOGICAL) {
    if (physicalSide && POSITIONS.some(position => from.startsWith(position))) continue
    if (!utility.startsWith(from)) continue
    if (!from.endsWith('-') && utility !== from) continue
    mapped = utility.replace(from, to)
    break
  }
  return [join(variants, mapped, modifier)]
}

/**
 * A space-separated class list, with physical sides made logical and an `rtl:` twin for what
 * has no logical form, as shadcn's transformDirection rewrites a className.
 *
 *   logicalClasses('pl-2 text-left translate-x-1/2')
 *   // 'ps-2 text-start translate-x-1/2 rtl:-translate-x-1/2'
 */
export function logicalClasses(classes) {
  return classes
    .split(' ')
    .flatMap(name => (name === '' ? [name] : logical(name)))
    .join(' ')
}
