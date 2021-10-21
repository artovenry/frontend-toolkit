path= require "path"
fs= require "fs"
config= require "./config"

class Asset
  constructor: (entry)->
    @entry= entry; @deps= []; @map= null; @code= ""; @outputFilename= "";
    @name= path.parse(entry).name
  write: ->
    outputTo= path.resolve(path.join(config.output, @outputFilename))
    return Promise.all [
      new Promise (done)=> fs.writeFile outputTo, @code, done
      if @map? then new Promise (done)=>
        outputTo= path.resolve(path.join(config.output, @outputFilename + '.map'))
        fs.writeFile outputTo, @map, done
    ]
