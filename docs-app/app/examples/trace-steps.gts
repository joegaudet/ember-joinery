import { ChevronRight, FileText, Search } from 'lucide'
import { Badge, Icon, Trace, TraceCollapsible, TraceLine } from '@ember-joinery/ember'
import { CodeBlock } from '@ember-joinery/code-block'

const query = 'cache key image optimization'

<template>
  <div class="w-full max-w-sm">
    <TraceCollapsible @defaultOpen={{true}} as |c|>
      <c.Trigger>
        <TraceLine @status="running" as |l|>
          <l.Title>Looking into the slow deploy</l.Title>
        </TraceLine>
      </c.Trigger>
      <c.Content>
        <Trace>
          <TraceCollapsible as |s|>
            <s.Trigger>
              <TraceLine as |l|>
                <l.Icon>
                  <Icon @icon={{Search}} />
                </l.Icon>
                <l.Title>Searched for the checkout build log</l.Title>
              </TraceLine>
            </s.Trigger>
            <s.Content class="flex flex-wrap gap-1.5">
              <Badge @variant="secondary">vercel.com</Badge>
              <Badge @variant="secondary">github.com</Badge>
            </s.Content>
          </TraceCollapsible>
          <a href="#steps">
            <TraceLine as |l|>
              <l.Icon>
                <Icon @icon={{FileText}} />
              </l.Icon>
              <l.Title>Read the last twelve deploys</l.Title>
              <l.Icon>
                <Icon @icon={{ChevronRight}} />
              </l.Icon>
            </TraceLine>
          </a>
          <TraceCollapsible as |s|>
            <s.Trigger>
              <TraceLine @status="running" as |l|>
                <l.Icon>
                  <Icon @icon={{Search}} />
                </l.Icon>
                <l.Title>Searching for the cache key</l.Title>
              </TraceLine>
            </s.Trigger>
            <s.Content>
              <CodeBlock @size="sm" as |b|>
                <b.Content @code={{query}} @wrap={{true}} class="max-h-64" />
              </CodeBlock>
            </s.Content>
          </TraceCollapsible>
        </Trace>
      </c.Content>
    </TraceCollapsible>
  </div>
</template>
