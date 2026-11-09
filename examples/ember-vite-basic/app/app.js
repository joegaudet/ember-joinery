import Application from '@ember/application'
import compatModules from '@embroider/virtual/compat-modules'
import Resolver from 'ember-resolver'
import loadInitializers from 'ember-load-initializers'
import config from 'ember-vite-basic/config/environment'
// Joinery's component CSS, in the `joinery` cascade layer, so the app's own CSS always wins.
import '@ember-joinery/ember/joinery.css'
import './styles/app.css'

export default class App extends Application {
  modulePrefix = config.modulePrefix
  podModulePrefix = config.podModulePrefix
  Resolver = Resolver.withModules(compatModules)
}

loadInitializers(App, config.modulePrefix, compatModules)
