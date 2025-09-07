class Decks {
  static const List<String> fibonacci = [
    '0', '1', '2', '3', '5', '8', '13', '21', '34', '?'
  ];
  static const List<String> tshirt = ['XS', 'S', 'M', 'L', 'XL', '?'];
  static const List<String> powersOfTwo = ['0', '1', '2', '4', '8', '16', '32', '?'];

  static List<String> resolve(String? deckType) {
    switch ((deckType ?? '').toLowerCase()) {
      case 'tshirt':
        return tshirt;
      case 'powers':
      case 'powers_of_two':
        return powersOfTwo;
      case 'fibonacci':
      default:
        return fibonacci;
    }
  }
}
