abstract class Input<I> {
  factory Input.array(List<I> symbols) {}

  static StringInput string(String symbols) {
    return StringInput(symbols, 0);
  }

  Input();

  int position();

  bool end();

  I current();

  List<I> curList(int n);

  Input<I> next(int n);

  Input<I> next0() {
    return next(1);
  }
}

class StringInput extends Input<String> {
  final String symbols;
  final int pos;

  StringInput(this.symbols, this.pos);

  @override
  List<String> curList(int n) {
    return symbols.substring(pos, pos + n).split('');
  }

  @override
  String current() {
    return pos < symbols.length ? symbols[pos] : null;
  }

  @override
  bool end() {
    return pos >= symbols.length;
  }

  @override
  Input<String> next(int n) {
    return new StringInput(symbols, pos + 1);
  }

  @override
  int position() {
    return pos;
  }

  String getCharSequence() {
    return symbols.substring(pos);
  }

  String getCharSequence1(int length) {
    return symbols.substring(pos, pos + length);
  }
}
