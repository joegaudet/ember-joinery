import { Download, FileText } from 'lucide'
import { Attachment, Bubble, Icon, Message } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-sm flex-col gap-8 py-12">
    <Message @align="end" as |m|>
      <m.Content>
        <Attachment @orientation="vertical" as |at|>
          <at.Media @variant="image">
            <img
              src="https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=900&auto=format&fit=crop&q=80"
              alt="Workspace"
            />
          </at.Media>
        </Attachment>
        <Bubble as |b|>
          <b.Content>
            Here's the image. Can you add it to the PDF? Use it for the cover page.
          </b.Content>
        </Bubble>
      </m.Content>
    </Message>
    <Message as |m|>
      <m.Content>
        <Bubble @variant="muted" as |b|>
          <b.Content>
            Done. Here's the PDF with the image added as the cover page.
          </b.Content>
        </Bubble>
        <Attachment as |at|>
          <at.Media>
            <Icon @icon={{FileText}} />
          </at.Media>
          <at.Content>
            <at.Title>sales-dashboard.pdf</at.Title>
            <at.Description>PDF · 2.4 MB</at.Description>
          </at.Content>
          <at.Actions>
            <at.Action
              @size="icon-sm"
              @variant="secondary"
              type="button"
              title="Download"
              aria-label="Download"
            >
              <Icon @icon={{Download}} />
            </at.Action>
          </at.Actions>
        </Attachment>
      </m.Content>
    </Message>
    <Message @align="end" as |m|>
      <m.Content>
        <Bubble as |b|>
          <b.Content>Thanks. Looks good.</b.Content>
        </Bubble>
      </m.Content>
    </Message>
  </div>
</template>
