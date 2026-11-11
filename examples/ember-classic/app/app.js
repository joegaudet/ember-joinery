import Application from '@ember/application'
import Resolver from 'ember-resolver'
import loadInitializers from 'ember-load-initializers'
import config from 'ember-classic/config/environment'
// ember-auto-import bundles Joinery's CSS: the theme's tokens, then the components, in the
// `joinery` cascade layer.
import '@ember-joinery/ember/tokens.css'
import '@ember-joinery/ember/joinery.css'

export default class App extends Application {
  modulePrefix = config.modulePrefix
  podModulePrefix = config.podModulePrefix
  Resolver = Resolver
}

loadInitializers(App, config.modulePrefix)
