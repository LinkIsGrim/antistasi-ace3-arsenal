#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Flattens Antistasi's jna_dataList (per-tab [classname, count] arrays) into
 * a distinct classname list suitable for ace_arsenal_fnc_addVirtualItems.
 *
 * Uses a hashmap accumulator rather than pushBackUnique - antistasi-ace-arsenal's
 * equivalent (fn_poolFlat.sqf) builds this with pushBackUnique inside the loop,
 * which is O(n^2) over the full equipment list and is the confirmed root cause
 * of the "arsenal slow to load" reports on that mod's Workshop page.
 *
 * Tab 27 (CARGOBULLET, TEH's loose-ammo pool) is always excluded - it has no
 * physical or ACE-virtual-item representation, see script_component.hpp.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Distinct classnames present anywhere in jna_dataList <ARRAY of STRINGS>
 *
 * Example:
 * [] call FUNC(poolFlat)
 */

if (isNil "jna_dataList") exitWith {[]};

private _skipTabs = [JNA_TAB_FACE, JNA_TAB_VOICE, JNA_TAB_INSIGNIA, JNA_TAB_CARGOMAG, JNA_TAB_CARGOBULLET];
private _seen = createHashMap;

{
    private _tab = _forEachIndex;
    if (_tab in _skipTabs) then {continue};

    {
        _x params [["_class", "", [""]], ["_count", 0, [0]]];
        if (_class == "" || {_count == 0}) then {continue};
        _seen set [_class, true];
    } forEach _x;
} forEach jna_dataList;

keys _seen
