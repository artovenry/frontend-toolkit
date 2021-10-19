path= require "path"; fs= require "fs"
{mapObject}= require "underscore"
config = require "../config"


class Asset
  deps: [], map: null, code: "", outputFilename: ""
  constructor: (@entry)->
  

module.exports= class
  constructor: (@entries= [])->
    @assets= @entries.reduce (m, entry)->
      m[path.basename(entry)] = new Asset entry; return m
    , {}

  ###
  src/coffee/nameA.coffee
  src/coffee/nameB.coffee
  => @assets= {nameA: assetObj, nameB: assetObj}
  ###

  compileAll: ->Promise.all @entries.map (entry)=> @compile entry
  writeAll: ->Promise.all @entries.map (entry)=>@write entry
  write: (entry)->
    ext= if @constructor.ext then ".#{@constructor.ext}" else ""
    outputTo= path.resolve(path.join(config.output, path.basename(entry)) + ext)
    new Promise (done)=>fs.writeFile outputTo, @results[entry], done
  assets: ->
    mapObject @outputFilenames, (entry, filename)->
