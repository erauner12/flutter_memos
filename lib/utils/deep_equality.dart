import 'package:collection/collection.dart';

/// A utility for deep comparison of collections and objects.
/// 
/// This is useful when comparing lists, maps, or other nested objects
/// where reference equality isn't sufficient.
final deepEquality = const DeepCollectionEquality();

/// A helper function to compare two lists deeply
bool deepListEquals<T>(List<T>? list1, List<T>? list2) {
  return deepEquality.equals(list1, list2);
}

/// A helper function to compare two maps deeply
bool deepMapEquals<K, V>(Map<K, V>? map1, Map<K, V>? map2) {
  return deepEquality.equals(map1, map2);
}
