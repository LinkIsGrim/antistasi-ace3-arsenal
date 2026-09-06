#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Client-side: requests a fresh jna_dataList from the server and runs the
 * given callback once it arrives (fnc_dataListResult.sqf). Every path that
 * needs a current jna_dataList client-side goes through this rather than
 * assuming it's already populated.
 *
 * Known gap: a second call before the first's reply arrives overwrites the
 * pending callback, silently dropping the first. Acceptable for now since
 * these are short, user-initiated one-off actions, not a hot path - not
 * worth a request queue for that likelihood.
 *
 * Temporary: logs _this/typeName _this before params runs - a field report
 * hit "Error Params: Type String, expected code" on the params line below,
 * with no fuller callstack in the RPT to identify the caller. Every actual
 * call site in this addon passes either nothing or [{code}], neither of
 * which should produce this - logging the raw value here to catch it
 * concretely next time instead of guessing further. Strip once resolved.
 *
 * Arguments:
 * 0: Callback to run once jna_dataList is fresh <CODE> (default: {})
 *
 * Return Value:
 * None
 *
 * Example:
 * [{hint "synced"}] call FUNC(requestDataListSync)
 */

diag_log text format ["[skuaa3aa_arsenal][DIAG] requestDataListSync: _this=%1 typeName=%2", _this, typeName _this];

params [["_callback", {}, [{}]]];

GVAR(pendingSyncCallback) = _callback;
[QGVAR(dataListRequest), [player]] call CBA_fnc_serverEvent;
