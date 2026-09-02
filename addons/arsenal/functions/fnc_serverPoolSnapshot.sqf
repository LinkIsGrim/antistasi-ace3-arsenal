#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Server-side: builds a [tab, class, count] snapshot of jna_dataList for the
 * transfer dialog's pool list and replies to the requesting unit. Excludes
 * the same tabs fnc_poolFlat.sqf does (faces/voices/insignia aren't
 * arsenal-manageable, CARGOMAG is a duplicate of CARGOMAGALL, CARGOBULLET
 * has no transferable representation - see script_component.hpp).
 *
 * Arguments:
 * 0: Requesting unit <OBJECT>
 *
 * Return Value:
 * None
 */

if (!isServer) exitWith {};

params [["_unit", objNull, [objNull]]];
if (isNull _unit) exitWith {};

private _skipTabs = [JNA_TAB_FACE, JNA_TAB_VOICE, JNA_TAB_INSIGNIA, JNA_TAB_CARGOMAG, JNA_TAB_CARGOBULLET];
private _snapshot = [];

if (!isNil "jna_dataList") then {
    {
        private _tab = _forEachIndex;
        if (_tab in _skipTabs) then {continue};

        {
            _x params [["_class", "", [""]], ["_count", 0, [0]]];
            if (_class == "" || {_count == 0}) then {continue};
            _snapshot pushBack [_tab, _class, _count];
        } forEach _x;
    } forEach jna_dataList;
};

[QGVAR(poolSnapshotResult), [_snapshot], _unit] call CBA_fnc_targetEvent;
