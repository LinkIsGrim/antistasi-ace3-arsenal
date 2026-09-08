#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Server-side: sends the raw jna_dataList to a requesting client. Not
 * reshaped/reduced - the client needs the real global, in its real shape,
 * because TEH's own native functions (JN_fnc_arsenal_quickReload,
 * JN_fnc_arsenal_loadInventory, etc.) read it directly too, not just our
 * own code. Registered against QGVAR(dataListRequest) in XEH_postInit.sqf.
 *
 * Stock JNA only ever populates this client-side as a side effect of
 * jn_fnc_arsenal_requestOpen, which we never call (it also opens the real
 * BIS arsenal). This is the replacement for that side effect, without the
 * BIS-arsenal part.
 *
 * Arguments:
 * 0: Requesting unit <OBJECT>
 *
 * Return Value:
 * None
 */

if (!isServer) exitWith {};

params [["_unit", objNull, [objNull]]];

diag_log text format ["[skuaa3aa_arsenal][DIAG] serverSyncDataList: request received, unit=%1 isNull=%2 jna_dataList isNil=%3", _unit, isNull _unit, isNil "jna_dataList"];

if (isNull _unit) exitWith {};

private _snapshot = if (isNil "jna_dataList") then {[]} else {+jna_dataList};

[QGVAR(dataListResult), [_snapshot], _unit] call CBA_fnc_targetEvent;
