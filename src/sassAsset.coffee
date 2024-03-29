path= require "path"
fs= require "fs"
config= require "./config"
byteSize= require "byte-size"
Asset= require "./asset"
sass= require "sass"
opts= config.compilerOpts.sass

module.exports= class extends Asset
  @extension= "css"
  @hashBust= opts.hashBust
  if config.purge?
    {PurgeCSS}= require "purgecss"
    purge: (htmls, options)->
      options= Object.assign({
        content: htmls.map (h)->extension: "html", raw: h
        css: [raw: @code]
      }, options)

      result= await new PurgeCSS().purge options
      @code= result[0].css

      size= byteSize(Buffer.byteLength(@code)).toString()
      console.log "Purged: #{@entry} #{size}"

      @setOutputFilename()

  compile: ->
    try
      {css, map, stats}= sass.renderSync
        outFile: @name + ".css"
        file: path.resolve(@entry)
        includePaths: opts.includePaths
        outputStyle: if opts.minify then "compressed" else "expanded"
        sourceMap: if config.purge or opts.hashBust then off else if opts.sourceMap then on else off

      @code= css.toString()
      @setOutputFilename()
      @map= map?.toString()
      size= byteSize(Buffer.byteLength(@code)).toString()
      @deps= stats.includedFiles
      console.log "Compiled: #{@entry} in #{stats.duration}ms, #{size}"
    catch error
      console.log error.formatted
