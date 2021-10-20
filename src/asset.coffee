path= require "path"
config= require "../config"
class Asset
  constructor: (entry)->
    @entry= entry; @deps= []; @map= null; @code= ""; @outputFilename= "";
    @name= path.parse(entry).name
