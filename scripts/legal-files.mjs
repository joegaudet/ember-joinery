#!/usr/bin/env node
//
// Copies the repository's LICENSE.md and NOTICE into a package, so its tarball carries
// Joinery's licence and the notices of everything it ports (shadcn/ui, ember-primitives,
// sonner, recharts and the rest).
//
//   node ../../scripts/legal-files.mjs .   # from a package: what its `prepack` runs
//
// The root files are the only copies kept in git; each package lists both in its `files`, and
// its `prepack` copies them in before it builds, so every pack (`pnpm pack`, `pnpm release`,
// `node scripts/publish.mjs --dry-run`) has them as they are at the root. The copies are
// gitignored. scripts/legal-files.test.mjs holds every public package to this.
import { copyFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

export const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..')

/** The files every published package carries from the root. */
export const LEGAL_FILES = ['LICENSE.md', 'NOTICE']

/** Copies the root's legal files into `packageDir`, replacing any copies already there. */
export function copyLegalFiles(packageDir, root = ROOT) {
  for (const file of LEGAL_FILES) copyFileSync(join(root, file), join(packageDir, file))
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const target = process.argv[2]
  if (!target) {
    process.stderr.write('usage: node scripts/legal-files.mjs <package directory>\n')
    process.exit(2)
  }
  copyLegalFiles(resolve(target))
}
