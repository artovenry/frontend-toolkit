path= require "path"
fs= require "fs"
config= require "./config"

module.exports= class
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
  setOutputFilename: ->
    name= @name
    {extension, hashBust}= @constructor
    if hashBust then name += "-" + (require "./hash")(@code)
    @outputFilename= name + ".#{extension}"
