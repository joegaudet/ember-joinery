import { Calculator, Calendar, CreditCard, Settings, Smile, User } from 'lucide'
import { Command, Icon } from '@ember-joinery/ember'

<template>
  <Command class="max-w-sm rounded-lg border" as |c|>
    <c.Input placeholder="Type a command or search..." />
    <c.List>
      <c.Empty>No results found.</c.Empty>
      <c.Group @heading="Suggestions">
        <c.Item>
          <Icon @icon={{Calendar}} />
          <span>Calendar</span>
        </c.Item>
        <c.Item>
          <Icon @icon={{Smile}} />
          <span>Search Emoji</span>
        </c.Item>
        <c.Item @disabled={{true}}>
          <Icon @icon={{Calculator}} />
          <span>Calculator</span>
        </c.Item>
      </c.Group>
      <c.Separator />
      <c.Group @heading="Settings">
        <c.Item>
          <Icon @icon={{User}} />
          <span>Profile</span>
          <c.Shortcut>⌘P</c.Shortcut>
        </c.Item>
        <c.Item>
          <Icon @icon={{CreditCard}} />
          <span>Billing</span>
          <c.Shortcut>⌘B</c.Shortcut>
        </c.Item>
        <c.Item>
          <Icon @icon={{Settings}} />
          <span>Settings</span>
          <c.Shortcut>⌘S</c.Shortcut>
        </c.Item>
      </c.Group>
    </c.List>
  </Command>
</template>
