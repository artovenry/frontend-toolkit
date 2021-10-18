require 'coffeescript/register'
{env, entries, dev}= require "./config.coffee"
{SassCompiler, CoffeeCompiler, PugCompiler}= require "./compiler.coffee"

sassCompiler= new SassCompiler entries.sass
coffeeCompiler= new CoffeeCompiler entries.coffee
pugCompiler= new PugCompiler entries.pug
pugCompiler.sassCompiler= sassCompiler
pugCompiler.coffeeCompiler= coffeeCompiler
do ->
  await Promise.all [
    do ->
      await sassCompiler.compileAll()
      sassCompiler.writeAll()
    do ->
      await coffeeCompiler.compileAll()
      coffeeCompiler.writeAll()
  ]
  await pugCompiler.compileAll()
  pugCompiler.writeAll()
