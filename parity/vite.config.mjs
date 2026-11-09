import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import upstream from './upstream-plugin.mjs'

// The parity reference app. `pnpm --dir parity start` serves it; `/<example-id>` renders one
// upstream example (see parity/README.md). scripts/parity.mjs builds it with PARITY_EXAMPLES set
// to the examples it compares, and serves the build.
export default defineConfig({
  plugins: [upstream(), react(), tailwindcss()],
  build: { outDir: 'dist', emptyOutDir: true, chunkSizeWarningLimit: 4096 },
  logLevel: process.env.PARITY_QUIET ? 'warn' : 'info',
})
