import 'package:built_collection/built_collection.dart';

typedef Classifier<Predicate, Item> = Predicate Function(Item);

class EventPartitionUtil {
  static Partitioned<Predicate, Item> partition<Predicate, Item>(Iterable<Item> items, Classifier<Predicate, Item> classifier) {
    final partitions = ListMultimapBuilder<Predicate, Item>();
    final others = ListBuilder<Item>();

    for (final item in items) {
      final predicate = classifier(item);
      if (predicate == null) {
        others.add(item);
      } else {
        partitions.add(predicate, item);
      }
    }

    return Partitioned<Predicate, Item>(partitions.build().asMap(), others.build().asList());
  }
}

class Partitioned<Predicate, Item> {
  final Map<Predicate, Iterable<Item>> _partitions;
  final List<Item> others;

  Iterable<Item> getPartition(Predicate predicate){
    return _partitions[predicate] ?? Iterable.empty();
  }

  Partitioned(this._partitions, this.others);
}
