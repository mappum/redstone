// The parser is based on [node-binary](https://github.com/substack/node-binary).
var binary = require("binary");

// Welcome to the decoding module. Here you'll find all manner of decode related
// functionality. Feel free to clarify any comments here.
module.exports = Decode;

// This is where you'll want to start. The usage is usually like this:
//
//    nibbit.decode(some_buffer, function(err, ast) { ... });
//
// If the first element isn't a compound type (mentioned as being mandatory on
// [the wiki](http://wiki.vg/NBT), it'll throw an error. In other
// error cases, it'll probably just throw exceptions and/or set fire to your
// computer. It's not very well tested with bad input.
//
// This file could really do with more documentation on how the stuff works
// internally.
function Decode(data, done) {
  b = binary(data);

  b.word8("type").tap(function(vars) {
    var type = vars.type;
    delete vars.type;

    if (type != 10) {
      return done(Error("first tag must be compound"));
    }

    Decode[type](b, true).tap(function(vars) {
      return done(null, vars.data);
    });
  });
};

Decode.byte = Decode[1] = function(b, has_name) {
  if (has_name) {
    b.word16bs("name_length").buffer("name", "name_length");
  }

  b.word8s("data");

  b.tap(function(vars) {
    var name = null;

    if (vars.name_length && vars.name) {
      name = vars.name.toString();
      delete vars.name_length;
      delete vars.name;
    }

    vars.data = [1, name, vars.data];
  });

  return b;
};

Decode.short = Decode[2] = function(b, has_name) {
  if (has_name) {
    b.word16bs("name_length").buffer("name", "name_length");
  }

  b.word16bs("data");

  b.tap(function(vars) {
    var name = null;

    if (vars.name_length && vars.name) {
      name = vars.name.toString();
      delete vars.name_length;
      delete vars.name;
    }

    vars.data = [2, name, vars.data];
  });

  return b;
};

Decode.integer = Decode[3] = function(b, has_name) {
  if (has_name) {
    b.word16bs("name_length").buffer("name", "name_length");
  }

  b.word32bs("data");

  b.tap(function(vars) {
    var name = null;

    if (vars.name_length && vars.name) {
      name = vars.name.toString();
      delete vars.name_length;
      delete vars.name;
    }

    vars.data = [3, name, vars.data];
  });

  return b;
};

Decode.long = Decode[4] = function(b, has_name) {
  if (has_name) {
    b.word16bs("name_length").buffer("name", "name_length");
  }

  b.word64bs("data");

  b.tap(function(vars) {
    var name = null;

    if (vars.name_length && vars.name) {
      name = vars.name.toString();
      delete vars.name_length;
      delete vars.name;
    }

    vars.data = [4, name, vars.data];
  });

  return b;
};

Decode.float = Decode[5] = function(b, has_name) {
  if (has_name) {
    b.word16bs("name_length").buffer("name", "name_length");
  }

  b.buffer("data", 4);

  b.tap(function(vars) {
    var name = null;

    if (vars.name_length && vars.name) {
      name = vars.name.toString();
      delete vars.name_length;
      delete vars.name;
    }

    vars.data = [5, name, vars.data.readFloatBE(0)];
  });

  return b;
};

Decode.double = Decode[6] = function(b, has_name) {
  if (has_name) {
    b.word16bs("name_length").buffer("name", "name_length");
  }

  b.buffer("data", 8);

  b.tap(function(vars) {
    var name = null;

    if (vars.name_length && vars.name) {
      name = vars.name.toString();
      delete vars.name_length;
      delete vars.name;
    }

    vars.data = [6, name, vars.data.readDoubleBE(0)];
  });

  return b;
};

Decode.byte_array = Decode[7] = function(b, has_name) {
  if (has_name) {
    b.word16bs("name_length").buffer("name", "name_length");
  }

  b.word32bs("length").buffer("data", "length");

  b.tap(function(vars) {
    var name = null;

    if (vars.name_length && vars.name) {
      name = vars.name.toString();
      delete vars.name_length;
      delete vars.name;
    }

    vars.data = [7, name, Array.prototype.slice.apply(vars.data)];
    delete vars.length;
  });

  return b;
};

Decode.string = Decode[8] = function(b, has_name) {
  if (has_name) {
    b.word16bs("name_length").buffer("name", "name_length");
  }

  b.word16be("data_length").buffer("data", "data_length");

  b.tap(function(vars) {
    var name = null;

    if (vars.name_length && vars.name) {
      name = vars.name.toString();
      delete vars.name_length;
      delete vars.name;
    }

    vars.data = [8, name, vars.data.toString()];
    delete vars.data_length;
  });

  return b;
};

Decode.list = Decode[9] = function(b, has_name) {
  if (has_name) {
    b.word16be("name_length").buffer("name", "name_length");
  }

  b.word8s("type").word32bs("count");

  b.tap(function(vars) {
    var name = null, type = null, count = 0, elements = [];

    if (vars.name_length && vars.name) {
      name = vars.name.toString();
      delete vars.name_length;
      delete vars.name;
    }

    type = vars.type;
    count = vars.count;

    delete vars.type;
    delete vars.count;

    var i = 0;
    b.loop(function(end) {
      if (i++ >= count) {
        return end();
      }

      Decode[type](this, false).tap(function(vars) {
        elements.push(vars.data);
        delete vars.data;
      });
    }).tap(function(vars) {
      vars.data = [9, name, elements];
    });
  });

  return b;
};

Decode.compound = Decode[10] = function(b, has_name) {
  if (has_name) {
    b.word16be("name_length").buffer("name", "name_length");
  }

  b.tap(function(vars) {
    var name = null, elements = [];

    if (vars.name_length && vars.name) {
      name = vars.name.toString();
      delete vars.name_length;
    }

    this.loop(function(end, vars) {
      this.word8("type").tap(function(vars) {
        var type = vars.type;
        delete vars.type;

        if (type === 0 || type === null) {
          return end();
        }

        Decode[type](this, true).tap(function(vars) {
          elements.push(vars.data);
          delete vars.data;
        });
      });
    }).tap(function(vars) {
      vars.data = [10, name, elements];
    });
  });

  return b;
};

Decode.integer_array = Decode[11] = function(b, has_name) {
  if (has_name) {
    b.word16bs("name_length").buffer("name", "name_length");
  }

  b.word32bs("count");

  b.tap(function(vars) {
    var name = null, count = 0, elements = [];

    if (vars.name_length && vars.name) {
      name = vars.name.toString();
      delete vars.name_length;
      delete vars.name;
    }

    count = vars.count;
    delete vars.count;

    var i = 0;
    this.loop(function(end) {
      if (i++ >= count) {
        return end();
      }

      Decode.integer(this).tap(function(vars) {
        elements.push(vars.data);
        delete vars.data;
      });
    }).tap(function(vars) {
      vars.data = [11, name, elements];
    });
  });

  return b;
};
