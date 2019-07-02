import 'package:ebnf_dart/input.dart';
import 'package:ebnf_dart/parser.dart';
import 'package:dartz/dartz.dart';

abstract class Combinators {
  static Ref<I, A> retn<I, A>(A x) {
    return Ref((input) => ConsumedT.empty(
          Reply.ok(x, input, Message.lazy(() => Message.of1(input.position()))),
        ));
  }

  /**
   * Monadic bind function.
   * Bind chains two parsers by creating a parser which calls the first,
   * and if that parser succeeds the resultant value is passed to the
   * function argument to obtain a second parser, which is then invoked.
   * @param p         a parser which is called first
   * @param f         a function which is passed the result of the first parser if successful,
   *                  and which returns a second parser
   * @param <I>       the input symbol type
   * @param <A>       the first parser value type
   * @param <B>       the second parser value type
   * @return          the parser
   */
  static Ref<I, B> bind<I, A, B>(Ref<I, A> p, Function1<A, Ref<I, B>> f) {
    return Ref((input) {
      final ConsumedT<I, A> cons1 = p.apply(input);
      if (cons1.isConsumed()) {
        return ConsumedT.consumed(() => cons1.getReply().match(
              (ok1) {
                final ConsumedT<I, B> cons2 = (f(ok1.result)).apply(ok1.rest);
                return cons2.getReply();
              },
              (error) => error.cast<B>(),
            ));
      } else {
        return cons1.getReply().match((ok1) {
          final ConsumedT<I, B> cons2 = (f(ok1.result)).apply(ok1.rest);
          if (cons2.isConsumed()) {
            return cons2;
          } else {
            return cons2.getReply().match(
                (ok2) => ConsumedT.mergeOk(
                    ok2.result, ok2.rest, ok1.message, ok2.message),
                (error) => ConsumedT.mergeError(ok1.message, error.message));
          }
        }, (error) => ConsumedT.empty(error.cast()));
      }
    });
  }

  /**
   * A parser first tries parser <code>p</code>.
   * If it succeeds or consumes input then its result is returned.
   * Otherwise return the result of applying parser <code>q</code>.
   * @param p         first parser to try with
   * @param q         second parser to try with
   * @param <I>       the input symbol type
   * @param <A>       the parser value type
   * @return          the parser
   */
  static Ref<I, A> or<I, A>(Ref<I, A> p, Ref<I, A> q) {
    return Ref((input) {
      final ConsumedT<I, A> cons1 = p.apply(input);
      if (cons1.isConsumed()) {
        return cons1.cast();
      } else {
        return cons1.getReply().match((ok1) {
          final ConsumedT<I, A> cons2 = q.apply(input);
          if (cons2.isConsumed()) {
            return cons2.cast();
          } else {
            return ConsumedT.mergeOk(
                    ok1.result, ok1.rest, ok1.message, cons2.getReply().message)
                .cast();
          }
        }, (error1) {
          final ConsumedT<I, A> cons2 = q.apply(input);
          if (cons2.isConsumed()) {
            return cons2.cast();
          } else {
            return cons2
                .getReply()
                .match(
                  (ok2) => ConsumedT.mergeOk(
                      ok2.result, ok2.rest, error1.message, ok2.message),
                  (error2) =>
                      ConsumedT.mergeError(error1.message, error2.message),
                )
                .cast();
          }
        });
      }
    });
  }

  static Ref<I, A> choice2<I, A>(Ref<I, A> p1, Ref<I, A> p2) {
    return or(p1, p2);
  }

  static Ref<I, A> choice4<I, A>(
      Ref<I, A> p1, Ref<I, A> p2, Ref<I, A> p3, Ref<I, A> p4) {
    return or(p1, or(p2, or(p3, p4)));
  }

  /**
   * Label a parser with a readable name for more meaningful error messages.
   * @param p         the parser to be labelled
   * @param name      the label (this will appear in the list of expected rules in the event of a failure)
   * @param <I>       the input symbol type
   * @param <A>       the parser value type
   * @return          the parser
   */
  static Ref<I, A> label<I, A>(Ref<I, A> p, String name) {
    return Ref((input) {
      final ConsumedT<I, A> cons = p.apply(input);
      if (cons.isConsumed()) {
        return cons;
      } else {
        return cons.getReply().match(
              (ok) => ConsumedT.empty(
                  Reply.ok(ok.result, ok.rest, ok.message.expect(name))),
              (error) =>
                  ConsumedT.empty(Reply.error(error.message.expect(name))),
            );
      }
    });
  }

  static Ref<I, I> satisfy<I>(Predicate<I> test) {
    return Ref((input) {
      if (!input.end()) {
        final I s = input.current();
        if (test(s)) {
          final Input<I> newInput = input.next0();
          return ConsumedT.consumed(() => Reply.ok(
                s,
                newInput,
                Message.lazy(() => Message.of1(input.position())),
              ));
        } else {
          return ConsumedT.empty(Reply.error(Message.lazy(
              () => Message.of3(input.position(), input.current(), '<test>'))));
        }
      } else {
        return ConsumedT.empty(endOfInput(input, '<test>'));
      }
    });
  }

  static Ref<I, I> satisfy1<I>(I value) {
    return label(satisfy((other) => other == value), value.toString());
  }

  static Ref<I, A> satisfy2<I, A>(I value, A result) {
    return satisfy1(value).then(retn(result));
  }

  static Ref<String, String> chr(String c) {
    return satisfy1(c);
  }

  static final String INTEGER_REGEX = "([0-9]+)";
  static final String DOUBLE_REGEX = "(([0-9]+)(\\.[0-9]+)?([eE][-+]?[0-9]+)?)";

  static final Ref<String, int> lng = bind(
    regex(INTEGER_REGEX),
    (s) => safeRetn((str) => int.parse(str), s, "int"),
  ).label("int");

  static final Ref<String, double> dble = bind(
    regex(DOUBLE_REGEX),
    (s) => safeRetn((s) => double.parse(s), s, "double"),
  ).label("double");

  /**
   * Apply the first parser, then apply the second parser and return the result.
   * This is an optimisation for <code>bind(p, x -&gt; q)</code> - i.e. a parser which discards <code>x</code>,
   * the result of the first parser <code>p</code>.
   * @param p         the first parser
   * @param q         the second parser
   * @param <I>       the input symbol type
   * @param <A>       the first parser value type
   * @param <B>       the second parser value type
   * @return          the parser
   */
  static Ref<I, B> then<I, A, B>(Ref<I, A> p, Ref<I, B> q) {
    return Ref((input) {
      final ConsumedT<I, A> cons1 = p.apply(input);
      if (cons1.isConsumed()) {
        return ConsumedT.consumed(() => cons1.getReply().match<Reply<I, B>>(
              (ok1) {
                final ConsumedT<I, B> cons2 = q.apply(ok1.rest);
                return cons2.getReply();
              },
              (error) => error.cast(),
            ));
      } else {
        return cons1.getReply().match<ConsumedT<I, B>>(
          (ok1) {
            final ConsumedT<I, B> cons2 = q.apply(ok1.rest);
            if (cons2.isConsumed()) {
              return cons2;
            } else {
              return cons2.getReply().match(
                  (ok2) => ConsumedT.mergeOk(
                      ok2.result, ok2.rest, ok1.message, ok2.message),
                  (error2) =>
                      ConsumedT.mergeError(ok1.message, error2.message));
            }
          },
          (error) => cons1.cast(),
        );
      }
    });
  }

  static Reply<I, A> endOfInput<I, A>(Input<I> input, String expected) {
    return Reply.error(
        Message.lazy(() => Message.endOfInput(input.position(), expected)));
  }

  /**
   * A parser which accepts a string which matches the supplied regex.
   * @param regex the regular expression
   * @return      the parser
   */
  static Ref<String, String> regex(String regex) {
    final RegExp pattern = RegExp(regex, multiLine: true);
    return Ref((state) {
      String cs;
      if (state is StringInput) {
        final StringInput input = state;
        cs = input.getCharSequence();
      } else {
        throw new Exception('regex only supported on CharState inputs');
      }

      final Match match = pattern.firstMatch(cs);
      final Message<String> msg = Message.lazy(() => Message.of3(
          state.position(), state.current(), "Regex(\"${regex}\")"));

      if (match != null && match.start == 0) {
        final int end = match.end;
        final String str = cs.substring(0, end);
        return ConsumedT.consumed(() => Reply.ok(str, state.next(end), msg));
      } else {
        return ConsumedT.empty(Reply.error(msg));
      }
    });
  }

  // Variant of retn which translates exceptions into ConsumedT errors.
  static Ref<String, A> safeRetn<A>(
      Function1<String, A> f, String s, String expected) {
    return Ref((input) {
      try {
        final A val = f(s);
        return ConsumedT.empty(Reply.ok(
            val, input, Message.lazy(() => Message.of1(input.position()))));
      } catch (e) {
        return ConsumedT.empty(Reply.error(Message.lazy(
            () => Message.of3(input.position(), input.current(), expected))));
      }
    });
  }

  /**
   * A parser which succeeds if the end of the input is reached.
   * @param <I>       the input symbol type
   * @return          the parser
   */
  static Ref<I, Unit> eof<I>() {
    return Ref((input) {
      if (input.end()) {
        return ConsumedT.empty(
          Reply.ok2(
            input,
            Message.lazy(() => Message.of2(input.position(), 'EOF')),
          ),
        );
      } else {
        return ConsumedT.empty(Reply.error(Message.lazy(
            () => Message.of3(input.position(), input.current(), 'EOF'))));
      }
    });
  }
}
