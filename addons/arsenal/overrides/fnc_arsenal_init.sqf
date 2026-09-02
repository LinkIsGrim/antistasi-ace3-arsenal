#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Replaces JN_fnc_arsenal_init (assigned in XEH_postInit.sqf). Antistasi
 * (CE/Ultimate/TEH) calls this from both fn_initServer.sqf and
 * fn_initClient.sqf with the arsenal box object.
 *
 * Doesn't touch jn_fnc_arsenal (JNA's own BIS-arsenal-skinned display) at
 * all - the "Arsenal"/"Container" actions below go straight through
 * ace_arsenal_fnc_openBox instead, so none of JNA's arsenalOpened/
 * arsenalClosed scripted-event dispatch (which only fires for
 * BIS_fnc_arsenal) is relevant to this path.
 *
 * Arguments:
 * 0: Arsenal box object <OBJECT>
 *
 * Return Value:
 * None
 */

params [["_object", objNull, [objNull]]];

// Idempotent - matches JNA's own init, which guards the same way.
if (!isNull (missionNamespace getVariable ["jna_object", objNull])) exitWith {};
if (isNull _object) exitWith {
    ["Antistasi ACE3 Arsenal: init got a null object"] call BIS_fnc_error;
};

missionNamespace setVariable ["jna_object", _object];

// Kept for compatibility with other JNA code that still reads this (trader/guest
// limit coloring in JNA's own skin) even though our own flow doesn't use it.
private _limit = missionNamespace getVariable ["A3A_guestItemLimit", 0];
jna_minItemMember = [];
for "_i" from 0 to (JNA_TAB_COUNT_BASE - 1) do {jna_minItemMember pushBack _limit};
jna_minItemMember set [JNA_TAB_CARGOMAG, _limit * 3];
jna_minItemMember set [JNA_TAB_CARGOMAGALL, _limit * 3];

// Populates bis_fnc_arsenal_data, which jn_fnc_arsenal_itemType falls back to
// for classnames it can't classify by config type alone. Still needed even
// though we never open JNA's own skin.
["Preload"] call jn_fnc_arsenal;

if (isServer && {isNil "jna_dataList"}) then {
    jna_dataList = [];
    // TEH's own fn_initServer.sqf independently extends this to 28 tabs
    // (bullet-pile migration) after this runs, regardless of which
    // JN_fnc_arsenal_init implementation is active - safe to always start
    // at the CE/Ultimate baseline here.
    for "_i" from 0 to (JNA_TAB_COUNT_BASE - 1) do {jna_dataList pushBack []};
};

if (hasInterface) then {
    _object addAction [
        format ["<img image='%1' size='1.6' shadow=2/><t size='1'> %2</t>",
            "\A3\ui_f\data\GUI\Rsc\RscDisplayArsenal\spaceArsenal_ca.paa",
            localize "STR_A3_Arsenal"],
        {[] call JN_fnc_arsenal_handleAction},
        [],
        6, true, false, "",
        "alive _target && {_target distance _this < 5} && {vehicle player == player}"
    ];

    _object addAction [
        format ["<img image='%1' size='1.6' shadow=2/><t size='1'> %2</t>",
            "\A3\ui_f\data\GUI\Rsc\RscDisplayArsenal\cargoMag_ca.paa",
            "Open Container"],
        {[cursorObject] call FUNC(openContainer)},
        [],
        6, true, false, "",
        "alive _target && {_target distance _this < 5} && {vehicle player == player}"
    ];

    // TEH-only extras. Called directly against TEH's own functions - none of
    // these open an arsenal display, so there's nothing for us to bridge.
    if (!isNil "JN_fnc_arsenal_quickReload") then {
        _object addAction [
            format ["<img image='%1' size='1.6' shadow=2/><t size='1'> %2</t>",
                "\A3\Ui_f\data\IGUI\Cfg\Actions\reload_ca.paa", "Quick resupply"],
            {[vehicle player] call JN_fnc_arsenal_quickReload},
            [], 15, true, false, "", "true"
        ];
    };

    if (!isNil "JN_fnc_arsenal_loadInventory") then {
        _object addAction [
            format ["<img image='%1' size='1.6' shadow=2/><t size='1'> %2</t>",
                "\A3\Ui_f\data\GUI\Rsc\RscDisplayArsenal\uniform_ca.paa", "Equip last loadout"],
            {
                private _template = player getVariable ["lastArsenalLoadout", ""];
                if (_template != "") then {
                    _template call JN_fnc_arsenal_loadInventory;
                } else {
                    ["No saved loadout yet - save or load one from the arsenal first."] call BIS_fnc_error;
                };
            },
            [], 6, true, false, "",
            "alive _target && {_target distance _this < 5} && {vehicle player == player}"
        ];
    };

    if (!isNil "A3A_fnc_MagConvert_open") then {
        _object addAction [
            format ["<img image='%1' size='1.6' shadow=2/><t size='1'> %2</t>",
                "\A3\Ui_f\data\GUI\Rsc\RscDisplayArsenal\CargoMagAll_ca.paa", "Mag Service"],
            {[] call A3A_fnc_MagConvert_open},
            [], 6, true, false, "",
            "alive _target && {_target distance _this < 5} && {vehicle player == player}"
        ];
    };
};

arsenalInit = true;
