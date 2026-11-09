import { ChevronDown } from 'lucide'
import { Button, Card, Collapsible, Icon } from '@ember-joinery/ember'

<template>
  <Card class="mx-auto w-full max-w-sm" as |card|>
    <card.Content>
      <Collapsible class="rounded-md data-[state=open]:bg-muted" as |c|>
        <Button @variant="ghost" class="group w-full" {{c.trigger}}>
          Product details
          <Icon @icon={{ChevronDown}} class="ml-auto group-data-[state=open]:rotate-180" />
        </Button>
        <c.Content class="flex flex-col items-start gap-2 p-2.5 pt-0 text-sm">
          <div>
            This panel can be expanded or collapsed to reveal additional content.
          </div>
          <Button @size="xs">Learn More</Button>
        </c.Content>
      </Collapsible>
    </card.Content>
  </Card>
</template>
