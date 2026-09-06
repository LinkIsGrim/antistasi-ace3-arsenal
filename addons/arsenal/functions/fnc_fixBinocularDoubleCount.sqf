#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Ultimate/TEH only: corrects jn_fnc_arsenal_cargoToArray's own player-mode
 * result, which double-counts the equipped binocular by exactly 1.
 *
 * Root cause, confirmed against actual release tags: its player branch
 * tallies (items unit) + (assignedItems player) for miscellaneous items,
 * then separately walks weaponsItems (primary/secondary/handgun/binocular)
 * for weapons. assignedItems player is the bare/legacy call form, which
 * defaults to including the binocular (BIS wiki's alternate-syntax doc:
 * the bare form matches [unit, false, true] - includeBinocs true) - so the
 * equipped binocular gets tallied once there AND once via weaponsItems'
 * own dedicated walk of that slot. Confirmed reproducible in-game
 * (Rangefinder: 20 in stock, equip it, count reads 18 - a tab switch,
 * which forces a fresh diff against the correct post-charge state, then
 * shows 18 again, ruling out a display-only issue).
 *
 * This is jn_fnc_arsenal_cargoToArray's own logic, not something this addon
 * can edit at the source - fixed here instead, after the fact, scoped to
 * exactly the one entry the bug can touch (binocular _unit's own classname,
 * matched exactly - not baseClass-normalized, since this corrects a known
 * exact overcount, not general variant handling). Deliberately not applied
 * to jn_fnc_arsenal_cargoToArray's container/vehicle-cargo path at all
 * (that path never calls assignedItems/weaponsItems the way the player
 * path does, so it was never affected) - depositing a loot crate with
 * multiple real binoculars in it is untouched by this, and a player
 * legitimately holding one equipped plus more in cargo still gets those
 * cargo-stored ones counted correctly, since this only ever removes the
 * one known-phantom copy of whatever's actually equipped right now.
 *
 * Arguments:
 * 0: jn_fnc_arsenal_cargoToArray's own result <ARRAY>
 * 1: Unit <OBJECT>
 *
 * Return Value:
 * Corrected array (same array, mutated and returned) <ARRAY>
 *
 * Example:
 * [_result, player] call FUNC(fixBinocularDoubleCount)
 */

params [["_result", [], [[]]], ["_unit", objNull, [objNull]]];

private _bino = binocular _unit;
if (_bino == "") exitWith {_result};

private _tabEntries = _result select JNA_TAB_BINOCULARS;
private _entry = _tabEntries findIf {(_x select 0) == _bino};
if (_entry < 0) exitWith {_result};

private _amount = (_tabEntries select _entry select 1) - 1;
if (_amount <= 0) then {
    _tabEntries deleteAt _entry;
} else {
    (_tabEntries select _entry) set [1, _amount];
};

_result
