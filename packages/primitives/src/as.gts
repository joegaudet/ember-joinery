/* global HTMLElementTagNameMap -- a DOM type, which ESLint's browser globals don't list */
import Component from '@glimmer/component'
import { array } from '@ember/helper'
import { dependencySatisfies, importSync, macroCondition } from '@embroider/macros'
import type { ComponentLike } from '@glint/template'
import ClassicElement from './-private/classic-element.gts'

// The element's type is whichever tag the caller picks, so `As` declares it from `@tag`.
type ElementHelper = (tagName: string) => ComponentLike<{
  Element: any
  Blocks: { default: [] }
}>

/**
 * Ember 7.1 and later have the `element` helper built in. Older versions (6.12 LTS) render the
 * same thing through a classic component, below. The choice is made when the app builds.
 */
const builtinElement = (
  macroCondition(dependencySatisfies('ember-source', '>= 7.1.0-alpha.0'))
    ? (importSync('@ember/helper') as { element: ElementHelper }).element
    : undefined
) as ElementHelper | undefined

const hasBuiltinElement = builtinElement !== undefined

/** A tag name the browser knows, or any other (a custom element's). */
export type TagName = keyof HTMLElementTagNameMap | (string & {})

export interface AsSignature<Tag extends keyof HTMLElementTagNameMap> {
  Args: {
    /** The tag to render instead, from the part's caller: `<d.Trigger @as="span">`. */
    as?: TagName
    /** The part's own tag, when the caller gives no `@as`. Default `div`. */
    tag?: Tag
  }
  Blocks: { default: [] }
  Element: HTMLElementTagNameMap[Tag]
}

/**
 * An element whose tag the caller can change, for a part's `@as` argument (Radix's `asChild`
 * covers the same need, along with the part modifiers in `part`). It renders `@as`, or else
 * `@tag`, with the attributes, modifiers and block given to it:
 *
 *   <As @as={{@as}} @tag="button" type="button" {{this.trigger}} ...attributes>
 *     {{yield}}
 *   </As>
 *
 * The tag must be a real tag name (not empty). It uses Ember's built-in `element` helper where
 * there is one (7.1 and later), and works the same on 6.12.
 */
export class As<Tag extends keyof HTMLElementTagNameMap = 'div'> extends Component<
  AsSignature<Tag>
> {
  get tagName(): string {
    return this.args.as || this.args.tag || 'div'
  }

  <template>
    {{#if hasBuiltinElement}}
      {{#let (builtinElement this.tagName) as |Dynamic|}}
        <Dynamic ...attributes>{{yield}}</Dynamic>
      {{/let}}
    {{else}}
      {{! A classic component can't change its tag, so a new tag makes a new one. }}
      {{#each (array this.tagName) key="@identity" as |tagName|}}
        {{#let (component ClassicElement tagName=tagName) as |Dynamic|}}
          <Dynamic ...attributes>{{yield}}</Dynamic>
        {{/let}}
      {{/each}}
    {{/if}}
  </template>
}
