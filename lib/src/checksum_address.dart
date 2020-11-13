import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:pointycastle/digests/sha3.dart';

/// convert address to checksum address
/// 
/// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-55.md
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
    return '0x' + checksumAddr;
}

String publicKeyToChecksumAddress(String hexX, String hexY) {
  var plainKey = hex.decode(hexX) + hex.decode(hexY);
  var digest = SHA3Digest(256, true).process(Uint8List.fromList(plainKey));
  var hexDigest = hex.encode(digest);
  return toChecksumAddress(hexDigest.substring(hexDigest.length - 40));
}