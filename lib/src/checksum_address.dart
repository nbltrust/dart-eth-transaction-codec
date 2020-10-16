import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:pointycastle/digests/sha3.dart';

String toChecksumAddress(String hexAddress)
{
    if(hexAddress.startsWith('0x'))
      hexAddress = hexAddress.substring(2);

    var digest = SHA3Digest(256, true).process(Uint8List.fromList(hexAddress.toLowerCase().codeUnits));
    var hexStr = hex.encode(digest);
    var checksumAddr = '';
    for(var i = 0; i < hexAddress.length; i++) {
      if(int.parse(hexStr[i], radix: 16) >= 8) {
        checksumAddr +=  hexAddress[i].toUpperCase();
      } else {
        checksumAddr += hexAddress[i];
      }
    }
    return checksumAddr;
}