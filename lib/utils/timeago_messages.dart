import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago_flutter/timeago_flutter.dart';

class TimeagoMessages {
  static final _messageMap = {
    'en': timeago.EnMessages(),
    'en_short': timeago.EnShortMessages(),
    'ar': timeago.ArMessages(),
    'ar_short': timeago.ArShortMessages(),
    'fr': timeago.FrMessages(),
    'fr_short': timeago.FrShortMessages(),
    'hi': timeago.HiMessages(),
    'hi_short': timeago.HiShortMessages(),
    'pt': timeago.PtBrMessages(),
    'pt_short': timeago.PtBrShortMessages(),
    'es': timeago.EsMessages(),
    'es_short': timeago.EsShortMessages(),
    'tr': timeago.TrMessages(),
    'tr_short': timeago.TrShortMessages(),
  };

  static LookupMessages getMessages(String languageCode) =>
      _messageMap[languageCode.toLowerCase()] ?? timeago.EnMessages();
}
