import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { registerDestructor } from '@ember/destroyable'
import type Owner from '@ember/owner'
import type { TOC } from '@ember/component/template-only'
import { CircleCheck, Info, LoaderCircle, OctagonX, TriangleAlert } from 'lucide'
import {
  Toaster as ToasterPrimitive,
  type ToasterSignature as ToasterPrimitiveSignature,
  type ToastIcons,
  type ToastOptions,
  type ToastStyle,
  type ToasterTheme,
} from '@ember-joinery/primitives/toast'
import Icon from './icon.gts'

// shadcn's `toast()` is sonner's: Joinery's is the primitives', exported here too, so an app
// imports the Toaster and `toast` from one place, as upstream's examples import `toast` from
// "sonner".
export {
  Toasts,
  toast,
  toastsFor,
  type CustomToastSignature,
  type ExternalToast,
  type PromiseData,
  type PromiseToast,
  type SwipeDirection,
  type ToastAction,
  type ToastClassnames,
  type ToastContent,
  type ToastFunction,
  type ToastIcons,
  type ToastId,
  type ToastOffset,
  type ToastOptions,
  type ToastPosition,
  type ToastStyle,
  type ToastT,
  type ToastType,
  type ToasterTheme,
} from '@ember-joinery/primitives/toast'

// The icons upstream gives sonner: lucide's, size-4 (see toaster.css), the loader turning.
const SuccessIcon: TOC<object> = <template>
  <Icon @icon={{CircleCheck}} class="jn-toaster-icon jn-size-4" />
</template>
const InfoIcon: TOC<object> = <template>
  <Icon @icon={{Info}} class="jn-toaster-icon jn-size-4" />
</template>
const WarningIcon: TOC<object> = <template>
  <Icon @icon={{TriangleAlert}} class="jn-toaster-icon jn-size-4" />
</template>
const ErrorIcon: TOC<object> = <template>
  <Icon @icon={{OctagonX}} class="jn-toaster-icon jn-size-4" />
</template>
const LoadingIcon: TOC<object> = <template>
  <Icon @icon={{LoaderCircle}} class="jn-toaster-icon jn-toaster-icon-loading jn-size-4" />
</template>

/** The icons upstream's Toaster shows: lucide's circle-check, info, triangle-alert, octagon-x and loader-circle. */
export const TOASTER_ICONS: Readonly<ToastIcons> = {
  success: SuccessIcon,
  info: InfoIcon,
  warning: WarningIcon,
  error: ErrorIcon,
  loading: LoadingIcon,
}

/** The tokens upstream's Toaster gives sonner's CSS, so toasts look like a popover. */
export const TOASTER_STYLE: Readonly<ToastStyle> = {
  '--normal-bg': 'var(--popover)',
  '--normal-text': 'var(--popover-foreground)',
  '--normal-border': 'var(--border)',
  '--border-radius': 'var(--radius)',
}

export interface ToasterSignature {
  /** Each list (`<ol>`): sonner puts its `className` and `style` there. */
  Element: HTMLOListElement
  Args: Omit<ToasterPrimitiveSignature['Args'], 'theme'> & {
    /**
     * `light`, `dark`, or `system` to follow the OS. Default the page's: dark while `<html>`
     * has the `dark` class (what Joinery's `ColorScheme` and shadcn's tokens use), as upstream's
     * follows next-themes.
     */
    theme?: ToasterTheme
  }
}

const pageIsDark = () =>
  typeof document !== 'undefined' && document.documentElement.classList.contains('dark')

/**
 * shadcn's Toaster: sonner's, with toasts that look like a popover (its `--popover` tokens and
 * the theme's radius) and lucide's icons. Render it once, in your application template, and
 * show toasts from anywhere with `toast()`:
 *
 *   import { Toaster, toast } from '@ember-joinery/ember'
 *
 *   <Toaster />                                        {{! in templates/application.gts }}
 *   toast('Event has been created', { description: 'Sunday at 9:00 AM' })
 *
 * It takes every argument of `@ember-joinery/primitives/toast`'s Toaster (sonner's props).
 * `@icons`, `@style` and `@toastOptions.classNames` add to upstream's instead of replacing
 * them. In tests, `setupToaster(hooks)` from `@ember-joinery/test-support` gives each test its
 * own toasts, and `ToasterHarness` drives them.
 */
export default class Toaster extends Component<ToasterSignature> {
  @tracked pageDark = pageIsDark()

  constructor(owner: Owner, args: ToasterSignature['Args']) {
    super(owner, args)
    if (typeof MutationObserver === 'undefined') return
    const observer = new MutationObserver(() => (this.pageDark = pageIsDark()))
    observer.observe(document.documentElement, { attributes: true, attributeFilter: ['class'] })
    registerDestructor(this, () => observer.disconnect())
  }

  get theme(): ToasterTheme {
    return this.args.theme ?? (this.pageDark ? 'dark' : 'light')
  }

  get icons(): ToastIcons {
    return { ...TOASTER_ICONS, ...this.args.icons }
  }

  get style(): ToastStyle {
    return { ...TOASTER_STYLE, ...this.args.style }
  }

  get toastOptions(): ToastOptions {
    const options = this.args.toastOptions
    const own = options?.classNames?.toast
    return {
      ...options,
      classNames: { ...options?.classNames, toast: own ? `jn-toast ${own}` : 'jn-toast' },
    }
  }

  <template>
    <ToasterPrimitive
      @id={{@id}}
      @name={{@name}}
      @invert={{@invert}}
      @theme={{this.theme}}
      @position={{@position}}
      @hotkey={{@hotkey}}
      @richColors={{@richColors}}
      @expand={{@expand}}
      @duration={{@duration}}
      @gap={{@gap}}
      @visibleToasts={{@visibleToasts}}
      @closeButton={{@closeButton}}
      @toastOptions={{this.toastOptions}}
      @style={{this.style}}
      @offset={{@offset}}
      @mobileOffset={{@mobileOffset}}
      @dir={{@dir}}
      @swipeDirections={{@swipeDirections}}
      @icons={{this.icons}}
      @containerAriaLabel={{@containerAriaLabel}}
      class="toaster group"
      ...attributes
    />
  </template>
}
