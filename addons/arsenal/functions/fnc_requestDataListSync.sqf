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
 * Arguments:
 * 0: Callback to run once jna_dataList is fresh <CODE> (default: {})
 *
 * Return Value:
 * None
 *
 * Example:
 * [{hint "synced"}] call FUNC(requestDataListSync)
 */

params [["_callback", {}, [{}]]];

GVAR(pendingSyncCallback) = _callback;
[QGVAR(dataListRequest), [player]] call CBA_fnc_serverEvent;
