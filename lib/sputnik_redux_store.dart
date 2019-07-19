library sputnik_redux_store;

export 'package:sputnik_redux_store/actions/account_state_actions.dart';
export 'package:sputnik_redux_store/actions/app_state_actions.dart';
export 'package:sputnik_redux_store/actions/sputnik_action.dart';


import 'package:sputnik_app_state/sputnik_app_state.dart';
import 'package:redux/redux.dart';
import 'reducer/account_state_reducer.dart';
import 'reducer/app_state_reducer.dart';

class SputnikReduxStore extends Store<SputnikAppState> {
  SputnikReduxStore(
    SputnikAppState initialState, {
    List<Middleware<SputnikAppState>> middleware = const [],
  }) : super(
            combineReducers([
              AppStateReducer.reduce,
              AccountStateReducer.reduce,
            ]),
            middleware: middleware,
            initialState: initialState);
}
