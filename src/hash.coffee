crypto= require "crypto"
config= require "../config"

module.exports= (str)->
  shasum= crypto.createHash('sha1')
  shasum.update str
  shasum.digest('hex').substr(0, config.hashLength - 1)
