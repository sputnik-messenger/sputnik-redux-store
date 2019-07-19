import 'package:sputnik_app_state/sputnik_app_state.dart';
import 'package:sputnik_redux_store/actions/app_state_actions.dart';


class AppStateReducer {
  static SputnikAppState reduce(SputnikAppState state, dynamic action) {
    var newState = state;
    if (action is AddAccount) {
      newState = state.rebuild((builder) => builder..accountSummaries[action.accountSummary.userId] = action.accountSummary);
    } else if (action is RemoveAccount) {
      newState = state.rebuild((builder) => builder..accountStates.remove(action.userId)..accountSummaries.remove(action.userId));
    } else if (action is AddAccountState) {
      newState = state.rebuild((builder) => builder.accountStates[action.accountState.userId] = action.accountState);
    } else if (action is UnloadAccountState) {
      newState = state.rebuild((builder) => builder..accountStates.remove(action.userId));
    }
    return newState;
  }
}
