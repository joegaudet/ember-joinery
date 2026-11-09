import { ContextMenu } from '@ember-joinery/ember'

<template>
  <ContextMenu as |c|>
    <c.Trigger
      class="flex aspect-video w-full max-w-xs items-center justify-center rounded-xl border border-dashed text-sm"
    >
      <span class="hidden pointer-fine:inline-block">
        Right click here
      </span>
      <span class="hidden pointer-coarse:inline-block">
        Long press here
      </span>
    </c.Trigger>
    <c.Content class="w-48">
      <c.Group>
        <c.Item>
          Back
          <c.Shortcut>⌘[</c.Shortcut>
        </c.Item>
        <c.Item @disabled={{true}}>
          Forward
          <c.Shortcut>⌘]</c.Shortcut>
        </c.Item>
        <c.Item>
          Reload
          <c.Shortcut>⌘R</c.Shortcut>
        </c.Item>
        <c.Sub as |s|>
          <s.Trigger>More Tools</s.Trigger>
          <s.Content class="w-44">
            <c.Group>
              <c.Item>Save Page...</c.Item>
              <c.Item>Create Shortcut...</c.Item>
              <c.Item>Name Window...</c.Item>
            </c.Group>
            <c.Separator />
            <c.Group>
              <c.Item>Developer Tools</c.Item>
            </c.Group>
            <c.Separator />
            <c.Group>
              <c.Item @variant="destructive">Delete</c.Item>
            </c.Group>
          </s.Content>
        </c.Sub>
      </c.Group>
      <c.Separator />
      <c.Group>
        <c.CheckboxItem @checked={{true}}>
          Show Bookmarks
        </c.CheckboxItem>
        <c.CheckboxItem>Show Full URLs</c.CheckboxItem>
      </c.Group>
      <c.Separator />
      <c.Group>
        <c.RadioGroup @value="pedro" as |g|>
          <c.Label>People</c.Label>
          <g.Item @value="pedro">
            Pedro Duarte
          </g.Item>
          <g.Item @value="colm">Colm Tuite</g.Item>
        </c.RadioGroup>
      </c.Group>
    </c.Content>
  </ContextMenu>
</template>
