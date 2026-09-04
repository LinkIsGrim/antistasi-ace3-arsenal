#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Client-side: receives the server's jna_dataList and assigns it to the
 * real global (not a namespaced copy) - see fnc_serverSyncDataList.sqf's
 * header for why. Runs whatever callback was pending (fnc_requestDataListSync.sqf)
 * now that the data has actually arrived, and refreshes the transfer dialog
 * if it happens to be open.
 *
 * Redecorating the arsenal display (if open) is unconditional here, not left
 * to a passed-in callback like the transfer dialog refresh below - a resync
 * can now be triggered by someone else's pool change (fnc_onPoolChanged.sqf),
 * not just the player's own actions, so overlapping requestDataListSync calls
 * are routine rather than an edge case. fnc_requestDataListSync.sqf's callback
 * slot is a single overwritable variable (documented gap in that file), so a
 * decorate-via-callback here would silently not happen whenever two resyncs
 * overlapped - jna_dataList itself would still be correct, but the displayed
 * counts wouldn't reflect it until something else happened to trigger another
 * resync. Doing it unconditionally instead means it can never be dropped, and
 * it's a cheap, idempotent no-op call when nothing changed since the last one.
 *
 * Arguments:
 * 0: jna_dataList snapshot <ARRAY>
 *
 * Return Value:
 * None
 */

params [["_snapshot", [], [[]]]];

jna_dataList = _snapshot;

private _display = findDisplay ARSENAL_IDD;
if (!isNull _display) then {_display call FUNC(decorate)};

private _callback = missionNamespace getVariable [QGVAR(pendingSyncCallback), {}];
GVAR(pendingSyncCallback) = {};
call _callback;

if (!isNull (findDisplay IDD_TRANSFER)) then {
    ["fill"] call FUNC(transferDialog);
};
