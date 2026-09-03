#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Server-side: authoritative accept/refuse for a client's proposed pool
 * deltas (fnc_reconcile.sqf), registered against QGVAR(reconcileRequest)
 * in XEH_postInit.sqf. Replies with QGVAR(reconcileResult) targeted at the
 * unit, see fnc_reconcileResult.sqf for how the client applies it.
 *
 * A single forbidden/out-of-stock/member-limit failure on a non-magazine
 * item aborts the whole batch (client reverts its entire loadout to its own
 * last-known-good snapshot) rather than committing a partial take - matches
 * the reasoning in antistasi-ace-arsenal's fn_reconcile.sqf: a half-applied
 * loadout change is worse than losing the whole pending change. Magazine
 * failures are softer - only that magazine gets stripped, the rest commits.
 *
 * Arguments:
 * 0: Unit the proposal came from <OBJECT>
 * 1: Taken entries, [[tab, class, amount], ...] <ARRAY>
 * 2: Returned entries, [[tab, class, amount], ...] <ARRAY>
 *
 * Return Value:
 * None
 */

if (!isServer) exitWith {};

params [["_unit", objNull, [objNull]], ["_taken", [], [[]]], ["_returned", [], [[]]]];

if (isNull _unit) exitWith {};

private _isMember = _unit call A3A_fnc_isMember;
private _refusalMsg = "";
private _stripMags = [];
private _charge = [];

{
    _x params ["_tab", "_class", "_amount"];

    private _problem = "";

    if (_class call FUNC(isForbidden)) then {
        _problem = format ["%1 is off-limits.", getText (configFile >> "CfgWeapons" >> _class >> "displayName")];
    };

    private _poolTab = _tab;
    private _poolClass = _class;

    if (_problem == "") then {
        (_class call FUNC(poolFind)) params ["_foundTab", "_stock", "_foundClass"];

        switch (true) do {
            case (_foundTab < 0): {_problem = "Not enough in the arsenal.";};
            case (_stock == -1): {_poolTab = _foundTab; _poolClass = _foundClass;};
            case (_stock < _amount): {_problem = "Not enough in the arsenal.";};
            case (!_isMember && {_stock - _amount < ([_class, _foundTab] call FUNC(poolLimit))}): {
                _problem = "Only members can take that much.";
            };
            default {_poolTab = _foundTab; _poolClass = _foundClass;};
        };
    };

    if (_problem == "") exitWith {
        _charge pushBack [_poolTab, _poolClass, _amount];
    };

    if (_tab == JNA_TAB_CARGOMAGALL) then {
        _stripMags pushBackUnique _class;
    } else {
        if (_refusalMsg == "") then {_refusalMsg = _problem};
    };
} forEach _taken;

if (_refusalMsg != "") exitWith {
    [QGVAR(reconcileResult), ["revert", _refusalMsg], _unit] call CBA_fnc_targetEvent;
};

if (_stripMags isNotEqualTo []) exitWith {
    [QGVAR(reconcileResult), ["strip", _stripMags], _unit] call CBA_fnc_targetEvent;
};

{
    _x params ["_tab", "_class", "_amount"];
    [_tab, _class, _amount] call jn_fnc_arsenal_removeItem;
} forEach _charge;

{
    _x params ["_tab", "_class", "_amount"];
    [_tab, _class, _amount] call jn_fnc_arsenal_addItem;
} forEach _returned;

// Deliberately NOT piggybacking jna_dataList on this reply (tried once,
// reverted) - this event's reply is what clears GVAR(busy) client-side, and
// riding a potentially large nested array on the same critical path risked
// silently wedging reconciliation permanently if that payload ever failed
// to arrive cleanly. The client asks for a fresh jna_dataList separately
// via fnc_requestDataListSync.sqf's own dedicated, already-proven channel.
[QGVAR(reconcileResult), ["ok"], _unit] call CBA_fnc_targetEvent;
