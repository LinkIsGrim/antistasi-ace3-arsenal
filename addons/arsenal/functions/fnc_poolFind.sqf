#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Locates a classname's entry in jna_dataList. Safe to call client-side for
 * display purposes (fnc_decorate.sqf) now that jna_dataList is kept synced
 * for the duration of an arsenal session (fnc_requestDataListSync.sqf) -
 * still only the server's own copy is authoritative for actual accept/refuse
 * decisions (fnc_serverReconcile.sqf/fnc_serverTransfer.sqf already call this
 * from server context for that).
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

params [["_class", "", [""]]];

if (_class == "" || {isNil "jna_dataList"}) exitWith {[-1, 0, _class]};

_class = _class call FUNC(baseClass);

private _tab = _class call jn_fnc_arsenal_itemType;
if (_tab == JNA_TAB_CARGOMAG) then {_tab = JNA_TAB_CARGOMAGALL};

if (_tab < 0 || {_tab >= count jna_dataList}) exitWith {[-1, 0, _class]};

private _entry = (jna_dataList select _tab) findIf {(_x select 0) == _class};
if (_entry < 0) exitWith {[-1, 0, _class]};

[_tab, (jna_dataList select _tab select _entry select 1), _class]
