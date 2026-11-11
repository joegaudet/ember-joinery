import { Bot, ChevronDown } from 'lucide'
import {
  Button,
  ButtonGroup,
  Field,
  FieldDescription,
  FieldLabel,
  Icon,
  Popover,
  Textarea,
} from '@ember-joinery/ember'

<template>
  <ButtonGroup>
    <Button @variant="outline">
      <Icon @icon={{Bot}} />
      Copilot
    </Button>
    <Popover as |popover|>
      <Button @variant="outline" @size="icon" aria-label="Open Popover" {{popover.trigger}}>
        <Icon @icon={{ChevronDown}} />
      </Button>
      <popover.Content @align="end" class="rounded-xl text-sm">
        <popover.Header>
          <popover.Title>Start a new task with Copilot</popover.Title>
          <popover.Description>
            Describe your task in natural language.
          </popover.Description>
        </popover.Header>
        <Field>
          <FieldLabel for="task" class="sr-only">
            Task Description
          </FieldLabel>
          <Textarea id="task" placeholder="I need to..." class="resize-none" />
          <FieldDescription>
            Copilot will open a pull request for review.
          </FieldDescription>
        </Field>
      </popover.Content>
    </Popover>
  </ButtonGroup>
</template>
