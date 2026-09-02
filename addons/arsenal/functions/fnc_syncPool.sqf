#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Syncs a box's ACE virtual items from the current jna_dataList pool, but
 * skips the full removeVirtualItems+addVirtualItems round-trip when the
 * pool's classname set hasn't changed since the last sync (cached as a
 * sorted, joined signature string - sorted because fnc_poolFlat.sqf returns
 * hashmap keys, whose iteration order isn't guaranteed stable between calls
 * even for identical content).
 *
 * Only jna_object is ever synced this way (both fnc_openPlayer.sqf and
 * fnc_openLoadout.sqf act on the same box; container fill no longer touches
 * ACE virtual items at all, see fnc_openContainer.sqf), so one cached
 * signature is enough - this isn't a general per-box cache.
 *
 * Arguments:
 * 0: Box <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_box] call FUNC(syncPool)
 */

params [["_box", objNull, [objNull]]];
if (isNull _box) exitWith {};

private _items = [] call FUNC(poolFlat);
private _signature = (+_items) apply {toLowerANSI _x};
_signature sort true;
_signature = _signature joinString ",";

if (_signature == (missionNamespace getVariable [QGVAR(poolSignature), ""])) exitWith {};

[_box, true, false] call ace_arsenal_fnc_removeVirtualItems;
[_box, _items, false] call ace_arsenal_fnc_addVirtualItems;

GVAR(poolSignature) = _signature;
