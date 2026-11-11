import { InputGroup } from '@ember-joinery/ember'

<template>
  <div class="grid w-full max-w-sm gap-6">
    <InputGroup as |g|>
      <g.Addon>
        <g.Text>$</g.Text>
      </g.Addon>
      <g.Input placeholder="0.00" />
      <g.Addon @align="inline-end">
        <g.Text>USD</g.Text>
      </g.Addon>
    </InputGroup>
    <InputGroup as |g|>
      <g.Addon>
        <g.Text>https://</g.Text>
      </g.Addon>
      <g.Input placeholder="example.com" class="pl-0.5!" />
      <g.Addon @align="inline-end">
        <g.Text>.com</g.Text>
      </g.Addon>
    </InputGroup>
    <InputGroup as |g|>
      <g.Input placeholder="Enter your username" />
      <g.Addon @align="inline-end">
        <g.Text>@company.com</g.Text>
      </g.Addon>
    </InputGroup>
    <InputGroup as |g|>
      <g.Textarea placeholder="Enter your message" />
      <g.Addon @align="block-end">
        <g.Text class="text-xs text-muted-foreground">
          120 characters left
        </g.Text>
      </g.Addon>
    </InputGroup>
  </div>
</template>
