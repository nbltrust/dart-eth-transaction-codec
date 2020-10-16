import 'dart:convert';
import 'dart:io';

Map<String, dynamic> contractAbiToJson(String dirname) {
  Map<String, dynamic> result = new Map();
  List<dynamic> abis = new List();

  var symbol_file = new File('${dirname}/contract_symbols.json');
  var symbols = symbol_file.readAsStringSync();
  result['contracts'] = jsonDecode(symbols);

  (result['contracts'] as List)
  .map((i) => i['type'])
  .toSet()
  .toList()
  .forEach((element) {
    var abi_file = new File('${dirname}/abi/${element}.json');
    abis.add({'type': element, 'abi': jsonDecode(abi_file.readAsStringSync())});
  });
  result['abis'] = abis;
  return result;
}