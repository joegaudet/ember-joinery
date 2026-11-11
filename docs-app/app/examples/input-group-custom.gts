import { InputGroup } from '@ember-joinery/ember'

<template>
  {{!
    Upstream's control is react-textarea-autosize's TextareaAutosize. A plain textarea grows
    with its text here: field-sizing-content, in its class as in upstream's, does that in the
    browser. g.control marks it the group's (data-slot="input-group-control"), as upstream's
    data-slot attribute does.
  }}
  <div class="grid w-full max-w-sm gap-6">
    <InputGroup as |g|>
      <textarea
        class="flex field-sizing-content min-h-16 w-full resize-none rounded-md bg-transparent px-3 py-2.5 text-base transition-[color,box-shadow] outline-none md:text-sm"
        placeholder="Autoresize textarea..."
        {{g.control}}
      ></textarea>
      <g.Addon @align="block-end">
        <g.Button class="ml-auto" @size="sm" @variant="default">
          Submit
        </g.Button>
      </g.Addon>
    </InputGroup>
  </div>
</template>
