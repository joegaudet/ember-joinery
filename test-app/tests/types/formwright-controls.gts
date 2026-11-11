/**
 * Type-only fixture: `pnpm typecheck` checks that Joinery's Formwright controls are typed: each
 * fits the paths that can hold what it stores, and takes its own args. Each
 * `@glint-expect-error` asserts that the line below it is rejected. Nothing here renders.
 */
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'
import '@ember-joinery/formwright'

interface Tag {
  id: string
  label: string
  blurb: string
}

interface Settings {
  name: string
  stars: number | null
  volume: number
  range: number[]
  dark: boolean
  plan: string | null
  size: 'sm' | 'lg'
  tags: Tag[]
  birthday: Date | null
  code: string
}

const plans = ['free', 'team']
const sizes = ['sm', 'lg'] as const
const tags: Tag[] = [{ id: 'a', label: 'A', blurb: 'The first' }]

/** Each of Joinery's controls fits the paths that can hold what it stores. */
export const Fits: TOC<{ Args: { settings: Settings } }> = <template>
  <Form @model={{@settings}} as |f|>
    <f.Field @for="name" @maxLength={{20}} as |field|>
      <field.Control @autocomplete="name" />
    </f.Field>
    <f.Field @for="name" @control="textarea" as |field|><field.Control @rows={{4}} /></f.Field>
    <f.Field @for="stars" @control="rating" @max={{5}} />
    <f.Field @for="volume" @control="slider" @min={{0}} @max={{11}} />
    <f.Field @for="volume" @control="range" />
    <f.Field @for="range" @control="slider" />
    <f.Field @for="dark" @control="switch" />
    <f.Field @for="dark" @control="toggle" />
    <f.Field @for="dark" @control="checkbox" />
    <f.Field @for="plan" @control="select" @options={{plans}} as |field|>
      <field.Control @size="sm" />
    </f.Field>
    <f.Field @for="plan" @control="combobox" @options={{plans}} />
    <f.Field @for="plan" @control="native-select" @options={{plans}} />
    <f.Field @for="size" @control="radio" @options={{sizes}} as |field|>
      <field.Control @variant="card" />
    </f.Field>
    <f.Field @for="tags" @control="checkbox-group" @options={{tags}} as |field|>
      <field.Control @optionDescription="blurb" />
    </f.Field>
    <f.Field @for="tags" @control="toggle-group" @options={{tags}} />
    <f.Field @for="birthday" @control="date-picker" />
    <f.Field @for="code" @control="input-otp" @maxLength={{6}} />
  </Form>
</template>

/** A control that can't hold its path, or an arg it doesn't take, is rejected. */
export const Misfits: TOC<{ Args: { settings: Settings } }> = <template>
  <Form @model={{@settings}} as |f|>
    {{! @glint-expect-error: a switch stores a boolean }}
    <f.Field @for="name" @control="switch" />
    {{! @glint-expect-error: clearing a rating stores null; volume can't hold it }}
    <f.Field @for="volume" @control="rating" />
    {{! @glint-expect-error: a date picker stores a Date }}
    <f.Field @for="name" @control="date-picker" />
    {{! @glint-expect-error: a single slider stores a number, not a list }}
    <f.Field @for="name" @control="slider" />
    {{! @glint-expect-error: the options aren't sizes }}
    <f.Field @for="size" @control="radio" @options={{plans}} />
    {{! @glint-expect-error: a switch has no options }}
    <f.Field @for="dark" @control="switch" @options={{plans}} />
    <f.Field @for="dark" @control="switch" as |field|>
      {{! @glint-expect-error: a switch has no rows }}
      <field.Control @rows={{4}} />
    </f.Field>
  </Form>
</template>
