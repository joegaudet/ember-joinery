import { Card } from '@ember-joinery/ember'
import { Carousel } from '@ember-joinery/carousel'

const ARABIC_NUMERALS = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩']

function toArabicNumerals(num: number): string {
  return num
    .toString()
    .split('')
    .map(digit => ARABIC_NUMERALS[parseInt(digit, 10)])
    .join('')
}

/** Each slide's name, in Arabic: "١ من ٥", 1 of 5. */
const slideLabel = (index: number, count: number) =>
  `${toArabicNumerals(index)} من ${toArabicNumerals(count)}`

const slides = Array.from({ length: 5 }, (_, index) => index + 1)

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic. Upstream's sets dir on its own root, and Embla's direction to match, from a language
    picker; Joinery's carousel takes both from the nearest dir, so the example needs neither.
    Upstream leaves the names read aloud in English (the buttons' "Previous slide" and "Next
    slide"); Joinery's are in Arabic, as a right-to-left page would name them, and so are the
    carousel's and its slides' names. They're read aloud, not drawn, so the screenshot is the
    same.
  }}
  <Carousel
    class="w-full max-w-[12rem] sm:max-w-xs"
    aria-label="أرقام"
    @slideLabel={{slideLabel}}
    as |c|
  >
    <c.Content>
      {{#each slides as |number|}}
        <c.Item>
          <div class="p-1">
            <Card as |card|>
              <card.Content class="flex aspect-square items-center justify-center p-6">
                <span class="text-4xl font-semibold">
                  {{toArabicNumerals number}}
                </span>
              </card.Content>
            </Card>
          </div>
        </c.Item>
      {{/each}}
    </c.Content>
    <c.Previous @label="الشريحة السابقة" />
    <c.Next @label="الشريحة التالية" />
  </Carousel>
</template>
