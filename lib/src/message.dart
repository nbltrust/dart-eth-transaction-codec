library ethereum_codec.message;

import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/keccak.dart';


import 'util/strip0x.dart';

const MESSAGE_PREFIX = "\x19Ethereum Signed Message:\n";

class EthereumMessage {
  String raw;

  EthereumMessage(this.raw);

  factory EthereumMessage.fromHex(String raw) {
    return EthereumMessage(raw);
  }

  String get decoded => new String.fromCharCodes(hex.decode(strip0x(raw)));

  String toString() => this.decoded;

  Uint8List hashToSign() {
    final decoded = this.decoded;
    return Digest('Keccak/256').process(Uint8List.fromList(hex.decode("$MESSAGE_PREFIX${decoded.length.toString()}$decoded")));
  }
}
