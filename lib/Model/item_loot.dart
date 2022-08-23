class ItemLoot {
  DateTime time;
  String looter;
  String quantity;
  String item;
  String droppedBy;

  ItemLoot(
      {required this.time,
      required this.looter,
      required this.quantity,
      required this.item,
      required this.droppedBy});
}