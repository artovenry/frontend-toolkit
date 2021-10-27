path= require "path"; fs= require "fs"
pug= require "pug"
config= require "./config"
{defaults}= require "underscore"
Asset= require "./asset"

buildAssetUrls= (assets)->
  assets.reduce (m, a)->
    m[a.name]= config.assetUrl + a.outputFilename
    return m
  , {}

module.exports= class extends Asset
  compile: (assets)->
    try
      pugString= fs.readFileSync(path.resolve(@entry)).toString()
      {body, dependencies}= pug.compileClientWithDependenciesTracked pugString, filename: path.resolve(@entry), self: config.compilerOpts.pug.self
      @deps= dependencies
      @deps.push path.resolve(@entry) # dependencies doesnt include entry as a part of itself
      locals= defaults (config.compilerOpts.pug.locals),
        env: config.env, dev: config.dev
      locals.assets= sass: buildAssetUrls(assets.sass), coffee: buildAssetUrls(assets.coffee)
      locals= JSON.stringify(locals)
      @code= eval(body + "; template(#{locals})")
      @outputFilename= @name
      console.log "Compiled: #{@entry}"

    catch error
      console.log error
