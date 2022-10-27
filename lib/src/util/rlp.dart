

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';

Uint8List encode(dynamic input) {
  if (input is List && !(input is Uint8List)) {
    final output = <Uint8List>[];
    for (var data in input) {
      output.add(encode(data));
    }

    final data = _concat(output);
    return _concat([encodeLength(data.length, 192), data]);
  } else {
    final data = _toBuffer(input);

    if (data.length == 1 && data[0] < 128) {
      return data;
    } else {
      return _concat([encodeLength(data.length, 128), data]);
    }
  }
}

Uint8List encodeLength(int length, int offset) {
  if (length < 56) {
    return Uint8List.fromList([length + offset]);
  } else {
    final hexLen = _intToHex(length);
    final lLength = hexLen.length ~/ 2;

    return _concat([
      Uint8List.fromList([offset + 55 + lLength]),
      Uint8List.fromList(hex.decode(hexLen))
    ]);
  }
}

int safeParseInt(String v, [int? base]) {
  if (v.startsWith('00')) {
    throw FormatException('invalid RLP: extra zeros');
  }

  return int.parse(v, radix: base);
}

class Decoded {
  dynamic data;
  Uint8List remainder;
  Decoded(this.data, this.remainder);
}

dynamic decode(Uint8List? input, [bool stream = false]) {
  if (input == null || input.length == 0) {
    return <dynamic>[];
  }

  Uint8List inputBuffer = _toBuffer(input);
  Decoded decoded = _decode(inputBuffer);

  if (stream) {
    return decoded;
  }
  if (decoded.remainder.length != 0) {
    throw FormatException('invalid remainder');
  }

  return decoded.data;
}

Decoded _decode(Uint8List input) {
  int firstByte = input[0];
  if (firstByte <= 0x7f) {
    // a single byte whose value is in the [0x00, 0x7f] range, that byte is its own RLP encoding.
    return Decoded(input.sublist(0, 1), input.sublist(1));
  } else if (firstByte <= 0xb7) {
    // string is 0-55 bytes long. A single byte with value 0x80 plus the length of the string followed by the string
    // The range of the first byte is [0x80, 0xb7]
    int length = firstByte - 0x7f;

    // set 0x80 null to 0
    Uint8List data =
    firstByte == 0x80 ? Uint8List(0) : input.sublist(1, length);

    if (length == 2 && data[0] < 0x80) {
      throw FormatException('invalid rlp encoding: byte must be less 0x80');
    }

    return Decoded(data, input.sublist(length));
  } else if (firstByte <= 0xbf) {
    int llength = firstByte - 0xb6;
    int length = safeParseInt(hex.encode(input.sublist(1, llength)), 16);
    Uint8List data = input.sublist(llength, length + llength);
    if (data.length < length) {
      throw FormatException('invalid RLP');
    }

    return Decoded(data, input.sublist(length + llength));
  } else if (firstByte <= 0xf7) {
    // a list between  0-55 bytes long
    List<dynamic> decoded = <dynamic>[];
    int length = firstByte - 0xbf;
    Uint8List innerRemainder = input.sublist(1, length);
    while (innerRemainder.length > 0) {
      Decoded d = _decode(innerRemainder);
      decoded.add(d.data);
      innerRemainder = d.remainder;
    }

    return Decoded(decoded, input.sublist(length));
  } else {
    // a list  over 55 bytes long
    List<dynamic> decoded = <dynamic>[];
    int llength = firstByte - 0xf6;
    int length = safeParseInt(hex.encode(input.sublist(1, llength)), 16);
    int totalLength = llength + length;
    if (totalLength > input.length) {
      throw FormatException(
          'invalid rlp: total length is larger than the data');
    }

    Uint8List innerRemainder = input.sublist(llength, totalLength);
    if (innerRemainder.length == 0) {
      throw FormatException('invalid rlp, List has a invalid length');
    }

    while (innerRemainder.length > 0) {
      Decoded d = _decode(innerRemainder);
      decoded.add(d.data);
      innerRemainder = d.remainder;
    }
    return Decoded(decoded, input.sublist(totalLength));
  }
}

Uint8List _concat(List<Uint8List> lists) {
  final list = <int>[];

  lists.forEach(list.addAll);

  return Uint8List.fromList(list);
}

String _intToHex(int a) {
  return hex.encode(_toBuffer(a));
}

Uint8List _toBuffer(dynamic data) {
  if (data is Uint8List) return data;

  if (data is String) {
    if (isHexString(data)) {
      return Uint8List.fromList(hex.decode(padToEven(stripHexPrefix(data))));
    } else {
      return Uint8List.fromList(utf8.encode(data));
    }
  } else if (data is int) {
    if (data == 0) return Uint8List(0);

    return Uint8List.fromList(intToBuffer(data));
  } else if (data is BigInt) {
    if (data == BigInt.zero) return Uint8List(0);

    return Uint8List.fromList(encodeBigInt(data));
  } else if (data is List<int>) {
    return Uint8List.fromList(data);
  }

  throw TypeError();
}


bool isHexPrefixed(String str) {


  return str.substring(0, 2) == '0x';
}

String stripHexPrefix(String str) {


  return isHexPrefixed(str) ? str.substring(2) : str;
}

/// Pads a [String] to have an even length
String padToEven(String value) {


  var a = "${value}";

  if (a.length % 2 == 1) {
    a = "0${a}";
  }

  return a;
}

/// Converts a [int] into a hex [String]
String intToHex(int i) {


  return "0x${i.toRadixString(16)}";
}

/// Converts an [int] to a [Uint8List]
Uint8List intToBuffer(int i) {


  return Uint8List.fromList(hex.decode(padToEven(intToHex(i).substring(2))));
}

/// Get the binary size of a string
int getBinarySize(String str) {


  return utf8.encode(str).length;
}

/// Returns TRUE if the first specified array contains all elements
/// from the second one. FALSE otherwise.
bool arrayContainsArray(List superset, List subset, {bool some: false}) {


  if (some) {
    return Set.from(superset).intersection(Set.from(subset)).length > 0;
  } else {
    return Set.from(superset).containsAll(subset);
  }
}

/// Should be called to get utf8 from it's hex representation
String toUtf8(String hexString) {


  var bufferValue = hex.decode(
      padToEven(stripHexPrefix(hexString).replaceAll(RegExp('^0+|0+\$'), '')));

  return utf8.decode(bufferValue);
}

/// Should be called to get ascii from it's hex representation
String toAscii(String hexString) {


  var start = hexString.startsWith(RegExp('^0x')) ? 2 : 0;
  return String.fromCharCodes(hex.decode(hexString.substring(start)));
}

/// Should be called to get hex representation (prefixed by 0x) of utf8 string
String fromUtf8(String stringValue) {


  var stringBuffer = utf8.encode(stringValue);

  return "0x${padToEven(hex.encode(stringBuffer)).replaceAll(RegExp('^0+|0+\$'), '')}";
}

/// Should be called to get hex representation (prefixed by 0x) of ascii string
String fromAscii(String stringValue) {


  var hexString = ''; // eslint-disable-line
  for (var i = 0; i < stringValue.length; i++) {
    // eslint-disable-line
    var code = stringValue.codeUnitAt(i);
    var n = hex.encode([code]);
    hexString += n.length < 2 ? "0${n}" : n;
  }

  return "0x${hexString}";
}

/// Is the string a hex string.
bool isHexString(String value, {int length = 0}) {


  if (!RegExp('^0x[0-9A-Fa-f]*\$').hasMatch(value)) {
    return false;
  }

  if (length > 0 && value.length != 2 + 2 * length) {
    return false;
  }

  return true;
}

final BigInt _byteMask = new BigInt.from(0xff);

BigInt decodeBigInt(List<int> bytes) {
  BigInt result = new BigInt.from(0);
  for (int i = 0; i < bytes.length; i++) {
    result += new BigInt.from(bytes[bytes.length - i - 1]) << (8 * i);
  }
  return result;
}

Uint8List encodeBigInt(BigInt input,
    {Endian endian = Endian.be, int length = 0}) {
  int byteLength = (input.bitLength + 7) >> 3;
  int reqLength = length > 0 ? length : max(1, byteLength);
  assert(byteLength <= reqLength, 'byte array longer than desired length');
  assert(reqLength > 0, 'Requested array length <= 0');

  var res = Uint8List(reqLength);
  res.fillRange(0, reqLength - byteLength, 0);

  var q = input;
  if (endian == Endian.be) {
    for (int i = 0; i < byteLength; i++) {
      res[reqLength - i - 1] = (q & _byteMask).toInt();
      q = q >> 8;
    }
    return res;
  } else {
    // FIXME: le
    throw UnimplementedError('little-endian is not supported');
  }
}

enum Endian {
  be,
  // FIXME: le
}
