import 'dart:io';

import 'package:at_persistence_secondary_server/at_persistence_secondary_server.dart';
import 'package:at_persistence_secondary_server/src/keystore/secondary_persistence_store_factory.dart';
import 'package:at_persistence_secondary_server/src/model/at_data.dart';

void main() async {
  var secondaryPersistenceStore = SecondaryPersistenceStoreFactory.getInstance()
      .getSecondaryPersistenceStore('@test_user_1')!;
  var manager = secondaryPersistenceStore.getHivePersistenceManager()!;
  await manager.init('test/hive');
  manager.scheduleKeyExpireTask(1);

  var keyStoreManager =
      secondaryPersistenceStore.getSecondaryKeyStoreManager()!;
  var keyStore = secondaryPersistenceStore.getSecondaryKeyStore()!;
  var commitLogKeyStore = CommitLogKeyStore('@test_user_1');
  await commitLogKeyStore.init('test/hive/commit');
  keyStore.commitLog = AtCommitLog(commitLogKeyStore);
  keyStoreManager.keyStore = keyStore;
  var atData = AtData();
  atData.data = 'abc';
  await keyStoreManager
      .getKeyStore()
      .put('123', atData, time_to_live: 30 * 1000);
  print('end');
  var at_data = await keyStoreManager.getKeyStore().get('123');
  print(at_data?.data);
  assert(at_data?.data == 'abc');
  var expiredKey =
      await Future.delayed(Duration(minutes: 2), () => getKey(keyStoreManager));
  assert(expiredKey == null);
  print(expiredKey);
  exit(0);
}

Future<String?> getKey(keyStoreManager) async {
  AtData? at_data = await keyStoreManager.getKeyStore().get('123');
  return at_data?.data;
}
