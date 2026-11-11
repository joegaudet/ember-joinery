import { Brain, ChevronRight, FileText, Terminal } from 'lucide'
import { Icon, Trace, TraceCollapsible, TraceLine } from '@ember-joinery/ember'
import { CodeBlock } from '@ember-joinery/code-block'

const failure = 'command not found: pnpm'

<template>
  <div class="w-full max-w-sm">
    <TraceCollapsible @defaultOpen={{true}} as |c|>
      <c.Trigger>
        <TraceLine @status="error" as |l|>
          <l.Title>Worked for 2m 4s, 1 command failed</l.Title>
        </TraceLine>
      </c.Trigger>
      <c.Content class="flex flex-col gap-2">
        <Trace>
          <TraceCollapsible as |thought|>
            <thought.Trigger>
              <TraceLine as |l|>
                <l.Icon>
                  <Icon @icon={{Brain}} />
                </l.Icon>
                <l.Title>Thought</l.Title>
                <l.Description>12s</l.Description>
              </TraceLine>
            </thought.Trigger>
            <thought.Content class="whitespace-pre-wrap">
              I should check which package managers are installed before I scaffold anything.
            </thought.Content>
          </TraceCollapsible>
          <TraceCollapsible @defaultOpen={{true}} as |commands|>
            <commands.Trigger>
              <TraceLine @status="error" as |l|>
                <l.Icon>
                  <Icon @icon={{Terminal}} />
                </l.Icon>
                <l.Title>Ran 2 commands, 1 failed</l.Title>
              </TraceLine>
            </commands.Trigger>
            <commands.Content>
              <Trace>
                <TraceLine as |l|>
                  <l.Icon>
                    <Icon @icon={{Terminal}} />
                  </l.Icon>
                  <l.Title>Ran node --version</l.Title>
                </TraceLine>
                <TraceCollapsible as |command|>
                  <command.Trigger>
                    <TraceLine @status="error" as |l|>
                      <l.Icon>
                        <Icon @icon={{Terminal}} />
                      </l.Icon>
                      <l.Title>Failed to run pnpm --version</l.Title>
                    </TraceLine>
                  </command.Trigger>
                  <command.Content>
                    <CodeBlock @size="sm" @variant="destructive" as |b|>
                      <b.Content @code={{failure}} @wrap={{true}} class="max-h-64" />
                    </CodeBlock>
                  </command.Content>
                </TraceCollapsible>
              </Trace>
            </commands.Content>
          </TraceCollapsible>
        </Trace>
        <p>Node is installed and pnpm is not. Reading the docs config.</p>
        <Trace>
          <a href="#turn">
            <TraceLine as |l|>
              <l.Icon>
                <Icon @icon={{FileText}} />
              </l.Icon>
              <l.Title>Read apps/v4/lib/docs.ts</l.Title>
              <l.Icon>
                <Icon @icon={{ChevronRight}} />
              </l.Icon>
            </TraceLine>
          </a>
        </Trace>
      </c.Content>
    </TraceCollapsible>
  </div>
</template>
