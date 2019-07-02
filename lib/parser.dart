import 'package:dartz/dartz.dart';
import 'package:ebnf_dart/combinators.dart';
import 'package:ebnf_dart/input.dart';

typedef T Supplier<T>();
typedef ConsumedT<I, A> Parser<I, A>(Input<I> input);
// typedef Supplier<Parser<I, A>> Ref<I, A>();
typedef R BiFunction<T, U, R>(T t, U u);
typedef T BinaryOperator<T>(T t1, T t2);
typedef bool Predicate<I>(I i);

abstract class Message<I> {
  static Message<I> lazy<I>(Supplier<Message<I>> supplier) {
    return LazyMessage(supplier);
  }

  static Message<I> of0<I>() {
    return EmptyMessage.create();
  }

  static Message<I> of1<I>(int pos) {
    return MessageImpl(pos, null, Set.of([]));
  }

  static Message<I> of2<I>(int pos, String expected) {
    return MessageImpl(pos, null, Set.of([expected]));
  }

  static Message<I> of3<I>(int pos, I sym, String expected) {
    return MessageImpl(pos, sym, Set.of([expected]));
  }

  static Message<I> endOfInput<I>(int pos, String expected) {
    return EndOfInput(pos, Set.of([expected]));
  }

  LazyMessage<I> expect(String name) {
    return Message.lazy(() => Message.of3(position(), symbol(), name));
  }

  int position();

  // The symbol that caused the error.
  I symbol();

  Set<String> expected();

  Message<I> merge(Message<I> rhs) {
    return Message.lazy(() =>
        MessageImpl(
          this.position(),
          this.symbol(),
          this.expected().union(rhs.expected()),
        ));
  }
}

class EndOfInput<I> extends Message<I> {
  final int _pos;
  final Set<String> _expected;

  EndOfInput(this._pos, this._expected);

  @override
  Set<String> expected() {
    return _expected;
  }

  @override
  int position() {
    return _pos;
  }

  @override
  I symbol() {
    return null;
  }
}

class MessageImpl<I> extends Message<I> {
  final int _pos;
  final I _sym;
  final Set<String> _expected;

  MessageImpl(this._pos, this._sym, this._expected);

  @override
  int position() {
    return _pos;
  }

  @override
  I symbol() {
    return _sym;
  }

  @override
  Set<String> expected() {
    return _expected;
  }
}

class EmptyMessage<I> extends Message<I> {
  @override
  Set<String> expected() {
    return null;
  }

  static EmptyMessage<T> create<T>() {
    return new EmptyMessage<T>();
  }

  @override
  int position() {
    return 0;
  }

  @override
  I symbol() {
    return null;
  }
}

class LazyMessage<I> extends Message<I> {
  Supplier<Message<I>> _supplier;
  Message<I> _value;

  LazyMessage(this._supplier);

  Message<I> get() {
    if (_supplier != null) {
      _value = _supplier();
      _supplier = null;
    }

    return _value;
  }

  @override
  Set<String> expected() {
    return get().expected();
  }

  @override
  int position() {
    return get().position();
  }

  @override
  I symbol() {
    return get().symbol();
  }
}

abstract class Reply<I, A> {
  final Message<I> message;

  Reply(this.message);

  static OK<I, A> ok<I, A>(A result, Input<I> tail, Message<I> msg) {
    return new OK(result, tail, msg);
  }

  static OK<I, A> ok2<I, A>(Input<I> tail, Message<I> msg) {
    return new OK((unit as A), tail, msg);
  }

  static Error<I, A> error<I, A>(Message<I> msg) {
    return new Error(msg);
  }

  B match<B>(Function1<OK<I, A>, B> ok, Function1<Error<I, A>, B> error);

  A getResult();
}

class OK<I, A> extends Reply<I, A> {
  final A result;
  final Input<I> rest;

  OK(this.result, this.rest, Message<I> msg) : super(msg);

  @override
  B match<B>(Function1<OK<I, A>, B> ok, Function1<Error<I, A>, B> error) {
    return ok(this);
  }

  @override
  A getResult() {
    return result;
  }
}

class Error<I, A> extends Reply<I, A> {
  Error(Message<I> msg) : super(msg);

  @override
  B match<B>(Function1<OK<I, A>, B> ok, Function1<Error<I, A>, B> error) {
    return error(this);
  }

  Reply<I, B> cast<B>() {
    dynamic p = this;
    return p;
  }

  @override
  A getResult() {
    throw new Exception(message.toString());
  }
}

/**
 * ConsumedT is a discriminated union between a Consumed type and an Empty type.
 * Wraps a parse result (Reply) and indicates whether the parser consumed input
 * in the process of computing the parse result.
 * @param <I> Input stream symbol type.
 * @param <A> Parse result type
 */
abstract class ConsumedT<I, A> {
  static ConsumedT<I, A> consumed<I, A>(Supplier<Reply<I, A>> supplier) {
    return new Consumed<I, A>(supplier);
  }

  static ConsumedT<I, A> empty<I, A>(Reply<I, A> reply) {
    return new Empty<I, A>(reply);
  }

  static ConsumedT<I, A> of<I, A>(bool consumed,
      Supplier<Reply<I, A>> supplier) {
    return consumed
        ? ConsumedT.consumed(supplier)
        : ConsumedT.empty(supplier());
  }

  bool isConsumed();

  Reply<I, A> getReply();

  ConsumedT<I, B> cast<B>() {
    dynamic ca = this;
    return ca;
  }

  static ConsumedT<I, A> mergeOk<I, A>(A x, Input<I> input, Message<I> msg1,
      Message<I> msg2) {
    return ConsumedT.empty(Reply.ok(x, input, msg1.merge(msg2)));
  }

  static ConsumedT<I, A> mergeError<I, A>(Message<I> msg1, Message<I> msg2) {
    return ConsumedT.empty(Reply.error(msg1.merge(msg2)));
  }
}

/**
 * A parse result that indicates the parser did consume some input.
 * Consumed is lazy with regards to the reply it wraps.
 */
class Consumed<I, A> extends ConsumedT<I, A> {
// Lazy Reply supplier.
  Supplier<Reply<I, A>> supplier;

// Lazy-initialised Reply.
  Reply<I, A> reply;

  Consumed(Supplier<Reply<I, A>> supplier) {
    this.supplier = supplier;
  }

  @override
  bool isConsumed() {
    return true;
  }

  @override
  Reply<I, A> getReply() {
    if (supplier != null) {
      reply = supplier();
      supplier = null;
    }

    if (reply == null) {
      print(this);
      throw Exception('null point reply');
    }

    return reply;
  }
}

/**
 * A parse result that indicates the parser did not consume any input.
 */
class Empty<I, A> extends ConsumedT<I, A> {
  final Reply<I, A> reply;

  Empty(this.reply);

  bool isConsumed() {
    return false;
  }

  Reply<I, A> getReply() {
    return reply;
  }
}

class Ref<I, A> {
  Parser<I, A> _parser;

  Ref(this._parser);

  set parser(Parser<I, A> value) {
    _parser = value;
  }

  void setRef(Ref<I, A> value) {
    _parser = value._parser;
  }

  Parser<I, A> get parser => _parser == null ? throw Exception() : _parser;

  ConsumedT<I, A> apply(Input<I> input) {
    print('parser ${parse} input ${input}');
    return parser(input);
  }

  Ref<I, B> then<B>(Ref<I, B> p) {
    return Combinators.then(this, p);
  }

  Ref<I, A> label(String name) {
    return Combinators.label(this, name);
  }

  Ref<I, B> bind<B>(Function1<A, Ref<I, B>> f) {
    return Combinators.bind(this, f);
  }

  /**
   * Parse the input state, extract the result and apply one of the supplied functions.
   * @return a parse result
   */
  Reply<I, A>  parse(Input<I> input) {
    var apply1 = apply(input);

    print('apply1 ${(apply1 as Consumed).supplier}');

    return
        apply1
          .getReply()
          .match(
              // Strip off the message if the parse was successful.
              (ok) => Reply.ok(ok.result, ok.rest, Message.of0()),
              (error) => error,
      );
  }
}

class Parsers {

  static Ref<I, A> refEmpty<I, A>() {
    return Ref(null);
  }

  static Ref<I, A> ref<I, A>(Parser<I, A> p) {
    return Ref(p);
  }

//  Ref<I, B> then<I, B>(Parser<I, B> p) {
//    return Combinators.then(this, p);
//  }


}
