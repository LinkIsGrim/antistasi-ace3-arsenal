#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Wired to the CBA ace_arsenal_cargoChanged event (registered once in
 * XEH_postInit.sqf, not per-open). Fires once per item taken/returned in
 * an open ACE Arsenal - translates that into a jna_dataList pool delta.
 *
 * Ignores the event entirely unless GVAR(activeBox) is set, i.e. the
 * currently open arsenal is one of ours (openPlayer/openContainer) and not
 * some unrelated ace_arsenal_fnc_initBox placed elsewhere in the mission.
 *
 * Arguments:
 * 0: Arsenal display <DISPLAY>
 * 1: Item classname <STRING>
 * 2: Added (true) or removed (false) <BOOL>
 * 3: Shift-click (5x) was held <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, "arifle_MX_F", true, false] call FUNC(reconcileCargoChanged)
 */

params ["_display", "_item", "_added", "_shiftState"];

if (isNil QGVAR(activeBox) || {isNull GVAR(activeBox)}) exitWith {};

// Taking an item out of the arsenal withdraws it from the pool (negative delta);
// putting one back returns it (positive delta) - opposite of "added to cargo".
private _delta = ([1, 5] select _shiftState) * ([1, -1] select _added);

[_item, _delta] remoteExec [QFUNC(serverAdjustPool), 2];
