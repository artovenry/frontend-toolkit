path= require "path"; fs= require "fs"
pug= require "pug"
config= require "config"
{defaults}= require "underscore"


assetUrls:
  sass: _.mapObject @sassCompiler.results, (item, key)->"http://#{dev.host}:#{dev.port}/#{key}.css"
  coffee: _.mapObject @coffeeCompiler.results, (item, key)->"http://#{dev.host}:#{dev.port}/#{key}.js"

locals= defaults (config.compilerOpts.pug.locals),
  env: config.env, dev: config.dev

module.exports= class extends Compiler
  constructor: (entries=[], {@sassCompiler, @coffeeCompiler})->
    super(entries)
  compile: (entry)->
    try
      pugString= fs.readFileSync(path.resolve(entry)).toString()
      {body, dependencies}= pug.compileClientWithDependenciesTracked pugString, filename: path.resolve(entry), self: config.compilerOpts.pug.self

      @deps[entry]= dependencies
      @deps[entry].push path.resolve(entry) # dependencies doesnt include entry as a part of itself

      

      locals= JSON.stringify(locals)
      @results[key]= eval(body + "; template(#{locals})")

      console.log "Compiled: #{entry}"

    catch error
      console.log error
