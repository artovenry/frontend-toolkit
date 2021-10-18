#!/usr/bin/env node
path= require("path")
CoffeeScript= require("coffeescript")
fs= require("fs")
code= fs.readFileSync(path.join(__dirname, "./devServer.coffee"))
compiled= CoffeeScript.compile(code.toString(), {bare: true, header: false})
eval(compiled)
