part of badger.eval;

class StandardLibrary {
  static void import(Context context) {
    context.proxy("print", print);
    context.proxy("currentContext", () => Context.current);
    context.proxy("newContext", () => new Context());
    context.proxy("run", (func) => func([]));
    context.proxy("NativeHelper", NativeHelper);
    context.proxy("JSON", BadgerJSON);
    context.proxy("make", (type, [args = const []]) {
      return reflectClass(type).newInstance(MirrorSystem.getSymbol(""), args).reflectee;
    });
  }
}

class BadgerHttpClient {
  Future<BadgerHttpResponse> get(String url, [Map<String, String> headers]) async {
    var client = new HttpClient();
    HttpClientRequest req = await client.getUrl(Uri.parse(url));
    if (headers != null) {
      for (var key in headers.keys) {
        req.headers.set(key, headers[key]);
      }
    }
    HttpClientResponse res = await req.close();
    var bytes = [];
    await for (var x in res) {
      bytes.addAll(x);
    }
    var heads = {};
    res.headers.forEach((x, y) {
      heads[x] = y.first;
    });
    client.close();
    return new BadgerHttpResponse(heads, bytes);
  }
}

class BadgerHttpResponse {
  final Map<String, String> headers;
  final List<int> bytes;
  String _body;

  String get body {
    if (_body == null) {
      _body = UTF8.decode(bytes);
    }
    return _body;
  }

  BadgerHttpResponse(this.headers, this.bytes);
}

class BadgerJSON {
  static dynamic parse(String input) {
    return JSON.decode(input);
  }

  static String encode(input, [bool pretty = false]) {
    return pretty ? new JsonEncoder.withIndent("  ").convert(input) : JSON.encode(input);
  }
}

class NativeHelper {
  static LibraryMirror getLibrary(String name) {
    var symbol = new Symbol(name);

    return currentMirrorSystem().findLibrary(symbol);
  }
}

class IOLibrary {
  static void import(Context context) {
    context.proxy("HttpClient", BadgerHttpClient);
  }
}

class TestingLibrary {
  static void import(Context context) {
    context.define("test", (name, func) {
      if (!Context.current.meta.containsKey("__tests__")) {
        Context.current.meta["__tests__"] = [];
      }

      var tests = Context.current.meta["__tests__"];

      tests.add([name, func]);
    });

    context.define("testEqual", (a, b) {
      var result = a == b;

      if (!result) {
        throw new Exception("Test failed: ${a} != ${b}");
      }
    });

    context.define("shouldThrow", (func) async {
      var threw = false;

      try {
        await func([]);
      } catch (e) {
        threw = true;
      }

      if (!threw) {
        throw new Exception("Function did not throw an exception.");
      }
    });

    context.define("runTests", ([prefix]) async {
      Context.current.meta["tests.ran"] = true;

      if (!Context.current.meta.containsKey("__tests__")) {
        print("${prefix != null ? '[${prefix}] ' : ''}No Tests Defined");
      } else {
        var tests = Context.current.meta["__tests__"];

        for (var test in tests) {
          var name = test[0];
          var func = test[1];

          try {
            await func([]);
          } catch (e) {
            print("${prefix != null ? '[${prefix}] ' : ''}${name}: Failure");
            print(e.toString());
            exit(1);
          }

          print("${prefix != null ? '[${prefix}] ' : ''}${name}: Success");
        }
      }
    });
  }
}
