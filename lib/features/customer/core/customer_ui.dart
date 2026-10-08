// One import for every customer screen: shared UI kit (admin/core) plus
// ProviderConfig/fmtHm/capitalize from the provider module.
import 'package:flutter/foundation.dart';

export '../../provider/core/provider_ui.dart';

/// What the Search tab should show when it opens (set from Home etc.).
class SearchIntent {
  const SearchIntent({this.query = '', this.category, this.availableToday = false, this.emergency = false, this.token = 0});
  final String query;
  final String? category;
  final bool availableToday, emergency;
  final int token;
}

/// Tiny cross-screen navigation bus so any pushed screen can jump to a tab.
class CustomerNav {
  CustomerNav._();
  static final ValueNotifier<int> tab = ValueNotifier<int>(0);
  static final ValueNotifier<SearchIntent> search = ValueNotifier<SearchIntent>(const SearchIntent());
  static int _token = 0;

  static void goSearch({String query = '', String? category, bool availableToday = false, bool emergency = false}) {
    search.value = SearchIntent(
        query: query, category: category, availableToday: availableToday, emergency: emergency, token: ++_token);
    tab.value = 1;
  }

  static void goTab(int i) => tab.value = i;
}
