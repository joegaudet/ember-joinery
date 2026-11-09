/* global HTMLElementTagNameMap -- a DOM type, which ESLint's browser globals don't list */
import Component from '@glimmer/component'
import { array } from '@ember/helper'
import { dependencySatisfies, importSync, macroCondition } from '@embroider/macros'
// Only its type: the class itself is imported on Ember 6.12 alone, below.
// eslint-disable-next-line ember/no-classic-components
import type EmberComponent from '@ember/component'
import type { ComponentLike } from '@glint/template'

// The element's type is whichever tag the caller picks, so `As` declares it from `@tag`.
type ElementHelper = (tagName: string) => ComponentLike<{
  Element: any
  Blocks: { default: [] }
}>

interface ClassicElementSignature {
  Args: { tagName: string }
  Blocks: { default: [] }
  // Whichever tag `tagName` names; `As` declares the type from its `@tag`.
  Element: any
}

/**
 * Ember 7.1 and later have the `element` helper built in. Older versions (6.12 LTS) have no
 * public way to choose a tag at runtime other than a classic component's `tagName` (the
 * technique behind ember-element-helper), so `As` renders one there. The choice is made when the
 * app builds, and only a 6.12 build imports `@ember/component`.
 */
const builtinElement = (
  macroCondition(dependencySatisfies('ember-source', '>= 7.1.0-alpha.0'))
    ? (importSync('@ember/helper') as { element: ElementHelper }).element
    : undefined
) as ElementHelper | undefined

const hasBuiltinElement = builtinElement !== undefined

const ClassicElement = (
  macroCondition(dependencySatisfies('ember-source', '>= 7.1.0-alpha.0'))
    ? undefined
    : classicElement((importSync('@ember/component') as { default: typeof EmberComponent }).default)
) as ComponentLike<ClassicElementSignature>

/** The classic component `As` renders before Ember 7.1: its tag, its attributes and its block. */
function classicElement(Base: typeof EmberComponent): ComponentLike<ClassicElementSignature> {
  return class ClassicElement extends Base<ClassicElementSignature> {
    <template>{{yield}}</template>
  }
}

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
 * there is one (7.1 and later), and works the same on 6.12, where the element also gets the
 * `id="ember…"` and `ember-view` class Ember gives every classic component. A part's own `id`
 * replaces that id; don't depend on either.
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
