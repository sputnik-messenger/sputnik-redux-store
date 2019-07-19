import 'package:sputnik_app_state/sputnik_app_state.dart';

import 'sputnik_action.dart';


class AddAccount extends SputnikAction {
  final AccountSummary accountSummary;

  AddAccount(this.accountSummary);
}

class RemoveAccount extends SputnikAction {
  final String userId;

  RemoveAccount(this.userId);
}

class AddAccountState {
  final AccountState accountState;

  AddAccountState(this.accountState);
}

class UnloadAccountState {
  final String userId;

  UnloadAccountState(this.userId);
}

class OnSyncSuccess {
  final String userId;
  final String nextBatchSyncToken;

  OnSyncSuccess(this.userId, this.nextBatchSyncToken);
}
