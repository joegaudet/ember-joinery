import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { get } from '@ember/helper'
import type { ComponentLike } from '@glint/template'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { part, type PartModifier } from '@ember-joinery/primitives/part'
import Button, {
  buttonAttributes,
  buttonClasses,
  type ButtonSize,
  type ButtonVariant,
} from './button.gts'
import {
  staticPart,
  staticPartModifier,
  type StaticPartSignature,
} from '../-private/static-part.gts'
import {
  taggedPart,
  taggedPartModifier,
  type TaggedPartSignature,
} from '../-private/tagged-part.gts'

/** Where an attachment is in its upload: shadcn's five states. */
export type AttachmentState = 'idle' | 'uploading' | 'processing' | 'error' | 'done'

/** How big an attachment is. */
export type AttachmentSize = 'default' | 'sm' | 'xs'

/** Whether the media sits beside the content (`horizontal`) or above it (`vertical`). */
export type AttachmentOrientation = 'horizontal' | 'vertical'

/** What the media holds: an icon, or an `<img>` preview. */
export type AttachmentMediaVariant = 'icon' | 'image'

// ----- Media ---------------------------------------------------------------------------------

/** What the media part takes, as a component (`@variant`) and as a modifier (`variant=`). */
export interface AttachmentMediaOptions {
  /** Default `icon`. `image` crops an `<img>` inside it to a square. */
  variant?: AttachmentMediaVariant
}

/** The media's classes: upstream's semantic classes, renamed `jn-`. */
function mediaClasses({ variant = 'icon' }: AttachmentMediaOptions = {}): string {
  return `jn-attachment-media jn-attachment-media-variant-${variant}`
}

/** The media's attributes: upstream's, and its harness's part. */
function mediaAttributes({ variant = 'icon' }: AttachmentMediaOptions = {}): Record<
  string,
  string
> {
  return {
    'data-slot': 'attachment-media',
    'data-variant': variant,
    'data-test-jn-part': 'media',
  }
}

export interface AttachmentMediaSignature {
  Args: AttachmentMediaOptions & {
    /** The tag to render instead of `div`. */
    as?: TagName
  }
  /** An icon (`<Icon>`, a `<Spinner>`), or an `<img>` with `@variant="image"`. */
  Blocks: { default: [] }
  Element: HTMLElement
}

const AttachmentMedia: TOC<AttachmentMediaSignature> = <template>
  {{#let (mediaAttributes variant=@variant) as |attributes|}}
    <As
      @as={{@as}}
      class={{mediaClasses variant=@variant}}
      data-slot={{get attributes "data-slot"}}
      data-variant={{get attributes "data-variant"}}
      data-test-jn-part={{get attributes "data-test-jn-part"}}
      ...attributes
    >{{yield}}</As>
  {{/let}}
</template>

// ----- Content, Title, Description, Actions --------------------------------------------------

const CONTENT = {
  class: 'jn-attachment-content',
  slot: 'attachment-content',
  part: 'content',
} as const
const ACTIONS = {
  class: 'jn-attachment-actions',
  slot: 'attachment-actions',
  part: 'actions',
} as const
const TITLE = {
  tag: 'span',
  class: 'jn-attachment-title',
  slot: 'attachment-title',
  part: 'title',
} as const
const DESCRIPTION = {
  tag: 'span',
  class: 'jn-attachment-description',
  slot: 'attachment-description',
  part: 'description',
} as const

// ----- Action --------------------------------------------------------------------------------

/** What an action takes: a Button's look, with the attachment's defaults. */
export interface AttachmentActionOptions {
  /** Default `ghost`. */
  variant?: ButtonVariant
  /** Default `icon-xs`, a small square for an icon. */
  size?: ButtonSize
  /** Its name, for `ButtonHarness` (`data-test-jn-name`). */
  name?: string
}

/** An action's classes: a Button's, then the attachment's own. */
export function attachmentActionClasses({
  variant = 'ghost',
  size = 'icon-xs',
}: AttachmentActionOptions = {}): string {
  return `${buttonClasses({ variant, size })} jn-attachment-action`
}

/** An action's attributes: a Button's, with upstream's `data-slot`, and its harness's part. */
export function attachmentActionAttributes({
  variant = 'ghost',
  size = 'icon-xs',
  name,
}: AttachmentActionOptions = {}): Record<string, string | undefined> {
  return {
    ...buttonAttributes({ variant, size, name }),
    'data-slot': 'attachment-action',
    'data-test-jn-part': 'action',
  }
}

export interface AttachmentActionSignature {
  Args: AttachmentActionOptions & {
    /** The tag to render instead of `button`, such as `a` for a download link. */
    as?: TagName
  }
  /** Its icon. Name an icon-only action with `aria-label`, for what it does and to what. */
  Blocks: { default: [] }
  /** A `<button>`, as Joinery's Button, or with `@as="a"`, a link. */
  Element: HTMLButtonElement | HTMLAnchorElement
}

/**
 * An action on the attachment, such as removing it or retrying its upload: Joinery's Button,
 * `ghost` and `icon-xs` unless you say otherwise. Like upstream's (and Button), it sets no
 * `type`, so in a form give it `type="button"`.
 */
const AttachmentAction: TOC<AttachmentActionSignature> = <template>
  <Button
    @as={{@as}}
    @variant={{if @variant @variant "ghost"}}
    @size={{if @size @size "icon-xs"}}
    @name={{@name}}
    class="jn-attachment-action"
    data-slot="attachment-action"
    data-test-jn-part="action"
    ...attributes
  >{{yield}}</Button>
</template>

// ----- Trigger -------------------------------------------------------------------------------

const TRIGGER_ATTRIBUTES = {
  'data-slot': 'attachment-trigger',
  'data-test-jn-part': 'trigger',
} as const

export interface AttachmentTriggerSignature {
  Args: {
    /**
     * The tag to render instead of `button`: `a`, for a link that opens the file (upstream's
     * `asChild` on an `<a>`). For a component of your own, such as `LinkTo`, use `a.trigger`.
     */
    as?: TagName
  }
  /** It covers the card with no text of its own: name it with `aria-label`. */
  Blocks: { default: [] }
  /** A `<button>` (its `type` is `button`, unless you give another), or with `@as="a"`, a link. */
  Element: HTMLButtonElement | HTMLAnchorElement
}

class AttachmentTrigger extends Component<AttachmentTriggerSignature> {
  /** `button`, as upstream's, on a `<button>`; another tag has no `type`. */
  get type(): 'button' | undefined {
    const tag = this.args.as
    return !tag || tag === 'button' ? 'button' : undefined
  }

  <template>
    <As
      @as={{@as}}
      @tag="button"
      type={{this.type}}
      class="jn-attachment-trigger"
      data-slot="attachment-trigger"
      data-test-jn-part="trigger"
      ...attributes
    >{{yield}}</As>
  </template>
}

// ----- Parts ---------------------------------------------------------------------------------

/** What an attachment yields: its parts, each as a component and as a modifier for your own element. */
export interface AttachmentParts {
  /** The icon or image preview, at the start (or, `vertical`, on top). */
  Media: ComponentLike<AttachmentMediaSignature>
  /** Wraps the title and the description. */
  Content: ComponentLike<StaticPartSignature>
  /** The file's name, truncated to one line. It shimmers while `uploading` or `processing`. */
  Title: ComponentLike<TaggedPartSignature>
  /** What else there is to know: its type and size, its upload progress, or why it failed. */
  Description: ComponentLike<TaggedPartSignature>
  /** Holds the actions, at the end (or, `vertical`, over the media's corner). */
  Actions: ComponentLike<StaticPartSignature>
  /** An action: a `ghost`, `icon-xs` Button unless you say otherwise. */
  Action: ComponentLike<AttachmentActionSignature>
  /** A button (or `@as="a"`, a link) over the whole card, below the actions. */
  Trigger: ComponentLike<AttachmentTriggerSignature>
  /** Makes your own element the media, taking `variant=`. */
  media: PartModifier<HTMLElement, AttachmentMediaOptions>
  /** Makes your own element the content. */
  content: PartModifier<HTMLElement>
  /** Makes your own element the title. */
  title: PartModifier<HTMLElement>
  /** Makes your own element the description. */
  description: PartModifier<HTMLElement>
  /** Makes your own element the actions. */
  actions: PartModifier<HTMLElement>
  /** Makes your own element or component an action, taking `variant=`, `size=` and `name=`. */
  action: PartModifier<HTMLElement, AttachmentActionOptions>
  /** `<LinkTo {{a.trigger}}>`: makes your own element or component the trigger. */
  trigger: PartModifier<HTMLElement>
}

const PARTS: AttachmentParts = {
  Media: AttachmentMedia,
  Content: staticPart(CONTENT),
  Title: taggedPart(TITLE),
  Description: taggedPart(DESCRIPTION),
  Actions: staticPart(ACTIONS),
  Action: AttachmentAction,
  Trigger: AttachmentTrigger,
  media: part<HTMLElement, AttachmentMediaOptions>(options => ({
    class: mediaClasses(options),
    attributes: mediaAttributes(options),
  })),
  content: staticPartModifier(CONTENT),
  title: taggedPartModifier(TITLE),
  description: taggedPartModifier(DESCRIPTION),
  actions: staticPartModifier(ACTIONS),
  action: part<HTMLElement, AttachmentActionOptions>(options => ({
    class: attachmentActionClasses(options),
    attributes: attachmentActionAttributes(options),
  })),
  trigger: part<HTMLElement>(() => ({
    class: 'jn-attachment-trigger',
    attributes: TRIGGER_ATTRIBUTES,
  })),
}

// ----- Attachment ----------------------------------------------------------------------------

/** The classes an attachment renders: upstream's semantic classes, renamed `jn-`, and its marker. */
function attachmentClasses(
  size: AttachmentSize = 'default',
  orientation: AttachmentOrientation = 'horizontal',
): string {
  return `jn-attachment group/attachment jn-attachment-size-${size} jn-attachment-orientation-${orientation}`
}

export interface AttachmentSignature {
  Args: {
    /**
     * Default `done`. `idle` dashes the border; `uploading` and `processing` shimmer the title
     * (and dim an image); `error` turns it destructive. Say why in the description too, so the
     * state isn't told by colour alone.
     */
    state?: AttachmentState
    /** Default `default`. */
    size?: AttachmentSize
    /** Default `horizontal`, the media beside the content; `vertical` puts it on top. */
    orientation?: AttachmentOrientation
    /** The tag to render instead of `div`, such as `li` in a list of attachments. */
    as?: TagName
    /** The attachment's name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    default: [AttachmentParts]
  }
  Element: HTMLElement
}

/**
 * Displays a file or image attachment with media, metadata, upload state, and actions:
 * shadcn's Attachment.
 *
 *   <Attachment @state="uploading" as |a|>
 *     <a.Media><Spinner /></a.Media>
 *     <a.Content>
 *       <a.Title>sales-dashboard.pdf</a.Title>
 *       <a.Description>Uploading · 64%</a.Description>
 *     </a.Content>
 *     <a.Actions>
 *       <a.Action aria-label="Cancel upload"><Icon @icon={{X}} /></a.Action>
 *     </a.Actions>
 *   </Attachment>
 *
 * It is a layout, with no role of its own; a `Trigger` makes the whole card a button or a link,
 * and its actions stay clickable above it.
 */
const Attachment: TOC<AttachmentSignature> = <template>
  <As
    @as={{@as}}
    class={{attachmentClasses @size @orientation}}
    data-slot="attachment"
    data-state={{if @state @state "done"}}
    data-size={{if @size @size "default"}}
    data-orientation={{if @orientation @orientation "horizontal"}}
    data-test-jn="attachment"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield PARTS}}</As>
</template>

export default Attachment

export interface AttachmentGroupSignature {
  Args: {
    /** The tag to render instead of `div`, such as `ul` for a list of attachments. */
    as?: TagName
    /** The group's name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/**
 * Lays attachments out in a row that scrolls across, snapping to each one, with its edges
 * faded while there is more to see. A row of presentational attachments (no trigger, no
 * actions) can't be reached by Tab: give the group `tabindex="0"`, `role="group"` and an
 * `aria-label`, so a keyboard can scroll it.
 *
 *   <AttachmentGroup>
 *     <Attachment @orientation="vertical" as |a|>…</Attachment>
 *     <Attachment @orientation="vertical" as |a|>…</Attachment>
 *   </AttachmentGroup>
 */
export const AttachmentGroup: TOC<AttachmentGroupSignature> = <template>
  <As
    @as={{@as}}
    class="jn-attachment-group"
    data-slot="attachment-group"
    data-test-jn="attachment-group"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield}}</As>
</template>
