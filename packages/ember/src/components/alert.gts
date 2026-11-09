import type { TOC } from '@ember/component/template-only'
import type { ComponentLike } from '@glint/template'
import { As, type TagName } from '@ember-joinery/primitives/as'
import type { PartModifier } from '@ember-joinery/primitives/part'
import {
  staticPart,
  staticPartModifier,
  type StaticPartSignature,
} from '../-private/static-part.gts'

/** How an alert looks: shadcn's two variants. */
export type AlertVariant = 'default' | 'destructive'

const TITLE = { class: 'jn-alert-title', slot: 'alert-title', part: 'title' } as const
const DESCRIPTION = {
  class: 'jn-alert-description',
  slot: 'alert-description',
  part: 'description',
} as const
const ACTION = { class: 'jn-alert-action', slot: 'alert-action', part: 'action' } as const

const AlertTitle = staticPart(TITLE)
const AlertDescription = staticPart(DESCRIPTION)
const AlertAction = staticPart(ACTION)

/** What an alert yields: its parts, each as a component and as a modifier for your own element. */
export interface AlertParts {
  /** The title. With an icon before it, it sits beside the icon. */
  Title: ComponentLike<StaticPartSignature>
  /** The description, muted, under the title. */
  Description: ComponentLike<StaticPartSignature>
  /** A button or other control, in the alert's top inline-end corner. */
  Action: ComponentLike<StaticPartSignature>
  /** `<h3 {{a.title}}>`: makes your own element the title. */
  title: PartModifier<HTMLElement>
  /** `<p {{a.description}}>`: makes your own element the description. */
  description: PartModifier<HTMLElement>
  /** Makes your own element the action's container. */
  action: PartModifier<HTMLElement>
}

const PARTS: AlertParts = {
  Title: AlertTitle,
  Description: AlertDescription,
  Action: AlertAction,
  title: staticPartModifier(TITLE),
  description: staticPartModifier(DESCRIPTION),
  action: staticPartModifier(ACTION),
}

export interface AlertSignature {
  Args: {
    /** Default `default`. */
    variant?: AlertVariant
    /** The tag to render instead of `div`. */
    as?: TagName
    /** The alert's name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** An icon (first, so it takes the first column), then the alert's parts. */
    default: [AlertParts]
  }
  Element: HTMLElement
}

/**
 * Displays a callout for user attention: shadcn's Alert. It has the `alert` role, as
 * upstream's; give it `role="status"` for news that can wait. An icon placed first sits beside
 * the title and description, and the action takes the top inline-end corner.
 *
 *   <Alert @variant="destructive" as |a|>
 *     <Icon @icon={{CircleAlert}} />
 *     <a.Title>Payment failed</a.Title>
 *     <a.Description>Please check your payment method and try again.</a.Description>
 *     <a.Action><Button @size="xs">Retry</Button></a.Action>
 *   </Alert>
 */
const Alert: TOC<AlertSignature> = <template>
  <As
    @as={{@as}}
    class="jn-alert group/alert jn-alert-variant-{{if @variant @variant 'default'}}"
    data-slot="alert"
    role="alert"
    data-variant={{if @variant @variant "default"}}
    data-test-jn="alert"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield PARTS}}</As>
</template>

export default Alert
