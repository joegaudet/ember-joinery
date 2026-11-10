import { FileText } from 'lucide'
import { Attachment, Icon } from '@ember-joinery/ember'

<template>
  <div class="mx-auto flex w-full max-w-sm flex-col gap-3 py-12">
    <Attachment @size="default" class="w-full" as |at|>
      <at.Media>
        <Icon @icon={{FileText}} />
      </at.Media>
      <at.Content>
        <at.Title>Default attachment</at.Title>
        <at.Description>PDF · 2.4 MB</at.Description>
      </at.Content>
    </Attachment>
    <Attachment @size="sm" class="w-full" as |at|>
      <at.Media>
        <Icon @icon={{FileText}} />
      </at.Media>
      <at.Content>
        <at.Title>Small attachment</at.Title>
        <at.Description>PDF · 2.4 MB</at.Description>
      </at.Content>
    </Attachment>
    <Attachment @size="xs" class="w-full" as |at|>
      <at.Media>
        <Icon @icon={{FileText}} />
      </at.Media>
      <at.Content>
        <at.Title>Extra small attachment</at.Title>
      </at.Content>
    </Attachment>
  </div>
</template>
