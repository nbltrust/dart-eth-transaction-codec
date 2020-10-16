import 'package:ethereum_codec/ethereum_codec.dart';

void main() {
  var addr = EthereumAddressHash.fromHex('fb6916095ca1df60bb79ce92ce3ea74c37c5d359');
  print(addr.toChecksumAddress());
}
