#!/usr/bin/env node

var fs = require("fs"),
    zlib = require("zlib"),
    crypto = require("crypto"),
    nibbit = require("./lib/index");

if (process.argv.length < 3) {
  console.log("Usage: " + process.argv[0] + " <file.nbt>");
  process.exit(-1);
}

fs.readFile(process.argv[2], function(err, compressed) {
  if (err) { return console.log(err); }

  zlib.gunzip(compressed, function(err, data) {
    if (err) { return console.log(err); }

    nibbit.decode(data, function(err, decoded) {
      if (err) { return console.log(err); }

      console.log(JSON.stringify(decoded));

      var converted = nibbit.convert(decoded);

      console.log(JSON.stringify(converted));

      var encoded = nibbit.encode(decoded);

      console.log([data.length, encoded.length]);

      var h1 = crypto.createHash("md5").update(data).digest("hex"),
          h2 = crypto.createHash("md5").update(encoded).digest("hex");

      console.log([h1, h2]);
    });
  });
});
