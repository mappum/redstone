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

  saveInterval: 5 * 60 * 1000     # how often to save chunks inside the region
  chunkReloadInterval: 60 * 1000  # how often we should reload neighboring chunks
  chunkUnloadDelay: 2 * 60 * 1000 # how long a chunk should be inactive before unloading
  chunkInterval: 10               # how long to wait in between sending chunks (to prevent locking up)

  remapInterval: 10 * 60 * 1000
  remapDelay: 20 * 1000

  spawnDelay: 250

  connector:
    'online-mode': false
    encryption: false
    motd: 'Redstone test server'

  database: 'mongodb://localhost/redstone'