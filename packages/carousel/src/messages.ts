import type { Message } from '@ember-joinery/primitives/i18n'

/**
 * Every string `@ember-joinery/carousel` shows or announces itself, in English, for a
 * translation catalog. An argument (`@label`, `@slideLabel`) still beats each one.
 */
export const messages = {
  carousel: {
    id: 'joinery.carousel.roleDescription',
    message: 'carousel',
    description: "What a screen reader calls the carousel's region.",
  },
  slide: {
    id: 'joinery.carousel.slideRoleDescription',
    message: 'slide',
    description: 'What a screen reader calls each slide.',
  },
  slideLabel: {
    id: 'joinery.carousel.slideLabel',
    message: '{index} of {count}',
    description: "A slide's name, by its place: {index} of the {count} slides.",
  },
  previous: { id: 'joinery.carousel.previous', message: 'Previous slide' },
  next: { id: 'joinery.carousel.next', message: 'Next slide' },
} satisfies Record<string, Message>
