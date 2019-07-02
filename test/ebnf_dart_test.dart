import 'package:dartz/dartz.dart';
import 'package:ebnf_dart/input.dart';
import 'package:test/test.dart';
import 'package:ebnf_dart/parser.dart';
import 'package:ebnf_dart/combinators.dart';
//import 'package:ebnf_dart/ebnf_dart.dart';

void main() {
  test('simple expr.', () {
    final Ref<String, double> expr = Parsers.refEmpty();
    final Ref<String, BinaryOperator<double>> add =
        Combinators.retn((l, r) => l + r);
    final Ref<String, BinaryOperator<double>> sub =
        Combinators.retn((l, r) => l - r);
    final Ref<String, BinaryOperator<double>> times =
        Combinators.retn((l, r) => l * r);
    final Ref<String, BinaryOperator<double>> divide =
        Combinators.retn((l, r) => l / r);

    // bin-op ::= '+' | '-' | '*' | '/'
    final Ref<String, BinaryOperator<double>> binOp = Combinators.choice4(
      Combinators.chr('+').then(add),
      Combinators.chr('-').then(sub),
      Combinators.chr('*').then(times),
      Combinators.chr('/').then(divide),
    );

    // bin-expr ::= '(' expr bin-op expr ')'
    final Ref<String, double> binOpExpr = Combinators.chr('(').then(
      expr.bind(
        (l) => binOp.bind(
              (op) => expr.bind(
                    (r) => Combinators.chr(')').then(
                          Combinators.retn(
                            op(l, r),
                          ),
                        ),
                  ),
            ),
      ),
    );

    expr.setRef(Combinators.choice2(Combinators.dble, binOpExpr));

    final Ref<String, Unit> eof = Combinators.eof();

    final Ref<String, double> parser = expr.bind(
        (d) => eof.then(
          Combinators.retn(d)
        )
    );

    void evaluate(String s) {
      print("$s == ${parser.parse(Input.string(s)).getResult()}");
    }

     evaluate("(100000+1000)");
//    print('\n');
//    print(Combinators.regex(Combinators.DOUBLE_REGEX).parse(Input.string("100.0")).getResult());
//    print(Combinators.regex(Combinators.INTEGER_REGEX).parse(Input.string("100")).getResult());
//    print('dble ${Combinators.dble}, ${Combinators.dble.parser}');

//    print(Combinators.dble.parse(Input.string("100")).getResult());
  });
}
