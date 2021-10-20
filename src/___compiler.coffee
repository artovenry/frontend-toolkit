path= require "path"; fs= require "fs"
{mapObject, keys}= require "underscore"
config = require "../config"


class Asset
  constructor: (entry)->
    @entry= entry; @deps= []; @map= null; @code= ""; @outputFilename= "";

module.exports= class
  constructor: (entries= [])->
    @entries= entries
    @assets= @entries.reduce (m, entry)->
      m[entry] = new Asset entry; return m
    , {}

  compileAll: ->Promise.all @entries.map (entry)=> @compile entry
  writeAll: ->Promise.all @entries.map (entry)=>@write entry
  write: (entry)->
    ext= if @constructor.ext then ".#{@constructor.ext}" else ""
    outputTo= path.resolve(path.join(config.output, path.basename(entry)) + ext)
    new Promise (done)=>fs.writeFile outputTo, @results[entry], done
  buildAssets: ->
    keys(@assets).reduce (m, entry)->
      
