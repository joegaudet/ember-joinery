import { ChevronRight, FilePen, FilePlus, GitCommitHorizontal } from 'lucide'
import { Icon, Sheet, Trace, TraceCollapsible, TraceLine } from '@ember-joinery/ember'
import { CodeBlock, type CodeBlockLineVariant } from '@ember-joinery/code-block'

const files = [
  {
    path: 'app/login/page.tsx',
    added: false,
    additions: 2,
    deletions: 2,
    diff: `@@ -14,7 +14,7 @@ export default async function LoginPage({
   searchParams,
 }) {
   const { next } = await searchParams
-  const redirectTo =
-    next && next.startsWith("/") ? next : "/"
+  const redirectTo = safeRedirect(next)
+
   return <LoginForm redirectTo={redirectTo} />
 }`,
  },
  {
    path: 'lib/auth/redirect.ts',
    added: true,
    additions: 7,
    deletions: 0,
    diff: `@@ -0,0 +1,7 @@
+export function safeRedirect(next: string | undefined) {
+  if (!next || !next.startsWith("/") || next.startsWith("//")) {
+    return "/"
+  }
+
+  return next
+}`,
  },
]

interface DiffLine {
  code: string
  variant: CodeBlockLineVariant
  hunk: boolean
}

// A hunk header is shown whole and muted; every other row drops its +, - or space marker.
function diffLines(diff: string): DiffLine[] {
  return diff.split('\n').map(line => {
    if (line.startsWith('@@')) return { code: line, variant: 'default', hunk: true }
    const variant = line.startsWith('+') ? 'added' : line.startsWith('-') ? 'removed' : 'default'
    return { code: line.slice(1), variant, hunk: false }
  })
}

<template>
  <Trace class="max-w-sm">
    <TraceCollapsible @defaultOpen={{true}} as |c|>
      <c.Trigger>
        <TraceLine as |l|>
          <l.Icon>
            <Icon @icon={{GitCommitHorizontal}} />
          </l.Icon>
          <l.Title>Committed a1b2c3: Fix the login redirect</l.Title>
        </TraceLine>
      </c.Trigger>
      <c.Content>
        <Trace>
          {{#each files as |file|}}
            <Sheet as |s|>
              <s.Trigger>
                <TraceLine as |l|>
                  <l.Icon>
                    <Icon @icon={{if file.added FilePlus FilePen}} />
                  </l.Icon>
                  <l.Title>
                    {{if file.added "Added" "Edited"}}
                    {{file.path}}
                  </l.Title>
                  <l.Description class="font-mono">
                    +{{file.additions}}
                    −{{file.deletions}}
                  </l.Description>
                  <l.Icon>
                    <Icon @icon={{ChevronRight}} />
                  </l.Icon>
                </TraceLine>
              </s.Trigger>
              <s.Content>
                <s.Header>
                  <s.Title class="font-mono">{{file.path}}</s.Title>
                  <s.Description>
                    {{file.additions}}
                    additions,
                    {{file.deletions}}
                    deletions
                  </s.Description>
                </s.Header>
                <CodeBlock class="mx-6 mb-6 w-auto" as |b|>
                  <b.Content>
                    {{#each (diffLines file.diff) as |line|}}
                      {{#if line.hunk}}
                        <b.Line @code={{line.code}} class="text-muted-foreground" />
                      {{else}}
                        <b.Line @code={{line.code}} @variant={{line.variant}} />
                      {{/if}}
                    {{/each}}
                  </b.Content>
                </CodeBlock>
              </s.Content>
            </Sheet>
          {{/each}}
        </Trace>
      </c.Content>
    </TraceCollapsible>
  </Trace>
</template>
