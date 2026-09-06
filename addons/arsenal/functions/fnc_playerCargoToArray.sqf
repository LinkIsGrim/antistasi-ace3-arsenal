#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Replaces every [_unit, true] call jn_fnc_arsenal_cargoToArray call site in
 * this addon - "give me a person's own gear in JNA's array shape" needs
 * different handling per variant:
 * - CE: no such mode exists in jn_fnc_arsenal_cargoToArray at all (confirmed
 *   against release tags, see fnc_isCE.sqf's header) - built directly
 *   instead, see fnc_playerCargoToArrayCE.sqf.
 * - Ultimate/TEH: real support, but the result needs a small correction -
 *   see fnc_fixBinocularDoubleCount.sqf's header.
 *
 * Container/vehicle-cargo calls (fnc_transferDialog.sqf,
 * fnc_serverTransfer.sqf) are unaffected by either variant difference and
 * still call jn_fnc_arsenal_cargoToArray directly - this is only for the
 * player-mode call sites.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Array of arrays of [classname, amount], indexed by JNA tab <ARRAY>
 *
 * Example:
 * [player] call FUNC(playerCargoToArray)
 */

params [["_unit", objNull, [objNull]]];

if ([] call FUNC(isCE)) exitWith {
    [_unit] call FUNC(playerCargoToArrayCE)
};

private _result = [_unit, true] call jn_fnc_arsenal_cargoToArray;
[_result, _unit] call FUNC(fixBinocularDoubleCount)
