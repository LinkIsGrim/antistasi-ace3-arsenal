#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Server-side: locates a classname's entry in jna_dataList.
 *
 * Arguments:
 * 0: Classname <STRING>
 *
 * Return Value:
 * [tab, stock, classname] <ARRAY> - tab is -1 and stock 0 if not found at all
 *
 * Example:
 * ["arifle_MX_F"] call FUNC(poolFind)
 */

if (!isServer) exitWith {[-1, 0, ""]};

params [["_class", "", [""]]];

if (_class == "" || {isNil "jna_dataList"}) exitWith {[-1, 0, _class]};

private _tab = _class call jn_fnc_arsenal_itemType;
if (_tab == JNA_TAB_CARGOMAG) then {_tab = JNA_TAB_CARGOMAGALL};

if (_tab < 0 || {_tab >= count jna_dataList}) exitWith {[-1, 0, _class]};

private _entry = (jna_dataList select _tab) findIf {(_x select 0) == _class};
if (_entry < 0) exitWith {[-1, 0, _class]};

[_tab, (jna_dataList select _tab select _entry select 1), _class]
