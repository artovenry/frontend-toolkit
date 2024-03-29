path= require "path"
require("dotenv").config path: path.resolve(".env")
{defaults} = require "underscore"

config= require(path.resolve("config.coffee"))

env = config.env ? process.env.NODE_ENV ? "development"
isDev= env is "development"
dev= defaults (config.dev ? {}),
  host: process.env.HOST ? "localhost"
  port: process.env.PORT ? 3000
  wsport: process.env.WSPORT ? 3001

module.exports=
  entries: defaults (config.entries ? {}),
    sass: [], coffee: [], pug: []
  env: env, dev: dev
  watch: defaults (config.watch ? {}),
    sass: "src/sass", pug: "src/pug", coffee: "src/coffee"
  output: config.output ? "compiled"
  hashLength: config.hashLength ? 8
  assetUrl: config.assetUrl ? "http://#{dev.host}:#{dev.port}/"
  purge: config.purge ? {}
  ###
    purge: {"someCssFilename": ["extractor1", "extractor2", "extractor3"]}
    OR
    purge: {"someCssFilename": {
      htmls: ["extractor1", "extractor2", "extractor3"]
      options: {
        PurgeCSS options go here, for example safelist.
      }
    }}
  ###
  compilerOpts:
    sass: defaults (config.compilerOpts?.sass ? {}),
      includePaths: ["node_modules"]
      sourceMap : if isDev then on  else off
      hashBust  : if isDev then off else on
      minify    : if isDev then off else on
    coffee: defaults (config.compilerOpts?.coffee ? {}),
      define: defaults (config.compilerOpts?.coffee?.define ? {}),
        'process.env.NODE_ENV': JSON.stringify(env)
      resolve: ["node_modules"]
      minify    : if isDev then off else on
      sourceMap : if isDev then on  else off
      hashBust  : if isDev then off else on
    pug: defaults (config.compilerOpts?.pug ? {}),
      self: on, locals: {}
