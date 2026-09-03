#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Client-side: receives the server's jna_dataList and assigns it to the
 * real global (not a namespaced copy) - see fnc_serverSyncDataList.sqf's
 * header for why. Runs whatever callback was pending (fnc_requestDataListSync.sqf)
 * now that the data has actually arrived, and refreshes the transfer dialog
 * if it happens to be open.
 *
 * Arguments:
 * 0: jna_dataList snapshot <ARRAY>
 *
 * Return Value:
 * None
 */

params [["_snapshot", [], [[]]]];

jna_dataList = _snapshot;

private _callback = missionNamespace getVariable [QGVAR(pendingSyncCallback), {}];
GVAR(pendingSyncCallback) = {};
call _callback;

if (!isNull (findDisplay IDD_TRANSFER)) then {
    ["fill"] call FUNC(transferDialog);
};
