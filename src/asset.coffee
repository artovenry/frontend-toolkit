path= require "path"
fs= require "fs"
config= require "./config"

createHash= (str)->
  crypto= require "crypto"
  shasum= crypto.createHash('sha1')
  shasum.update str
  shasum.digest('hex').substr(0, config.hashLength - 1)

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
    if hashBust then name += "-" + createHash(@code)
    @outputFilename= name + ".#{extension}"
