#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Server-side: applies a pool count delta for one classname via JNA's own
 * add/removeItem primitives (these already own jna_dataList bookkeeping,
 * unlimited-stock (-1) handling, and syncing the JNA UI skin to whoever
 * still has it open - reuse them rather than touching jna_dataList directly).
 *
 * Arguments:
 * 0: Classname <STRING>
 * 1: Delta, positive returns the item to the pool, negative withdraws it <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["arifle_MX_F", -1] call FUNC(serverAdjustPool)
 */

if (!isServer) exitWith {};

params [["_class", "", [""]], ["_delta", 0, [0]]];

if (_class == "" || {_delta == 0}) exitWith {};

private _index = _class call jn_fnc_arsenal_itemType;
// Can't classify (e.g. TEH's bullet-pile ammo classnames aren't weapons/magazines/
// backpacks/glasses) - nothing sound to do, see JNA_TAB_CARGOBULLET note.
if (_index < 0) exitWith {};

if (_delta > 0) then {
    [_index, _class, _delta] call jn_fnc_arsenal_addItem;
} else {
    [_index, _class, -_delta] call jn_fnc_arsenal_removeItem;
};
