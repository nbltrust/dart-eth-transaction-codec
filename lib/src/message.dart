library ethereum_codec.message;

import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:ethereum_util/ethereum_util.dart';

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
    return keccak("$MESSAGE_PREFIX${decoded.length.toString()}$decoded");
  }
}
