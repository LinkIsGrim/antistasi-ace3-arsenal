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
 * are routine rather than an edge case. Doing it unconditionally means it
 * never depends on which specific callback(s) happen to be queued, and it's
 * a cheap, idempotent no-op call when nothing changed since the last one.
 *
 * Runs every queued callback (fnc_requestDataListSync.sqf's
 * GVAR(pendingSyncCallbacks) is an array, not a single slot - see that
 * file's header for why that matters), not just one - any reply carries the
 * same real, current jna_dataList regardless of which request triggered it,
 * so it's correct to satisfy everything queued so far whenever any reply
 * arrives.
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

private _pending = missionNamespace getVariable [QGVAR(pendingSyncCallbacks), []];
GVAR(pendingSyncCallbacks) = [];
{[] call _x} forEach _pending;

if (!isNull (findDisplay IDD_TRANSFER)) then {
    ["fill"] call FUNC(transferDialog);
};
