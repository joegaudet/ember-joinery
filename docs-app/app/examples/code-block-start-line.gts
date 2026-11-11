import { CodeBlock, highlightedCode } from '@ember-joinery/code-block'

const code = `  if (!session) {
    redirect("/login")
  }

  const projects = await db.project.findMany({
    where: { ownerId: session.user.id },
    orderBy: { updatedAt: "desc" },
  })

  return <ProjectList projects={projects} />
}`

<template>
  <div class="w-full max-w-md">
    <CodeBlock as |b|>
      <b.Header>
        <b.Title>app/dashboard/page.tsx</b.Title>
      </b.Header>
      <b.Content @lineNumbers={{true}} @startLine={{995}}>
        {{#each (highlightedCode code "tsx") as |line|}}
          <b.Line @code={{line}} />
        {{/each}}
      </b.Content>
    </CodeBlock>
  </div>
</template>
