packageJson = JSON.parse require('fs').readFileSync('./package.json', 'utf8')
nodeVersion = process.versions.node
redstoneVersion = packageJson.version

module.exports =
  motd: [
    '§cWelcome to the Redstone test server!'
    "Running Node.js §a#{nodeVersion}§r, Redstone §a#{redstoneVersion}"
    'This server is experimental, so expect bugs'
  ]

  worlds: [
    id: 'main'
    persistent: true
    time: 5000
  ]

  connector:
    'online-mode': false
    encryption: false
    motd: 'Redstone test server'

  database: 'mongodb://localhost/redstone'