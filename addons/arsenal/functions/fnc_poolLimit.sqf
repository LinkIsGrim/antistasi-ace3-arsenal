#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Server-side: minimum stock a non-member must leave in the pool for one
 * classname (the "guest limit" floor), mirroring the _minItemsMember helper
 * JNA's own arsenal skin uses - jna_minItemMember (set in overrides/fnc_arsenal_init.sqf)
 * as the per-tab default, overridden per-classname by A3A_arsenalLimits when present.
 *
 * Arguments:
 * 0: Classname <STRING>
 * 1: Tab index <NUMBER>
 *
 * Return Value:
 * Minimum stock to leave behind <NUMBER>
 *
 * Example:
 * ["arifle_MX_F", JNA_TAB_PRIMARYWEAPON] call FUNC(poolLimit)
 */

if (!isServer) exitWith {0};

params [["_class", "", [""]], ["_tab", -1, [0]]];

if (_tab < 0 || {isNil "jna_minItemMember"} || {_tab >= count jna_minItemMember}) exitWith {0};

private _min = jna_minItemMember select _tab;

if (!isNil "A3A_arsenalLimits") then {
    _min = A3A_arsenalLimits getOrDefault [_class, _min];
};

_min
