import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatChannelProvider = NotifierProvider<_ShowAuctionStatsNotifier, String>(_ShowAuctionStatsNotifier.new);

class _ShowAuctionStatsNotifier extends Notifier<String> {
  @override
  String build() {
    return '';
  }

  void setChatChannel({required String channel}) {
    Future.delayed(Duration.zero).then((val) => state = channel);
  }
}
