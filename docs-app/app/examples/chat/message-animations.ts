// The entrance animations of upstream's `lib/message-animations.ts` (motion variants), as Web
// Animations keyframes. Motion's tweens keep their duration and easing; its springs become an
// easing curve that settles as each spring does (`pop` all but critically damped, `spring-bounce`
// with a slight overshoot).

/** One entrance: a name for the picker, and the keyframes a new row plays. */
export interface MessageAnimationPreset {
  id: MessageAnimationId
  name: string
  keyframes: Keyframe[]
  options: KeyframeAnimationOptions
}

export type MessageAnimationId =
  'fade' | 'slide-up' | 'slide-side' | 'pop' | 'spring-bounce' | 'blur-fade' | 'scale-fade'

const EASE_OUT = 'cubic-bezier(0, 0, 0.58, 1)'
const EXPO = 'cubic-bezier(0.16, 1, 0.3, 1)'

const ANIMATIONS: MessageAnimationPreset[] = [
  {
    id: 'fade',
    name: 'Fade',
    keyframes: [{ opacity: 0 }, { opacity: 1 }],
    options: { duration: 220, easing: EASE_OUT },
  },
  {
    id: 'slide-up',
    name: 'Slide Up',
    keyframes: [
      { opacity: 0, transform: 'translateY(10px)' },
      { opacity: 1, transform: 'none' },
    ],
    options: { duration: 260, easing: EXPO },
  },
  {
    id: 'slide-side',
    name: 'Slide Side',
    keyframes: [
      { opacity: 0, transform: 'translateX(18px)' },
      { opacity: 1, transform: 'none' },
    ],
    options: { duration: 280, easing: EXPO },
  },
  {
    id: 'pop',
    name: 'Pop',
    keyframes: [
      { opacity: 0, transform: 'translateY(6px) scale(0.94)', transformOrigin: '100% 100%' },
      { opacity: 1, transform: 'none', transformOrigin: '100% 100%' },
    ],
    options: { duration: 300, easing: 'cubic-bezier(0.22, 1, 0.36, 1)' },
  },
  {
    id: 'spring-bounce',
    name: 'Spring Bounce',
    keyframes: [
      { opacity: 0, transform: 'translateY(12px) scale(0.96)' },
      { opacity: 1, transform: 'none' },
    ],
    options: { duration: 340, easing: 'cubic-bezier(0.34, 1.3, 0.64, 1)' },
  },
  {
    id: 'blur-fade',
    name: 'Blur Fade',
    keyframes: [
      { opacity: 0, filter: 'blur(4px)', transform: 'translateY(6px)' },
      { opacity: 1, filter: 'blur(0px)', transform: 'none' },
    ],
    options: { duration: 280, easing: EASE_OUT },
  },
  {
    id: 'scale-fade',
    name: 'Scale Fade',
    keyframes: [
      { opacity: 0, transform: 'scale(0.98)' },
      { opacity: 1, transform: 'none' },
    ],
    options: { duration: 240, easing: EASE_OUT },
  },
]

/** The presets by id, in upstream's order. */
export const MESSAGE_ANIMATIONS = Object.fromEntries(
  ANIMATIONS.map(preset => [preset.id, preset]),
) as Record<MessageAnimationId, MessageAnimationPreset>
