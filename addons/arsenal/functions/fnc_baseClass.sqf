#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Resolves a classname to whatever it's actually tracked as in the pool -
 * the specific variant a player ends up with after picking something in
 * ACE arsenal (a camo/color variant, a CBA switchable attachment/scripted
 * optic's currently-cycled sub-class, an attachments-bearing weapon) can
 * differ from the exact classname jna_dataList has stored. A raw
 * exact-string match (fnc_poolFind.sqf) would treat that as "not in the
 * pool at all" and refuse it.
 *
 * Delegates to ACE's own resolution functions where they apply
 * (ace_arsenal_fnc_baseWeapon/baseOptic/baseAttachment - these already
 * handle CBA Scripted Optics/Switchable Attachments correctly, no reason
 * to reimplement that), then falls back to ace_arsenal_uniqueBase
 * (framework doc section 3.2) for the types those three don't cover -
 * uniforms, vests, backpacks, NVGs etc.
 *
 * Arguments:
 * 0: Classname <STRING>
 *
 * Return Value:
 * Resolved classname <STRING>
 *
 * Example:
 * ["arifle_MX_ARCO_F"] call FUNC(baseClass)
 */

params [["_class", "", [""]]];

if (_class == "") exitWith {_class};

private _tab = _class call jn_fnc_arsenal_itemType;

private _resolved = switch (true) do {
    case (_tab in [JNA_TAB_PRIMARYWEAPON, JNA_TAB_SECONDARYWEAPON, JNA_TAB_HANDGUN]): {
        _class call ace_arsenal_fnc_baseWeapon
    };
    case (_tab == JNA_TAB_ITEMOPTIC): {
        private _r = _class call ace_arsenal_fnc_baseOptic;
        if (_r == _class) then {_r = _class call ace_arsenal_fnc_baseAttachment};
        _r
    };
    case (_tab in [JNA_TAB_ITEMACC, JNA_TAB_ITEMMUZZLE, JNA_TAB_ITEMBIPOD]): {
        _class call ace_arsenal_fnc_baseAttachment
    };
    default {_class};
};

private _uniqueBase = getText (configFile >> "CfgWeapons" >> _resolved >> "ace_arsenal_uniqueBase");
if (_uniqueBase == "") then {_uniqueBase = getText (configFile >> "CfgMagazines" >> _resolved >> "ace_arsenal_uniqueBase")};
if (_uniqueBase == "") then {_uniqueBase = getText (configFile >> "CfgVehicles" >> _resolved >> "ace_arsenal_uniqueBase")};

if (_uniqueBase != "") exitWith {_uniqueBase};

_resolved
