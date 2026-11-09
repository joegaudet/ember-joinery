import type { TOC } from '@ember/component/template-only'
import { get } from '@ember/helper'
import type { ComponentLike } from '@glint/template'
import { As, type TagName } from '@ember-joinery/primitives/as'
import { part, type PartModifier } from '@ember-joinery/primitives/part'
import {
  staticPart,
  staticPartModifier,
  type StaticPartSignature,
} from '../-private/static-part.gts'

/** How an empty state's media looks: as it is, or an icon on a muted tile. */
export type EmptyMediaVariant = 'default' | 'icon'

/** What the media part takes, as a component (`@variant`) and as a modifier (`variant=`). */
export interface EmptyMediaOptions {
  /** Default `default`. */
  variant?: EmptyMediaVariant
}

const HEADER = { class: 'jn-empty-header', slot: 'empty-header', part: 'header' } as const
const TITLE = {
  class: 'jn-empty-title jn-font-heading',
  slot: 'empty-title',
  part: 'title',
} as const
const DESCRIPTION = {
  class: 'jn-empty-description',
  slot: 'empty-description',
  part: 'description',
} as const
const CONTENT = { class: 'jn-empty-content', slot: 'empty-content', part: 'content' } as const

/** The media's classes: upstream's semantic classes, renamed `jn-`. */
function mediaClasses({ variant = 'default' }: EmptyMediaOptions = {}): string {
  return `jn-empty-media jn-empty-media-${variant}`
}

/** The media's attributes. Its `data-slot` is upstream's, `empty-icon`, whatever it holds. */
function mediaAttributes({ variant = 'default' }: EmptyMediaOptions = {}): Record<string, string> {
  return { 'data-slot': 'empty-icon', 'data-variant': variant, 'data-test-jn-part': 'media' }
}

export interface EmptyMediaSignature {
  Args: EmptyMediaOptions & {
    /** The tag to render instead of `div`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

const EmptyMedia: TOC<EmptyMediaSignature> = <template>
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

/** What an empty state yields: its parts, each as a component and as a modifier. */
export interface EmptyParts {
  /** Wraps the media, title and description. */
  Header: ComponentLike<StaticPartSignature>
  /** An icon (`@variant="icon"` puts it on a tile), an image or an avatar. */
  Media: ComponentLike<EmptyMediaSignature>
  /** The title, in the theme's heading font. */
  Title: ComponentLike<StaticPartSignature>
  /** What the empty state means, muted; a link in it is underlined. */
  Description: ComponentLike<StaticPartSignature>
  /** A button, an input or a link. */
  Content: ComponentLike<StaticPartSignature>
  /** Makes your own element the header. */
  header: PartModifier<HTMLElement>
  /** `<img {{e.media}}>`, `<span {{e.media variant="icon"}}>`: makes your own element the media. */
  media: PartModifier<HTMLElement, EmptyMediaOptions>
  /** Makes your own element or component the title. */
  title: PartModifier<HTMLElement>
  /** Makes your own element the description. */
  description: PartModifier<HTMLElement>
  /** Makes your own element the content. */
  content: PartModifier<HTMLElement>
}

const PARTS: EmptyParts = {
  Header: staticPart(HEADER),
  Media: EmptyMedia,
  Title: staticPart(TITLE),
  Description: staticPart(DESCRIPTION),
  Content: staticPart(CONTENT),
  header: staticPartModifier(HEADER),
  media: part<HTMLElement, EmptyMediaOptions>(options => ({
    class: mediaClasses(options),
    attributes: mediaAttributes(options),
  })),
  title: staticPartModifier(TITLE),
  description: staticPartModifier(DESCRIPTION),
  content: staticPartModifier(CONTENT),
}

export interface EmptySignature {
  Args: {
    /** The tag to render instead of `div`. */
    as?: TagName
    /** The empty state's name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    default: [EmptyParts]
  }
  Element: HTMLElement
}

/**
 * Displays an empty state: shadcn's Empty. It fills the space it is given (`flex-1`) and
 * centres what it holds. Give it a border, a background or a height with your own classes.
 *
 *   <Empty as |e|>
 *     <e.Header>
 *       <e.Media @variant="icon"><Icon @icon={{FolderCode}} /></e.Media>
 *       <e.Title>No data</e.Title>
 *       <e.Description>No data found</e.Description>
 *     </e.Header>
 *     <e.Content><Button>Add data</Button></e.Content>
 *   </Empty>
 */
const Empty: TOC<EmptySignature> = <template>
  <As
    @as={{@as}}
    class="jn-empty"
    data-slot="empty"
    data-test-jn="empty"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield PARTS}}</As>
</template>

export default Empty
