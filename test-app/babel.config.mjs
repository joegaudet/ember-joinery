import { dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { babelCompatSupport, templateCompatSupport } from '@embroider/compat/babel'

export default {
  plugins: [
    [
      '@babel/plugin-transform-typescript',
      {
        allExtensions: true,
        onlyRemoveTypeImports: true,
        allowDeclareFields: true,
      },
    ],
    [
      'babel-plugin-ember-template-compilation',
      {
        enableLegacyModules: [
          'ember-cli-htmlbars',
          'ember-cli-htmlbars-inline-precompile',
          'htmlbars-inline-precompile',
        ],
        transforms: [...templateCompatSupport()],
      },
    ],
    [
      'module:decorator-transforms',
      {
        runtime: {
          import: fileURLToPath(import.meta.resolve('decorator-transforms/runtime-esm')),
        },
      },
    ],
    [
      '@babel/plugin-transform-runtime',
      {
        absoluteRuntime: dirname(fileURLToPath(import.meta.url)),
        useESModules: true,
        regenerator: false,
      },
    ],
    ...babelCompatSupport(),
  ],

  overrides: [
    {
      // The harness tests check that `@child` works as a standard decorator too, so this one
      // fixture compiles with standard decorators in place of the legacy ones above.
      test: /[\\/]tests[\\/]fixtures[\\/]harness[\\/]standard-decorators\.ts$/,
      plugins: [
        ['module:decorator-transforms', false],
        ['@babel/plugin-proposal-decorators', { version: '2023-11' }],
      ],
    },
  ],

  generatorOpts: {
    compact: false,
  },
}
