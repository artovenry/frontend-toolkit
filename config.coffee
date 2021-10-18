path= require "path"
require("dotenv").config path: path.resolve(".env")

config= require(path.resolve("config.coffee"))
env = config.env ? process.env.NODE_ENV ? "development"
dev = config.dev ?
  host: process.env.HOST ? "localhost"
  port: process.env.PORT ? 3000
  wsport: process.env.WSPORT ? 3001
watch= dev.watch ? sass: "src/sass", pug: "src/pug", coffee: "src/coffee"

module.exports= {config..., env, dev, watch}
