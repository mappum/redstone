redstone
========

A distributed, infinite-player Minecraft server that runs on Node.js.

Redstone can support theoretically infinite players in one game world by transparently breaking up the work to multiple servers. Being based on Node.js, it has blazing fast IO performance, which means lower resource consumption and lower latency than standard Java servers.

## Status

Redstone currently only supports creative mode, and is missing much of the game logic. The framework for the clustering of servers is present and functional, but could use some reorganization.
This was originally a private project. Since I don't have enough time to spend on it anymore, I am open-sourcing it to allow the community to contribute and progress the code.
When I have time, I will document the current architecture to make it easier to figure out what's going on.

## Usage

First, make sure you have a MongoDB instance running. By default, Redstone connects to a MongoDB server on `localhost`, but if neccessary, you can configure the Mongo URI via the `database` parameter in `config.coffee`.

Install the dependencies:
```
npm install
```
Start the server (simple mode, all components in one process):
```
coffee bin/redstone
```

On Windows, you must compile the script to Javascript then run it:
```
coffee -cp bin/redstone > bin/redstone.js
node bin/redstone.js

