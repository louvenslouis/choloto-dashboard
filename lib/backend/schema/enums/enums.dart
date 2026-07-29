import 'package:collection/collection.dart';

enum PaimentMethod {
  moncash,
  cash,
  stripe,
}

enum Periode {
  Matin,
  Midi,
  Soir,
}

enum Predictions {
  boulFavoris,
  boloto,
  extra,
  chif3,
  chif4,
  mariages,
  ggNyFloNy,
  soutni,
}

extension FFEnumExtensions<T extends Enum> on T {
  String serialize() => name;
}

extension FFEnumListExtensions<T extends Enum> on Iterable<T> {
  T? deserialize(String? value) =>
      firstWhereOrNull((e) => e.serialize() == value);
}

T? deserializeEnum<T>(String? value) {
  switch (T) {
    case (PaimentMethod):
      return PaimentMethod.values.deserialize(value) as T?;
    case (Periode):
      return Periode.values.deserialize(value) as T?;
    case (Predictions):
      return Predictions.values.deserialize(value) as T?;
    default:
      return null;
  }
}
