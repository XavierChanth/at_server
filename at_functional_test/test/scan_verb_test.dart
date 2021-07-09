import 'dart:io';

import 'package:at_functional_test/conf/config_util.dart';
import 'package:test/test.dart';

import 'commons.dart';

void main() {
  var first_atsign =
      ConfigUtil.getYaml()['first_atsign_server']['first_atsign_name'];
  var second_atsign =
      ConfigUtil.getYaml()['second_atsign_server']['second_atsign_name'];

  Socket _socket_first_atsign;
  Socket _socket_second_atsign;

  //Establish the client socket connection
  var first_atsign_server =
      ConfigUtil.getYaml()['first_atsign_server']['first_atsign_url'];
  var first_atsign_port =
      ConfigUtil.getYaml()['first_atsign_server']['first_atsign_port'];

  var second_atsign_server =
      ConfigUtil.getYaml()['second_atsign_server']['second_atsign_url'];
  var second_atsign_port =
      ConfigUtil.getYaml()['second_atsign_server']['second_atsign_port'];

  // socket connection for first atsign

  //Socket connection for second atsign

  test('Scan verb after authentication', () async {
    _socket_first_atsign =
        await secure_socket_connection(first_atsign_server, first_atsign_port);
    socket_listener(_socket_first_atsign);
    await prepare(_socket_first_atsign, first_atsign);

    ///UPDATE VERB
    await socket_writer(
        _socket_first_atsign, 'update:public:location$first_atsign California');
    var response = await read();
    assert(
        (!response.contains('Invalid syntax')) && (!response.contains('null')));

    ///SCAN VERB
    await socket_writer(_socket_first_atsign, 'scan');
    response = await read();
    print('scan verb response : $response');
    expect(response, contains('"public:location$first_atsign"'));
  }, timeout: Timeout(Duration(seconds: 120)));

  test('scan verb before authentication', () async {
    _socket_first_atsign =
        await secure_socket_connection(first_atsign_server, first_atsign_port);
    socket_listener(_socket_first_atsign);
    await prepare(_socket_first_atsign, first_atsign);

    ///SCAN VERB
    await socket_writer(_socket_first_atsign, 'scan');
    var response = await read();
    print('scan verb response : $response');
    expect(response, contains('"public:location$first_atsign"'));
  }, timeout: Timeout(Duration(seconds: 120)));

  test('Scan verb with only atsign and no value', () async {
    _socket_first_atsign =
        await secure_socket_connection(first_atsign_server, first_atsign_port);
    socket_listener(_socket_first_atsign);
    await prepare(_socket_first_atsign, first_atsign);
    ;

    ///SCAN VERB
    await socket_writer(_socket_first_atsign, 'scan@');
    var response = await read();
    print('scan verb response : $response');
    expect(response, contains('Invalid syntax'));
  }, timeout: Timeout(Duration(seconds: 120)));

  test('Scan verb with regex', () async {
    _socket_first_atsign =
        await secure_socket_connection(first_atsign_server, first_atsign_port);
    socket_listener(_socket_first_atsign);
    await prepare(_socket_first_atsign, first_atsign);

    ///UPDATE VERB
    await socket_writer(
        _socket_first_atsign, 'update:public:twitter.me$first_atsign bob_123');
    var response = await read();
    print('update verb response : $response');
    assert(
        (!response.contains('Invalid syntax')) && (!response.contains('null')));

    ///SCAN VERB
    await socket_writer(_socket_first_atsign, 'scan .me');
    response = await read();
    print('scan verb response : $response');
    expect(response, contains('"public:twitter.me$first_atsign"'));
  }, timeout: Timeout(Duration(seconds: 120)));

  test('scan verb with emoji', () async {
    _socket_first_atsign =
        await secure_socket_connection(first_atsign_server, first_atsign_port);
    socket_listener(_socket_first_atsign);
    await prepare(_socket_first_atsign, first_atsign);

    // connecting to the second atsign
    _socket_second_atsign = await secure_socket_connection(
        second_atsign_server, second_atsign_port);
    socket_listener(_socket_second_atsign);
    await prepare(_socket_second_atsign, second_atsign);

    ///UPDATE VERB
    await socket_writer(_socket_second_atsign,
        'update:ttr:-1:$first_atsign:emoticon$second_atsign 🦄🦄');
    var response = await read();
    print('update verb response : $response');
    assert(
        (!response.contains('Invalid syntax')) && (!response.contains('null')));

    ///SCAN VERB
    await socket_writer(_socket_first_atsign, 'scan:$second_atsign');
    response = await read();
    await Future.delayed(Duration(seconds: 5));
    print('scan verb response : $response');
    expect(response, contains('"emoticon$second_atsign"'));
  }, timeout: Timeout(Duration(seconds: 120)));

  tearDown(() {
    //Closing the client socket connection
    clear();
    _socket_first_atsign.destroy();
  });
}
