// This is basically just a wrapper for the [encode](encode.html), 
// [decode](decode.html) and [convert](convert.html) modules. There's also some
// convenience functions for generating ASTs as well.

// Load ALL the things!
exports.encode = require("./encode");
exports.decode = require("./decode");
exports.convert = require("./convert");

// Convenience functions for generating ASTs.
[
  [1, "byte"],
  [2, "short"],
  [3, "int"],
  [4, "long"],
  [5, "float"],
  [6, "double"],
  [7, "byte_array"],
  [8, "string"],
  [9, "list"],
  [10, "compound"],
  [11, "integer_array"]
].forEach(function(type) {
  module.exports[type[1]] = function(value, name) {
    return [type[0], name, value];
  };
});
