import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'commons.dart';
import 'package:at_functional_test/conf/config_util.dart';
import 'package:crypton/crypton.dart';

void main() {
  var signing_privateKey;
  var first_atsign =
      ConfigUtil.getYaml()['first_atsign_server']['first_atsign_name'];
  var second_atsign =
      ConfigUtil.getYaml()['second_atsign_server']['second_atsign_name'];

  Socket _socket_first_atsign;
  Socket _socket_second_atsign;

  //Establish the client socket connection
  setUp(() async {
    var first_atsign_server =
        ConfigUtil.getYaml()['first_atsign_server']['first_atsign_url'];
    var first_atsign_port =
        ConfigUtil.getYaml()['first_atsign_server']['first_atsign_port'];

    var second_atsign_server =
        ConfigUtil.getYaml()['second_atsign_server']['second_atsign_url'];
    var second_atsign_port =
        ConfigUtil.getYaml()['second_atsign_server']['second_atsign_port'];

    // socket connection for first atsign
    _socket_first_atsign =
        await secure_socket_connection(first_atsign_server, first_atsign_port);
    socket_listener(_socket_first_atsign);
    await prepare(_socket_first_atsign, first_atsign);

    //Socket connection for second atsign
    _socket_second_atsign = await secure_socket_connection(
        second_atsign_server, second_atsign_port);
    socket_listener(_socket_second_atsign);
    await prepare(_socket_second_atsign, second_atsign);
  });

  // generating digest using the signing private key
  String generateSignInDigest(String atsign, String challenge,
      {String signinKey}) {
    // send response
    signing_privateKey = signing_privateKey.trim();
    var key = RSAPrivateKey.fromString(signing_privateKey);
    challenge = challenge.trim();
    var sign = key.createSHA256Signature(utf8.encode(challenge));
    return base64Encode(sign);
  }

  test('pol verb test', () async {
    // updating some keys for alice
    await socket_writer(
        _socket_second_atsign, 'update:$first_atsign:Job$second_atsign QA');
    var response = await read();
    print('update response is : $response');
    assert(
        (!response.contains('Invalid syntax')) && (!response.contains('null')));

    // look up for signing private key
    await socket_writer(_socket_first_atsign,
        'llookup:$first_atsign:signing_privatekey$first_atsign');
    response = await read();
    print('llookup response for signing private key is $response');
    assert(
        (!response.contains('Invalid syntax')) && (!response.contains('null')));
    signing_privateKey = response.replaceAll('data:', '');
    print('signing key is $signing_privateKey');

    // authenticate to other atsign
    await socket_writer(_socket_first_atsign, 'from:$second_atsign');
    response = await read();
    print('from response containing proof is: $response');
    assert(response.contains('data:proof'));
    response.replaceAll('data:', ',');
    response.replaceAll('proof', '');
    var result = response.split(':');
    var key = result[2];
    var value = result[3];
    print('key is $key');
    print('value is $value');
    var digest_result = generateSignInDigest('$first_atsign', '$value',
        signinKey: '$signing_privateKey');

    // update publickey in the atsign's secondary
    await socket_writer(
        _socket_first_atsign, 'update:public:$key $digest_result');
    response = await read();
    print(response);

    // connecting as @second_atsign in first_atsign's secondary
    await socket_writer(_socket_second_atsign, 'pol');
    response = await read();
    print('pol response is $response');
    assert(response.contains('$first_atsign@'));
    await socket_writer(_socket_second_atsign, 'scan');
    response = await read();
    print('scan response is $response');
    assert(response.contains('"$first_atsign:job$second_atsign"'));
  });

  tearDown(() {
    //Closing the client socket connection
    clear();
    _socket_first_atsign.destroy();
    _socket_second_atsign.destroy();
  });
}
