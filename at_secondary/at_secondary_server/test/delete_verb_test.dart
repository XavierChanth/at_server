import 'package:at_commons/at_commons.dart';
import 'package:at_secondary/src/utils/handler_util.dart';
import 'package:at_secondary/src/utils/secondary_util.dart';
import 'package:at_secondary/src/verb/handler/delete_verb_handler.dart';
import 'package:at_server_spec/at_verb_spec.dart';
import 'package:test/test.dart';

void main() {
  group('A group of delete verb tests', () {
    test('test delete key-value', () {
      var verb = Delete();
      var command = 'delete:@bob:email@colin';
      var regex = verb.syntax();
      var paramsMap = getVerbParam(regex, command);
      expect(paramsMap[AT_KEY], 'email');
      expect(paramsMap[FOR_AT_SIGN], 'bob');
      expect(paramsMap[AT_SIGN], 'colin');
    });

    test('test delete getVerb', () {
      var handler = DeleteVerbHandler(null);
      var verb = handler.getVerb();
      expect(verb is Delete, true);
    });

    test('test delete command accept test', () {
      var command = 'delete:@bob:email@colin';
      var handler = DeleteVerbHandler(null);
      var result = handler.accept(command);
      print('result : $result');
      expect(result, true);
    });

    test('test delete command command with upper case and spaces', () {
      var command = 'DEL ETE:@bob:email@colin';
      command = SecondaryUtil.convertCommand(command);
      var handler = DeleteVerbHandler(null);
      var result = handler.accept(command);
      print('result : $result');
      expect(result, true);
    });

    test('test delete key-invalid keyword', () {
      var verb = Delete();
      var command = 'delet';
      var regex = verb.syntax();
      expect(
              () => getVerbParam(regex, command),
          throwsA(predicate((e) =>
          e is InvalidSyntaxException && e.message == 'Syntax Exception')));
    });

    test('test delete key-with emoji', () {
      var verb = Delete();
      var command = 'delete:@🦄:phone@🎠';
      var regex = verb.syntax();
      var paramsMap = getVerbParam(regex, command);
      expect(paramsMap[AT_KEY], 'phone');
      expect(paramsMap[FOR_AT_SIGN], '🦄');
      expect(paramsMap[AT_SIGN], '🎠');
    });

    test('test delete key-with public and emoji', () {
      var verb = Delete();
      var command = 'delete:public:phone@🎠';
      var regex = verb.syntax();
      var paramsMap = getVerbParam(regex, command);
      expect(paramsMap[AT_KEY], 'phone');
      expect(paramsMap[AT_SIGN], '🎠');
    });

    test('test delete key-with public and emoji', () {
      var verb = Delete();
      var command = 'delete:phone@🎠';
      var regex = verb.syntax();
      var paramsMap = getVerbParam(regex, command);
      expect(paramsMap[AT_KEY], 'phone');
      expect(paramsMap[AT_SIGN], '🎠');
    });
  });
}
