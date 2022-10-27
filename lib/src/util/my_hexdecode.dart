import 'dart:typed_data';

import 'package:convert/convert.dart' show hex;

Uint8List my_hexdecode(String hexStr) {
  return Uint8List.fromList(hex.decode((hexStr.length.isOdd ? '0' : '') + hexStr));
}