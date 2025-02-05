import 'dart:async';
import 'dart:io';

import 'package:at_persistence_secondary_server/at_persistence_secondary_server.dart';
import 'package:test/test.dart';

void main() async {
  var storageDir = Directory.current.path + '/test/hive';

  group('A group of commit log test', () {
    setUp(() async => await setUpFunc(storageDir));
    test('test single insert', () async {
      var commitLogInstance =
          await (AtCommitLogManagerImpl.getInstance().getCommitLog('@alice'));
      var hiveKey =
          await commitLogInstance!.commit('location@alice', CommitOp.UPDATE);
      var committedEntry = await (commitLogInstance.getEntry(hiveKey));
      expect(committedEntry?.key, hiveKey);
      expect(committedEntry?.atKey, 'location@alice');
      expect(committedEntry?.operation, CommitOp.UPDATE);
      commitLogInstance = null;
    });
    test('test multiple insert', () async {
      var commitLogInstance =
          await (AtCommitLogManagerImpl.getInstance().getCommitLog('@alice'));
      await commitLogInstance?.commit('location@alice', CommitOp.UPDATE);
      var key_2 =
          await commitLogInstance?.commit('location@alice', CommitOp.UPDATE);

      await commitLogInstance?.commit('location@alice', CommitOp.DELETE);
      expect(commitLogInstance?.lastCommittedSequenceNumber(), 2);
      var committedEntry = await (commitLogInstance?.getEntry(key_2));
      expect(committedEntry?.atKey, 'location@alice');
      expect(committedEntry?.operation, CommitOp.UPDATE);
    });

    test('test get entry ', () async {
      var commitLogInstance =
          await (AtCommitLogManagerImpl.getInstance().getCommitLog('@alice'));
      var key_1 =
          await commitLogInstance?.commit('location@alice', CommitOp.UPDATE);
      var committedEntry = await (commitLogInstance?.getEntry(key_1));
      expect(committedEntry?.atKey, 'location@alice');
      expect(committedEntry?.operation, CommitOp.UPDATE);
      expect(committedEntry?.opTime, isNotNull);
      expect(committedEntry?.commitId, isNotNull);
    });

    test('test entries since commit Id', () async {
      var commitLogInstance =
          await (AtCommitLogManagerImpl.getInstance().getCommitLog('@alice'));

      await commitLogInstance?.commit('location@alice', CommitOp.UPDATE);
      var key_2 =
          await commitLogInstance!.commit('location@alice', CommitOp.UPDATE);
      var key_3 =
          await commitLogInstance.commit('location@alice', CommitOp.DELETE);
      var key_4 = await commitLogInstance.commit('phone@bob', CommitOp.UPDATE);
      var key_5 =
          await commitLogInstance.commit('email@charlie', CommitOp.UPDATE);
      expect(commitLogInstance.lastCommittedSequenceNumber(), 4);
      var changes = await commitLogInstance.getChanges(key_2, '');
      expect(changes.length, 3);
      expect(changes[0].atKey, 'location@alice');
      expect(changes[1].atKey, 'phone@bob');
      expect(changes[2].atKey, 'email@charlie');
    });

    test('test last sequence number called once', () async {
      var commitLogInstance =
          await (AtCommitLogManagerImpl.getInstance().getCommitLog('@alice'));

      await commitLogInstance?.commit('location@alice', CommitOp.UPDATE);

      await commitLogInstance?.commit('location@alice', CommitOp.UPDATE);
      expect(commitLogInstance?.lastCommittedSequenceNumber(), 1);
    });

    test('test last sequence number called multiple times', () async {
      var commitLogInstance =
          await (AtCommitLogManagerImpl.getInstance().getCommitLog('@alice'));

      await commitLogInstance?.commit('location@alice', CommitOp.UPDATE);

      await commitLogInstance?.commit('location@alice', CommitOp.UPDATE);
      expect(commitLogInstance?.lastCommittedSequenceNumber(), 1);
      expect(commitLogInstance?.lastCommittedSequenceNumber(), 1);
    });
    tearDown(() async => await tearDownFunc());
  });

  group('A group of tests to verify lastSynced commit entry', () {
    setUp(() async => await setUpFunc(storageDir, enableCommitId: false));
    test(
        'test to verify the last synced entry returns entry with highest commit id',
        () async {
      var commitLogInstance =
          await (AtCommitLogManagerImpl.getInstance().getCommitLog('@alice'));

      await commitLogInstance?.commit('location@alice', CommitOp.UPDATE);
      await commitLogInstance?.commit('mobile@alice', CommitOp.UPDATE);
      await commitLogInstance?.commit('phone@alice', CommitOp.UPDATE);

      CommitEntry? commitEntry0 = await commitLogInstance?.getEntry(0);
      await commitLogInstance?.update(commitEntry0!, 1);
      CommitEntry? commitEntry1 = await commitLogInstance?.getEntry(1);
      await commitLogInstance?.update(commitEntry1!, 0);
      var lastSyncedEntry = await commitLogInstance?.lastSyncedEntry();
      expect(lastSyncedEntry!.commitId, 1);
      var lastSyncedCacheSize = commitLogInstance!.commitLogKeyStore
          .getLastSyncedEntryCacheMapValues()
          .length;
      expect(lastSyncedCacheSize, 1);
    });

    test('test to verify the last synced entry with regex', () async {
      var commitLogInstance =
          await (AtCommitLogManagerImpl.getInstance().getCommitLog('@alice'));

      await commitLogInstance?.commit('location.buzz@alice', CommitOp.UPDATE);
      await commitLogInstance?.commit('mobile.wavi@alice', CommitOp.UPDATE);
      await commitLogInstance?.commit('phone.buzz@alice', CommitOp.UPDATE);

      CommitEntry? commitEntry0 = await commitLogInstance?.getEntry(0);
      await commitLogInstance?.update(commitEntry0!, 2);
      CommitEntry? commitEntry1 = await commitLogInstance?.getEntry(1);
      await commitLogInstance?.update(commitEntry1!, 1);
      CommitEntry? commitEntry2 = await commitLogInstance?.getEntry(2);
      await commitLogInstance?.update(commitEntry2!, 0);
      var lastSyncedEntry =
          await commitLogInstance?.lastSyncedEntryWithRegex('buzz');
      expect(lastSyncedEntry!.atKey!, 'location.buzz@alice');
      expect(lastSyncedEntry.commitId!, 2);
      lastSyncedEntry =
          await commitLogInstance?.lastSyncedEntryWithRegex('wavi');
      expect(lastSyncedEntry!.atKey!, 'mobile.wavi@alice');
      expect(lastSyncedEntry.commitId!, 1);
      var lastSyncedEntriesList = commitLogInstance!.commitLogKeyStore
          .getLastSyncedEntryCacheMapValues();
      expect(lastSyncedEntriesList.length, 2);
    });
    tearDown(() async => await tearDownFunc());
  });

  group('A group of commit log compaction tests', () {
    setUp(() async => await setUpFunc(storageDir));
    test('Test to verify compaction when single is modified ten times',
        () async {
      var commitLogInstance =
          await (AtCommitLogManagerImpl.getInstance().getCommitLog('@alice'));
      var compactionService =
          CommitLogCompactionService(commitLogInstance!.commitLogKeyStore);
      commitLogInstance.addEventListener(compactionService);
      for (int i = 0; i <= 50; i++) {
        await commitLogInstance.commit('location@alice', CommitOp.UPDATE);
      }

      var list = compactionService.getEntries('location@alice');
      expect(list?.getSize(), 1);
    });

    test('Test to verify compaction when two are modified ten times', () async {
      var commitLogInstance =
          await (AtCommitLogManagerImpl.getInstance().getCommitLog('@alice'));
      var compactionService =
          CommitLogCompactionService(commitLogInstance!.commitLogKeyStore);
      commitLogInstance.addEventListener(compactionService);
      for (int i = 0; i <= 50; i++) {
        await commitLogInstance.commit('location@alice', CommitOp.UPDATE);
        await commitLogInstance.commit('country@alice', CommitOp.UPDATE);
      }
      var locationList = compactionService.getEntries('location@alice');
      var countryList = compactionService.getEntries('country@alice');
      expect(locationList!.getSize(), 1);
      expect(countryList!.getSize(), 1);
    });
    tearDown(() async => await tearDownFunc());
  });
}

Future<SecondaryKeyStoreManager> setUpFunc(storageDir,
    {bool enableCommitId = true}) async {
  var commitLogInstance = await AtCommitLogManagerImpl.getInstance()
      .getCommitLog('@alice',
          commitLogPath: storageDir, enableCommitId: enableCommitId);
  var secondaryPersistenceStore = SecondaryPersistenceStoreFactory.getInstance()
      .getSecondaryPersistenceStore('@alice')!;
  var persistenceManager =
      secondaryPersistenceStore.getHivePersistenceManager()!;
  await persistenceManager.init(storageDir);
//  persistenceManager.scheduleKeyExpireTask(1); //commented this line for coverage test
  var hiveKeyStore = secondaryPersistenceStore.getSecondaryKeyStore()!;
  hiveKeyStore.commitLog = commitLogInstance;
  var keyStoreManager =
      secondaryPersistenceStore.getSecondaryKeyStoreManager()!;
  keyStoreManager.keyStore = hiveKeyStore;
  return keyStoreManager;
}

Future<void> tearDownFunc() async {
  await AtCommitLogManagerImpl.getInstance().close();
  var isExists = await Directory('test/hive/').exists();
  if (isExists) {
    Directory('test/hive').deleteSync(recursive: true);
  }
}
