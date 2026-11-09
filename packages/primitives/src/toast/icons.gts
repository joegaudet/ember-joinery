import type { TOC } from '@ember/component/template-only'
import type { ComponentLike } from '@glint/template'
import type { ToastType } from './state.ts'

// sonner 2.0.7's own icons and loader (MIT, (c) 2023 Emil Kowalski; the notice is in state.ts),
// drawn as sonner draws them. A Toaster shows these unless its `@icons` replaces them
// (Joinery's styled Toaster does, with lucide's, as shadcn's does).

export const SuccessIcon: TOC<{ Element: SVGSVGElement }> = <template>
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 20 20"
    fill="currentColor"
    height="20"
    width="20"
    aria-hidden="true"
    ...attributes
  >
    <path
      fill-rule="evenodd"
      d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z"
      clip-rule="evenodd"
    />
  </svg>
</template>

export const WarningIcon: TOC<{ Element: SVGSVGElement }> = <template>
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24"
    fill="currentColor"
    height="20"
    width="20"
    aria-hidden="true"
    ...attributes
  >
    <path
      fill-rule="evenodd"
      d="M9.401 3.003c1.155-2 4.043-2 5.197 0l7.355 12.748c1.154 2-.29 4.5-2.599 4.5H4.645c-2.309 0-3.752-2.5-2.598-4.5L9.4 3.003zM12 8.25a.75.75 0 01.75.75v3.75a.75.75 0 01-1.5 0V9a.75.75 0 01.75-.75zm0 8.25a.75.75 0 100-1.5.75.75 0 000 1.5z"
      clip-rule="evenodd"
    />
  </svg>
</template>

export const InfoIcon: TOC<{ Element: SVGSVGElement }> = <template>
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 20 20"
    fill="currentColor"
    height="20"
    width="20"
    aria-hidden="true"
    ...attributes
  >
    <path
      fill-rule="evenodd"
      d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a.75.75 0 000 1.5h.253a.25.25 0 01.244.304l-.459 2.066A1.75 1.75 0 0010.747 15H11a.75.75 0 000-1.5h-.253a.25.25 0 01-.244-.304l.459-2.066A1.75 1.75 0 009.253 9H9z"
      clip-rule="evenodd"
    />
  </svg>
</template>

export const ErrorIcon: TOC<{ Element: SVGSVGElement }> = <template>
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 20 20"
    fill="currentColor"
    height="20"
    width="20"
    aria-hidden="true"
    ...attributes
  >
    <path
      fill-rule="evenodd"
      d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-8-5a.75.75 0 01.75.75v4.5a.75.75 0 01-1.5 0v-4.5A.75.75 0 0110 5zm0 10a1 1 0 100-2 1 1 0 000 2z"
      clip-rule="evenodd"
    />
  </svg>
</template>

export const CloseIcon: TOC<{ Element: SVGSVGElement }> = <template>
  <svg
    xmlns="http://www.w3.org/2000/svg"
    width="12"
    height="12"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="1.5"
    stroke-linecap="round"
    stroke-linejoin="round"
    aria-hidden="true"
    ...attributes
  >
    <line x1="18" y1="6" x2="6" y2="18" />
    <line x1="6" y1="6" x2="18" y2="18" />
  </svg>
</template>

const BARS = Array.from({ length: 12 }, (_, index) => index)

/** sonner's spinner: twelve bars, fading in turn (`.sonner-loading-bar` in its CSS). */
export const Loader: TOC<{
  Element: HTMLDivElement
  Args: { visible: boolean; class?: string }
}> = <template>
  <div
    class="sonner-loading-wrapper {{@class}}"
    data-visible={{if @visible "true" "false"}}
    ...attributes
  >
    <div class="sonner-spinner">
      {{#each BARS}}
        <div class="sonner-loading-bar"></div>
      {{/each}}
    </div>
  </div>
</template>

/** sonner's icon for a type (its `getAsset`): none for the types without one. */
export function iconFor(type: ToastType | undefined): ComponentLike | null {
  switch (type) {
    case 'success':
      return SuccessIcon
    case 'info':
      return InfoIcon
    case 'warning':
      return WarningIcon
    case 'error':
      return ErrorIcon
    default:
      return null
  }
}
