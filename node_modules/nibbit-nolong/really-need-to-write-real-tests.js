#!/usr/bin/env node

var fs = require("fs"),
    zlib = require("zlib"),
    crypto = require("crypto"),
    nibbit = require("./lib/index");

var ast1 = nibbit.compound([
  nibbit.string("world", "hello"),
  nibbit.byte_array([0xFF, 0xFF, 0xFF, 0xFE], "test byte array"),
  nibbit.list([
    nibbit.string("hello"),
    nibbit.string("world"),
  ], "test list"),
  nibbit.compound([
    nibbit.byte(127, "byte"),
    nibbit.short(32767, "short"),
    nibbit.int(2147483647, "int"),
    nibbit.long(9007199254740992, "long"),
    nibbit.float(1.1, "float"),
    nibbit.double(1.2, "double"),
  ], "compound"),
  nibbit.list([
    nibbit.list([
      nibbit.string("embedded"),
      nibbit.string("list"),
      nibbit.string("one"),
    ]),
    nibbit.list([
      nibbit.string("embedded"),
      nibbit.string("list"),
      nibbit.string("two"),
    ]),
  ], "embedded lists"),
], "root");
console.log(JSON.stringify(ast1, null, 2));
console.log(JSON.stringify(nibbit.convert(ast1), null, 2));

nibbit.encode(ast1, function(err, enc1) {
  console.log(enc1);
  var h1 = crypto.createHash("md5").update(enc1).digest("hex");

  nibbit.decode(enc1, function(err, ast2) {
    console.log(JSON.stringify(ast2, null, 2));
    console.log(JSON.stringify(nibbit.convert(ast2), null, 2));

    nibbit.encode(ast2, function(err, enc2) {
      console.log(enc2);
      var h2 = crypto.createHash("md5").update(enc2).digest("hex");

      console.log([enc1.length, enc2.length]);
      console.log([h1, h2]);

      zlib.gzip(enc2, function(err, compressed) {
        fs.writeFile("./data/complex.nbt", compressed, function(err) {
          console.log("Done");
        });
      });
    });
  });
});
