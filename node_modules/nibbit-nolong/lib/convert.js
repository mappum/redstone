// Welcome to the conversion module. It takes care of turning an AST into
// something you can use a little more easily. Note that this is a one way
// operation - JavaScript doesn't keep enough information about numeric types
// to go back to AST from an object.
module.exports = Convert;

// Here's the main entry point!
//
// var converted_object = nibbit.convert(ast);
//
// Basically it wraps the whole thing in an object if the first level tag has
// a name. If this makes no sense, go check out the [NBT documentation](http://wiki.vg/NBT).
function Convert(ast) {
  if (ast[1] !== null) {
    var r = {};
    r[ast[1]] = Convert[ast[0]](ast);
    return r;
  } else {
    return Convert[ast[0]](ast);
  }
}

// All these types just pass right on through, pretty simple. These are the
// `byte`, `short`, `int`, `long`, `float`, `double`, `byte array` and
// `int array` types.
[1,2,3,4,5,6,7,8,11].forEach(function(t) {
  Convert[t] = function(v) { return v[2]; };
});

// This is a `list` - think `list<object>` in C++
Convert[9] = function(v) {
  var r = [];

  v[2].forEach(function(e) {
    r.push(Convert[e[0]](e));
  });

  return r;
};

// This is a `compound` - think `list<pair<string,object>>` in C++
Convert[10] = function(v) {
  var r = {};

  v[2].forEach(function(e) {
    r[e[1]] = Convert[e[0]](e);
  });

  return r;
};
