// TypeDoc plugin for the API reference at joegaudet.com/ember-joinery/api/ (typedoc.json). It
// reads the packages' built declarations, as the guide's Reference does (Kolay), and refines
// them the way docs-app/api-docs.mjs refines the guide's JSON, where the HTML needs it:
//
// - Each module is named as it is imported: `ember/declarations` is `@ember-joinery/ember`,
//   `carousel/declarations/test-support` is `@ember-joinery/carousel/test-support`.
// - A class lists its own members. Every component would otherwise repeat Glimmer Component's,
//   and every harness all of `Harness`'s; the page links the class it extends instead.
// - A doc comment's indented examples are code (`fenceIndentedCode`, shared with the guide).
//   Joinery's comments indent their usage, as plain text in an editor; unfenced, TypeDoc's
//   Markdown would render `<Button @variant="outline">` as markup.
// - Each page gets the marketing site's link-preview card and JSON-LD, which TypeDoc has no
//   option for (it writes the canonical link and sitemap itself, from hostedBaseUrl).
import { readFileSync } from 'node:fs'
import { Converter, JSX, ReflectionKind } from 'typedoc'
import { fenceIndentedCode } from '../docs-app/api-docs.mjs'

const SITE = 'https://joegaudet.com/ember-joinery/'
const CARD = `${SITE}social-card.png`
const root = new URL('../', import.meta.url)

/** `<dir>/declarations[/sub]` or `test-support/dist` as the specifier that imports it. */
export function moduleSpecifier(name) {
  const match = /^([^/]+)\/(?:declarations|dist)(\/.+)?$/.exec(name)
  if (!match) return name
  const pkg = JSON.parse(readFileSync(new URL(`packages/${match[1]}/package.json`, root), 'utf8'))
  return pkg.name + (match[2] ?? '')
}

/**
 * Fences the indented examples in one comment's parts, in place. An inline tag (`{@link}`) is
 * kept as it is, through a placeholder (a private-use character); a relative link becomes text. Records the media ids of
 * relative links that became text (`dropped`) and of those left as links (`kept`).
 */
export function fence(parts, dropped = new Set(), kept = new Set()) {
  if (!parts?.length) return
  const tags = []
  const text = parts
    .map(part => {
      if (part.kind !== 'inline-tag') return part.text
      tags.push(part)
      return `\uE000${tags.length - 1}\uE000`
    })
    .join('')
  const links = parts.filter(part => part.kind === 'relative-link' && part.target)
  const fenced = fenceIndentedCode(text)
  if (fenced === text) {
    for (const link of links) kept.add(link.target)
    return
  }
  for (const link of links) dropped.add(link.target)
  const out = fenced
    .split(/\uE000(\d+)\uE000/)
    .map((piece, i) => (i % 2 ? tags[Number(piece)] : { kind: 'text', text: piece }))
    .filter(part => part.kind !== 'text' || part.text)
  parts.splice(0, parts.length, ...out)
}

export function load(app) {
  app.converter.on(Converter.EVENT_RESOLVE_BEGIN, context => {
    const { project } = context

    for (const module of project.getReflectionsByKind(ReflectionKind.Module))
      module.name = moduleSpecifier(module.name)

    for (const member of project.getReflectionsByKind(ReflectionKind.ClassMember))
      if (member.inheritedFrom && member.parent?.kindOf(ReflectionKind.Class))
        project.removeReflection(member)

    const dropped = new Set()
    const kept = new Set()
    for (const reflection of Object.values(project.reflections)) {
      const comment = reflection.comment
      if (!comment) continue
      fence(comment.summary, dropped, kept)
      for (const tag of comment.blockTags) fence(tag.content, dropped, kept)
    }
    // An `href={{film.url}}` in an example registered `declarations/` as a file to copy, which
    // TypeDoc then warns isn't one. Once the example is code, nothing links it.
    // shortcut: FileRegistry has no public way to forget a path; revisit if TypeDoc adds one.
    for (const id of dropped) {
      if (kept.has(id) || project.files.mediaToReflection.has(id)) continue
      project.files.pathToMedia.delete(project.files.mediaToPath.get(id))
      project.files.mediaToPath.delete(id)
    }
  })

  app.renderer.hooks.on('head.end', context => {
    const base = app.options.getValue('hostedBaseUrl')
    const url = new URL(context.page.url.replace(/(^|\/)index\.html$/, '$1'), base).href
    const title = context.page.model.isProject?.()
      ? 'Joinery API reference'
      : `${context.page.model.name} · Joinery API`
    const description = context.page.model.comment?.summary
      .map(part => part.text)
      .join('')
      .split('\n\n')[0]
    const ld = {
      '@context': 'https://schema.org',
      '@type': 'TechArticle',
      headline: title,
      url,
      isPartOf: { '@type': 'WebSite', name: 'Joinery', url: SITE },
      about: {
        '@type': 'SoftwareSourceCode',
        name: 'Joinery',
        codeRepository: 'https://github.com/joegaudet/ember-joinery',
        programmingLanguage: 'TypeScript',
      },
      author: { '@type': 'Person', name: 'Joe Gaudet', url: 'https://joegaudet.com/' },
    }
    return JSX.createElement(
      JSX.Fragment,
      null,
      JSX.createElement('meta', { property: 'og:type', content: 'article' }),
      JSX.createElement('meta', { property: 'og:site_name', content: 'Joinery' }),
      JSX.createElement('meta', { property: 'og:title', content: title }),
      description &&
        JSX.createElement('meta', { property: 'og:description', content: description }),
      JSX.createElement('meta', { property: 'og:url', content: url }),
      JSX.createElement('meta', { property: 'og:image', content: CARD }),
      JSX.createElement('meta', { property: 'og:image:width', content: '1200' }),
      JSX.createElement('meta', { property: 'og:image:height', content: '630' }),
      JSX.createElement('meta', { name: 'twitter:card', content: 'summary_large_image' }),
      JSX.createElement('link', {
        rel: 'alternate',
        type: 'text/plain',
        href: `${SITE}llms.txt`,
        title: 'llms.txt',
      }),
      JSX.createElement(
        'script',
        { type: 'application/ld+json' },
        JSX.createElement(JSX.Raw, { html: JSON.stringify(ld).replaceAll('<', '\\u003c') }),
      ),
    )
  })
}
