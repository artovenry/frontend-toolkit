path= require "path"; fs= require "fs"
pug= require "pug"
config= require "./config"
{defaults, mapObject}= require "underscore"
Asset= require "./asset"

module.exports= class extends Asset
  @assets= sass: [], coffee: []
  @buildAssetUrls= ->
    mapObject @assets, (assets)=>
      assets.reduce (m, a)->
        m[a.name]= config.assetUrl + a.outputFilename
        return m
      , {}

  setOutputFilename: ->@outputFilename= @name
  compile: ->
    try
      pugString= fs.readFileSync(path.resolve(@entry)).toString()
      {body, dependencies}= pug.compileClientWithDependenciesTracked pugString, filename: path.resolve(@entry), self: config.compilerOpts.pug.self
      @deps= dependencies
      @deps.push path.resolve(@entry) # dependencies doesnt include entry as a part of itself
      locals= config.compilerOpts.pug.locals
      locals.env= config.env; locals.dev= config.dev
      locals.assets= @constructor.buildAssetUrls()
      locals= JSON.stringify(locals)
      @code= eval(body + "; template(#{locals})")
      @setOutputFilename()
      console.log "Compiled: #{@entry}"

    catch error
      console.log error
