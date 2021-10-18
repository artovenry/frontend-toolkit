require("dotenv").config()
env= process.env.NODE_ENV ? "development"
isDev= env is "development"

host= process.env.HOST ? "localhost"
port= process.env.PORT ? 3000
wsport= process.env.WSPORT ? 3001
module.exports=
  env: env
  dev:
    host: host, port: port, wsport: wsport
  watch:
    sass: "src/sass"
    pug: "src/pug"
    coffee: "src/coffee"

  entries:
    pug: [
      "src/pug/index.php.pug"
    ]
    coffee:[
      "src/coffee/main.coffee"
    ]
    sass:[
      "src/sass/style.scss"
      "src/sass/sample.scss"
      "src/sass/bootstrap.scss"
      "src/sass/styleC.scss"
    ]

  output: "compiled"
  compiledUrl: switch env
    when "development" then "http://#{host}:#{port}/"
