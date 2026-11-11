import { InputOTP, REGEXP_ONLY_DIGITS } from '@ember-joinery/primitives/input-otp'

<template>
  {{!
    The headless input, styled here with utility classes alone: it yields each slot's state, and
    you draw the slots. The active one gets a ring, and an empty active one a caret.
  }}
  <div class="flex flex-col items-center gap-2 text-sm">
    <label for="headless-code">Code sent to your phone</label>
    <InputOTP
      id="headless-code"
      @maxLength={{4}}
      @pattern={{REGEXP_ONLY_DIGITS}}
      @containerClass="flex gap-2 has-disabled:opacity-50"
      as |otp|
    >
      {{#each otp.slots as |slot|}}
        <otp.Slot
          @index={{slot.index}}
          class="flex size-10 items-center justify-center rounded-md border border-gray-400 text-lg data-[active=true]:ring-2 data-[active=true]:ring-blue-600"
          as |s|
        >
          {{s.char}}
          {{#if s.hasFakeCaret}}
            <span class="h-5 w-px animate-pulse bg-current" data-test-jn-part="caret"></span>
          {{/if}}
        </otp.Slot>
      {{/each}}
    </InputOTP>
  </div>
</template>
