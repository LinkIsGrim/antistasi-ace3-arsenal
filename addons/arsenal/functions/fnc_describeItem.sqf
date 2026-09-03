#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Computes the label/color/tooltip fnc_decorate.sqf shows for one arsenal
 * item, from Antistasi's own pool state (forbidden list, stock, member
 * limit) rather than anything ACE natively tracks - see fnc_poolFind.sqf's
 * header for why this is safe to call client-side.
 *
 * Unlimited stock uses the infinity glyph, matching how JNA's own arsenal
 * skin already shows it ("[   ∞  ]" in fn_arsenal.sqf/fn_arsenal_loadoutArsenal.sqf)
 * rather than inventing our own convention.
 *
 * Arguments:
 * 0: Classname <STRING>
 *
 * Return Value:
 * [label, color, tooltip] <ARRAY>
 *
 * Example:
 * ["arifle_MX_F"] call FUNC(describeItem)
 */

params [["_class", "", [""]]];

if (_class == "") exitWith {["", ARSENAL_COLOR_DEFAULT, ""]};

if (_class call FUNC(isForbidden)) exitWith {
    ["banned", ARSENAL_COLOR_FORBIDDEN, "Off-limits."]
};

(_class call FUNC(poolFind)) params ["_tab", "_stock", ""];

if (_tab < 0) exitWith {["?", ARSENAL_COLOR_DEFAULT, "Not tracked by the arsenal pool."]};

if (_stock == -1) exitWith {["∞", ARSENAL_COLOR_UNLIMITED, "Unlimited stock."]};

private _limit = [_class, _tab] call FUNC(poolLimit);
private _color = if (_stock <= _limit) then {ARSENAL_COLOR_LIMITED} else {ARSENAL_COLOR_DEFAULT};

private _tooltip = format ["%1 in stock.", _stock];
if (_stock <= _limit) then {
    _tooltip = _tooltip + format [" Members-only below %1.", _limit];
};

[str _stock, _color, _tooltip]
