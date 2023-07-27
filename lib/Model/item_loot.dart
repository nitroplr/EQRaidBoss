class ItemLoot {
  DateTime time;
  String looter;
  int quantity;
  String itemGiven;
  String? itemLooted;
  String? droppedBy;
  String id;

  ItemLoot(
      {required this.time,
      required this.looter,
      required this.quantity,
      required this.itemLooted,
      required this.droppedBy,required this.id, required this.itemGiven});
}