import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/sha3.dart';

import 'util/my_hexdecode.dart';
import 'util/strip0x.dart';

/// convert address to checksum address
/// 
/// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-55.md
String toChecksumAddress(String hexAddress)
{
    hexAddress = strip0x(hexAddress);

    var digest = Digest('Keccak/256').process(Uint8List.fromList(hexAddress.toLowerCase().codeUnits));
    var hexStr = hex.encode(digest);
    var checksumAddr = '';
    for(var i = 0; i < hexAddress.length; i++) {
      if(int.parse(hexStr[i], radix: 16) >= 8) {
        checksumAddr += hexAddress[i].toUpperCase();
      } else {
        checksumAddr += hexAddress[i];
      }
    }
    return '0x' + checksumAddr;
}

String publicKeyToChecksumAddress(String hexX, String hexY) {
  var plainKey = my_hexdecode(hexX) + my_hexdecode(hexY);
  var digest = Digest('Keccak/256').process(Uint8List.fromList(plainKey));
  var hexDigest = hex.encode(digest);
  return toChecksumAddress(hexDigest.substring(hexDigest.length - 40));
}