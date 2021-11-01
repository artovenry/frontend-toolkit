path= require "path"
fs= require "fs"
{select, contains, bind}= require "underscore"
chokidar= require "chokidar"

module.exports= class
  constructor: ({targetDir, @assets})->
    @target= path.resolve targetDir
  watch: ({afterCompile})->
    return if not fs.existsSync @target
    compileAll= =>
      Promise.all @assets.map (a)->a.compile()
    compile= (filepath)=>
      Promise.all do =>
        select @assets, (a)->contains a.deps, filepath
        .map (a)->a.compile()

    return new Promise (done)=>
      watcher= chokidar.watch @target
      watcher.on "ready", =>
        await compileAll()
        done()
        afterCompile?.bind(@)()
        watcher.on "all", (e, filepath)=>
          return if not e.match /^(add|change|unlink)$/
          await compile(filepath)
          afterCompile?.bind(@)()
