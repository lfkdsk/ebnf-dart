library ebnf_dart;

import 'package:dartz/dartz.dart';

//Exception mzero() {
//  return Exception('mzero parser fails');
//}
//
//class Parser<Tok, A> {
//  Option<A> parse(IList<Tok> input) {
//    throw mzero();
//  }
//}
//
//class Zero<Tok> with Parser<Tok, Unit> {
//  Option<Unit> parse(IList<Tok> input) {
//    return optionOf(unit);
//  }
//}
//
//class One<Tok> with Parser<Tok, Unit> {
//  @override
//  Option<Unit> parse(IList<Tok> input) {
//    if (input.length == 0) {
//      return optionOf(unit);
//    }
//
//    throw mzero();
//  }
//}
//
//typedef check = bool Function<Tok>(Tok a);
//typedef satisfy = bool Function<Tok>(IList<Tok> a);
//
//class Check<Tok> with Parser<Tok, Tok> {
//  check pre;
//
//  Check(this.pre);
//
//  // input is [t]
//  @override
//  Option<Tok> parse(IList<Tok> input) {
//    if (input.length == 0) {
//      throw mzero();
//    }
//
//    if (input.length == 1 || pre(input.headOption)) {
//      return input.headOption;
//    }
//
//    throw mzero();
//  }
//}
//
//

//class Satisfy<Tok> with Parser<Tok, IList<Tok>> {
//  satisfy pre;
//
//  Satisfy(this.pre);
//
//  @override
//  IList<Tok> parse(IList<Tok> xs) {
//    if (pre(xs)) {
//      return xs;
//    }
//
//    throw mzero();
//  }
//}
//
//// parse (Push t x) ts = parse x (t:ts)
//class Push<Tok, A> with Parser<Tok, A> {
//  Parser<Tok, A> x;
//  Option<Tok> t;
//
//  Push(this.x, this.t);
//
//  @override
//  A parse(IList<Tok> ts) {
//    return x.parse(cons(t | null, ts));
//  }
//}
//
//class Plus<Tok, A, B> with Parser<Tok, Either<A, B>> {
//  Parser<Tok, A> parserA;
//  Parser<Tok, B> parserB;
//
//  Plus(this.parserA, this.parserB);
//
//  @override
//  Either<A, B> parse(IList<Tok> input) {
//    return left(parserA.parse(input)) | right(parserB.parse(input));
//  }
//}
//
//class Times<Tok, A, B> with Parser<Tok, Tuple2<A, B>> {
//  Parser<Tok, A> parserA;
//  Parser<Tok, B> parserB;
//
//  Times(this.parserA, this.parserB);
//
//  @override
//  Tuple2<A, B> parse(IList<Tok> input) {
//    final IList<Tok> empty = nil();
//    if (input == null || input.length == 0) {
//      return tuple2(parserA.parse(empty), parserB.parse(empty));
//    }
//
//    Option<Tok> t = input.headOption;
//    Option<IList<Tok>> ts = input.tailOption;
//    Push<Tok, A> push = Push(parserA, t);
//    Times<Tok, A, B> times = Times(push, parserB);
//    Tuple2<A, B> left = times.parse(ts | nil());
//    Tuple2<A, B> right = tuple2(parserA.parse(empty), parserB.parse(input));
//  }
//}
//
//Option<A> parse<Tok, A>(Parser<Tok, A> parser, List<Tok> a) {}
