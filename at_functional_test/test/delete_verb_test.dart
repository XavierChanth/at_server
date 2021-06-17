import 'package:test/test.dart';

import 'commons.dart';
import 'package:at_functional_test/conf/config_util.dart';
import 'dart:io';

void main() {
  var first_atsign = '@high8289';
  var second_atsign = '@92official22';

  Socket _socket_second_atsign;
  Socket _socket_first_atsign;

  //Establish the client socket connection
  setUp(() async {
    var high8289_server =  ConfigUtil.getYaml()['high8289_server']['high8289_url'];
    var high8289_port =  ConfigUtil.getYaml()['high8289_server']['high8289_port'];

    var official22_server =  ConfigUtil.getYaml()['92official22_server']['92official22_url'];
    var official22_port =  ConfigUtil.getYaml()['92official22_server']['92official22_port'];
    
    //  var root_server = ConfigUtil.getYaml()['root_server']['url'];
    _socket_first_atsign =
        await secure_socket_connection(high8289_server, high8289_port);
    socket_listener(_socket_first_atsign);
    await prepare(_socket_first_atsign, first_atsign);

    //Socket connection for alice atsign
    _socket_second_atsign =
    await secure_socket_connection(official22_server, official22_port);
    socket_listener(_socket_second_atsign);
    await prepare(_socket_second_atsign, second_atsign);
  });

  test('Delete verb for public key', () async {
    ///UPDATE VERB
    await socket_writer(_socket_first_atsign, 'update:public:location$first_atsign Bengaluru');
    var response = await read();
    print('update verb response : $response');
    assert((!response.contains('Invalid syntax')) && (!response.contains('null')));

    ///SCAN VERB
    await socket_writer(_socket_first_atsign, 'scan');
    response = await read();
    print('scan verb response before delete : $response');
    expect(response, contains('public:location$first_atsign'));

    ///DELETE VERB
    await socket_writer(_socket_first_atsign, 'delete:public:location$first_atsign');
    response = await read();
    print('delete verb response : $response');
    assert((!response.contains('Invalid syntax')) && (!response.contains('null')));

    ///SCAN VERB
    await socket_writer(_socket_first_atsign, 'scan');
    response = await read();
    print('scan verb response after delete : $response');
    expect(response, isNot('public:location$first_atsign'));
  }, timeout: Timeout(Duration(seconds: 50)));

  test('delete verb with incorrect spelling - negative scenario', () async {
    ///Delete verb
    await socket_writer(_socket_first_atsign, 'deete:phone$first_atsign');
    var response = await read();
    print('delete verb response : $response');
    expect(response, contains('Invalid syntax'));
  });

  test('delete verb for an emoji key', () async {
    ///UPDATE VERB
    await socket_writer(_socket_first_atsign, 'update:public:🦄🦄$first_atsign 2emojis');
    var response = await read();
    print('update verb response $response');
    assert((!response.contains('Invalid syntax')) && (!response.contains('null')));

    // ///SCAN VERB
    await socket_writer(_socket_first_atsign, 'scan');
    response = await read();
    print('scan verb response is :$response');
    expect(response,contains('public:🦄🦄$first_atsign'));

    ///DELETE VERB
    await socket_writer(_socket_first_atsign, 'delete:public:🦄🦄$first_atsign');
    response = await read();
    print('delete verb response : $response');
    assert((!response.contains('Invalid syntax')) && (!response.contains('null')));

    ///SCAN VERB
    await socket_writer(_socket_first_atsign, 'scan');
    response = await read();
    print('scan verb response is :$response');
    expect(response,isNot('public:🦄🦄$first_atsign'));
  });

  test('delete verb when ccd is true', () async {
    ///UPDATE VERB
    await socket_writer(_socket_first_atsign, 'update:ttr:-1:ccd:true:$second_atsign:hobby$first_atsign photography');
    var response = await read();
    print('update verb response : $response');
    assert((!response.contains('Invalid syntax')) && (!response.contains('null')));;

    ///SCAN VERB in the first atsign
    await socket_writer(_socket_first_atsign, 'scan');
    response = await read();
    print('scan verb response before delete : $response');
    expect(response, contains('"$second_atsign:hobby$first_atsign"'));

    // ///DELETE VERB
    await socket_writer(_socket_first_atsign, 'delete:$second_atsign:hobby$first_atsign');
    response = await read();
    print('delete verb response : $response');
    assert(!response.contains('data:null'));

    // ///SCAN VERB
    await socket_writer(_socket_first_atsign, 'scan');
    response = await read();
    print('scan verb response after delete : $response');
    expect(response, isNot('"$second_atsign:hobby$first_atsign"'));
  }, timeout: Timeout(Duration(seconds: 60)));



  tearDown(() {
    //Closing the client socket connection
    clear();
    _socket_first_atsign.destroy();
  });
}
