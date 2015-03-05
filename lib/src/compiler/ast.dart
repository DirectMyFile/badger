part of badger.compiler;

class AstTarget extends Target<String> {
  @override
  String compile(Program program) {
    var ast = new BadgerJsonBuilder(program);
    var encoder = new JsonEncoder.withIndent("  ");

    return encoder.convert(ast.build());
  }
}
