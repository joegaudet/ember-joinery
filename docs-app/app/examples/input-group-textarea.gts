import { Code, Copy, CornerDownLeft, RefreshCw } from 'lucide'
import { Icon, InputGroup } from '@ember-joinery/ember'

<template>
  {{!
    Upstream's draws Tabler's brand-javascript, copy, corner-down-left and refresh; Joinery's
    icons are lucide's, which has no brand icons, so the file's icon is its code. Upstream's
    icon-only buttons are unnamed; these have aria-label, so the audit passes.
  }}
  <div class="grid w-full max-w-md gap-4">
    <InputGroup as |g|>
      <g.Textarea
        id="textarea-code-32"
        placeholder="console.log('Hello, world!');"
        class="min-h-[200px]"
      />
      <g.Addon @align="block-end" class="border-t">
        <g.Text>Line 1, Column 1</g.Text>
        <g.Button @size="sm" class="ml-auto" @variant="default">
          Run
          <Icon @icon={{CornerDownLeft}} />
        </g.Button>
      </g.Addon>
      <g.Addon @align="block-start" class="border-b">
        <g.Text class="font-mono font-medium">
          <Icon @icon={{Code}} />
          script.js
        </g.Text>
        <g.Button class="ml-auto" @size="icon-xs" aria-label="Refresh">
          <Icon @icon={{RefreshCw}} />
        </g.Button>
        <g.Button @variant="ghost" @size="icon-xs" aria-label="Copy">
          <Icon @icon={{Copy}} />
        </g.Button>
      </g.Addon>
    </InputGroup>
  </div>
</template>
