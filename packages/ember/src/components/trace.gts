import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import type { ComponentLike, WithBoundArgs } from '@glint/template'
import { ChevronRight } from 'lucide'
import { As, type TagName } from '@ember-joinery/primitives/as'
import {
  CollapsibleContent as HeadlessContent,
  CollapsibleState,
} from '@ember-joinery/primitives/collapsible'
import { part, type PartModifier, type PartSpec } from '@ember-joinery/primitives/part'
import Icon, { type IconNode } from './icon.gts'
import {
  taggedPart,
  taggedPartModifier,
  type TaggedPartSignature,
} from '../-private/tagged-part.gts'

/** The state of the work a line reports: under way, failed, or not started. None is done. */
export type TraceLineStatus = 'running' | 'error' | 'pending'

const ICON = {
  tag: 'span',
  class: 'jn-trace-icon',
  slot: 'trace-icon',
  part: 'icon',
  attributes: { 'aria-hidden': 'true' },
} as const
const TITLE = {
  tag: 'span',
  class: 'jn-trace-title',
  slot: 'trace-title',
  part: 'title',
} as const
const DESCRIPTION = {
  tag: 'span',
  class: 'jn-trace-description',
  slot: 'trace-description',
  part: 'description',
} as const

/**
 * A decorative icon slot, hidden from assistive technology (`aria-hidden`), so the title is the
 * line's name. Before the title it names the action; after it, it is the indicator (a chevron
 * for a row that opens something, an arrow for a link out). An icon in it is 16px unless it has
 * a size of its own.
 */
export const TraceIcon: TOC<TaggedPartSignature> = taggedPart(ICON)

/** One sentence on one line: what happened. It truncates, and shimmers while the line runs. */
export const TraceTitle: TOC<TaggedPartSignature> = taggedPart(TITLE)

/** Secondary text after the title, such as a count or a duration. It doesn't truncate. */
export const TraceDescription: TOC<TaggedPartSignature> = taggedPart(DESCRIPTION)

/** What a `<TraceLine>` yields: its parts, each as a component and as a modifier. */
export interface TraceLineParts {
  /** A decorative icon slot, hidden from assistive technology. */
  Icon: ComponentLike<TaggedPartSignature>
  /** The line's title, its accessible name. */
  Title: ComponentLike<TaggedPartSignature>
  /** Secondary text after the title. */
  Description: ComponentLike<TaggedPartSignature>
  /** Makes your own element the icon's slot, hidden from assistive technology. */
  icon: PartModifier<HTMLElement>
  /** Makes your own element the title. */
  title: PartModifier<HTMLElement>
  /** Makes your own element the description. */
  description: PartModifier<HTMLElement>
}

const LINE_PARTS: TraceLineParts = {
  Icon: TraceIcon,
  Title: TraceTitle,
  Description: TraceDescription,
  icon: taggedPartModifier(ICON),
  title: taggedPartModifier(TITLE),
  description: taggedPartModifier(DESCRIPTION),
}

export interface TraceLineSignature {
  Args: {
    /** The state of the work it reports. None for work that is done. */
    status?: TraceLineStatus
    /** The tag to render instead of `span`. */
    as?: TagName
    /** Its name, for `TraceLineHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: { default: [TraceLineParts] }
  Element: HTMLSpanElement
}

/**
 * One line of a trace: an icon and a title, then an optional description and indicator. It is a
 * `span`, so it is neither a button nor a tab stop: to make a line do something, wrap it in
 * that thing's trigger (a `TraceCollapsible`'s, a dialog's or a sheet's) or in a link.
 *
 *   <TraceLine @status="running" as |l|>
 *     <l.Icon><Icon @icon={{LoaderCircle}} class="animate-spin" /></l.Icon>
 *     <l.Title>Running pnpm build</l.Title>
 *   </TraceLine>
 *
 * `@status` is shown with colour and motion only, so say it in the title too.
 */
export const TraceLine: TOC<TraceLineSignature> = <template>
  <As
    @as={{@as}}
    @tag="span"
    class="jn-trace-line"
    data-slot="trace-line"
    data-status={{@status}}
    data-test-jn="trace-line"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield LINE_PARTS}}</As>
</template>

export interface TraceSignature {
  Args: {
    /** The tag to render instead of `div`. */
    as?: TagName
    /** Its name, for `TraceHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * The building block for reasoning, tool calls, sources and more: shadcn's Trace, a list of
 * lines that sit next to each other. It adds no role: each line takes its semantics from what
 * wraps it. It also styles any trigger or link that wraps a `TraceLine` (rounded, with a focus
 * ring), so those need no classes of their own:
 *
 *   <Trace>
 *     <TraceLine as |l|>
 *       <l.Icon><Icon @icon={{Search}} /></l.Icon>
 *       <l.Title>Searched for minimumReleaseAge</l.Title>
 *     </TraceLine>
 *     <a href="https://pnpm.io">
 *       <TraceLine as |l|>…</TraceLine>
 *     </a>
 *   </Trace>
 */
const Trace: TOC<TraceSignature> = <template>
  <As
    @as={{@as}}
    @tag="div"
    class="jn-trace"
    data-slot="trace"
    data-test-jn="trace"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield}}</As>
</template>

export default Trace

/** A part's spec, with its `data-slot` added. */
function withSlot(spec: PartSpec, slot: string): PartSpec {
  return { ...spec, attributes: { ...spec.attributes, 'data-slot': slot } }
}

export interface TraceCollapsibleTriggerSignature {
  Args: {
    /** The chevron after the line, which turns as the row opens. Default lucide's `chevron-right`. */
    icon?: IconNode
    /** @internal Bound by the collapsible. */
    part: PartModifier
  }
  Blocks: { default: [] }
  Element: HTMLButtonElement
}

/**
 * The button that opens and closes the row, yielded as `c.Trigger`. Put a `TraceLine` in it; it
 * adds a chevron after the line, which turns a quarter while open. Like upstream's, it is always
 * a `<button>` of its own (upstream's takes no `asChild`), since the chevron is part of it.
 */
const TraceCollapsibleTrigger: TOC<TraceCollapsibleTriggerSignature> = <template>
  <button
    type="button"
    class="jn-trace-collapsible-trigger group/trace-collapsible-trigger"
    data-slot="trace-collapsible-trigger"
    ...attributes
    {{@part}}
  >
    {{yield}}
    <span
      class="jn-trace-icon jn-trace-collapsible-trigger-icon"
      data-slot="trace-icon"
      data-test-jn-part="indicator"
      aria-hidden="true"
    ><Icon @icon={{if @icon @icon ChevronRight}} /></span>
  </button>
</template>

export interface TraceCollapsibleContentSignature {
  Args: {
    /** @internal Bound by the collapsible. */
    collapsible: CollapsibleState
    /** @internal Bound by the collapsible. */
    part: PartModifier<HTMLElement, { shown: boolean }>
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * The detail of a row that expands, yielded as `c.Content`: indented under the line, behind a
 * border on its start side, with its text muted. It animates open and closed, and its element
 * stays in the document, `hidden` and empty, while closed. A class or attribute you give it goes
 * on its inner element, which lays the detail out (`<c.Content class="flex flex-wrap gap-1.5">`),
 * as upstream's `className` does.
 */
const TraceCollapsibleContent: TOC<TraceCollapsibleContentSignature> = <template>
  <HeadlessContent
    @collapsible={{@collapsible}}
    @part={{@part}}
    class="jn-trace-collapsible-content"
    data-slot="trace-collapsible-content"
  >
    <div
      class="jn-trace-collapsible-content-inner"
      data-slot="trace-collapsible-content-inner"
      ...attributes
    >{{yield}}</div>
  </HeadlessContent>
</template>

/** What `<TraceCollapsible>` yields. */
export interface TraceCollapsibleYield {
  /** The button that opens and closes the row: `<c.Trigger><TraceLine …/></c.Trigger>`. */
  Trigger: WithBoundArgs<typeof TraceCollapsibleTrigger, 'part'>
  /** The detail it shows and hides: `<c.Content>…</c.Content>`. */
  Content: WithBoundArgs<typeof TraceCollapsibleContent, 'collapsible' | 'part'>
  /** Whether it is open. */
  isOpen: boolean
  /** Opens or closes it. */
  toggle: () => void
}

export interface TraceCollapsibleSignature {
  Args: {
    /** The controlled open state. Pass `@onOpenChange` too, to hear the trigger. */
    open?: boolean
    /** Whether it starts open, when uncontrolled. Default `false`. */
    defaultOpen?: boolean
    /** Called with each new open state. */
    onOpenChange?: (open: boolean) => void
    /** Whether the trigger can't open or close it. */
    disabled?: boolean
    /** Its name, for `TraceCollapsibleHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: { default: [TraceCollapsibleYield] }
  Element: HTMLDivElement
}

/**
 * A trace row that expands to show more: shadcn's `TraceCollapsible`, on the primitives'
 * `CollapsibleState`. Put a `TraceLine` in its trigger and the detail in its content:
 *
 *   <TraceCollapsible as |c|>
 *     <c.Trigger>
 *       <TraceLine as |l|>
 *         <l.Icon><Icon @icon={{Terminal}} /></l.Icon>
 *         <l.Title>Ran node --version</l.Title>
 *       </TraceLine>
 *     </c.Trigger>
 *     <c.Content>v24.18.0</c.Content>
 *   </TraceCollapsible>
 *
 * Rows start closed: `@defaultOpen` starts one open, and `@open` with `@onOpenChange` controls
 * it. To open a row while it streams and let the reader's click win, pass
 * `@open={{this.openOrRunning}}` (the reader's choice, else whether it runs).
 */
export class TraceCollapsible extends Component<TraceCollapsibleSignature> {
  collapsible = new CollapsibleState({
    open: () => this.args.open,
    defaultOpen: () => this.args.defaultOpen,
    onOpenChange: () => this.args.onOpenChange,
    disabled: () => this.args.disabled,
  })

  /** The headless trigger, with upstream's `data-slot`. */
  trigger: PartModifier = part(() =>
    withSlot(this.collapsible.triggerSpec(), 'trace-collapsible-trigger'),
  )

  /** The headless content, with upstream's `data-slot`. */
  content: PartModifier<HTMLElement, { shown: boolean }> = part<HTMLElement, { shown: boolean }>(
    named => withSlot(this.collapsible.contentSpec(named), 'trace-collapsible-content'),
  )

  <template>
    <div
      class="jn-trace-collapsible"
      data-slot="trace-collapsible"
      data-state={{this.collapsible.dataState}}
      data-disabled={{if this.collapsible.isDisabled ""}}
      data-test-jn="trace-collapsible"
      data-test-jn-name={{@name}}
      ...attributes
    >
      {{yield
        (hash
          Trigger=(component TraceCollapsibleTrigger part=this.trigger)
          Content=(component TraceCollapsibleContent collapsible=this.collapsible part=this.content)
          isOpen=this.collapsible.isOpen
          toggle=this.collapsible.toggle
        )
      }}
    </div>
  </template>
}
