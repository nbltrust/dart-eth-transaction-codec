import 'package:ethereum_codec/ethereum_codec.dart';

void main() {
  var addr = EthereumAddressHash.fromHex('fb6916095ca1df60bb79ce92ce3ea74c37c5d359');
  print(addr.toChecksumAddress());

  var addr2 = publicKeyToChecksumAddress('5f37d20e5b18909361e0ead7ed17c69b417bee70746c9e9c2bcb1394d921d4ae', '612d83e3487012034792ff36357ee25f382913cfeb54a8622b7ef35d635d8740');
  print(addr2);
}
