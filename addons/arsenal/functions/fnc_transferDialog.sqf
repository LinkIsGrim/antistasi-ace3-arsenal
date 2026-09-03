#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Client-side dispatcher for the arsenal <-> container transfer dialog
 * (dialogues/transferDialog.hpp). GVAR(transferContainer) is set by
 * fnc_openContainer.sqf before the dialog is created. The pool side reads
 * jna_dataList directly - kept fresh via fnc_requestDataListSync.sqf on
 * load, since it isn't reliable to read client-side otherwise (see
 * fnc_serverSyncDataList.sqf's header for why).
 *
 * Arguments:
 * 0: Mode <STRING>
 * 1: Mode-specific params <ANY>
 *
 * Return Value:
 * None
 */

params [["_mode", "", [""]], ["_params", []]];

private _fnc_nameOf = {
    params ["_class"];
    private _name = getText (configFile >> "CfgWeapons" >> _class >> "displayName");
    if (_name == "") then {_name = getText (configFile >> "CfgMagazines" >> _class >> "displayName")};
    if (_name == "") then {_name = getText (configFile >> "CfgVehicles" >> _class >> "displayName")};
    if (_name == "") then {_name = getText (configFile >> "CfgGlasses" >> _class >> "displayName")};
    if (_name == "") then {_name = _class};
    _name
};

switch (_mode) do {

    case "onLoad": {
        // _params is already the display here (config wraps the dialog's raw
        // onLoad _this as ['onLoad', _this], matching ACE's own RscAttributes.hpp
        // convention) - no further unwrapping needed, and unused below anyway.
        ["fill"] call FUNC(transferDialog);
        [{["fill"] call FUNC(transferDialog)}] call FUNC(requestDataListSync);
    };

    case "onUnload": {
        GVAR(transferContainer) = objNull;
    };

    case "search": {
        ["fill"] call FUNC(transferDialog);
    };

    case "fill": {
        private _display = findDisplay IDD_TRANSFER;
        if (isNull _display) exitWith {};

        private _container = GVAR(transferContainer);
        if (isNull _container) exitWith {};

        private _filter = toLowerANSI (ctrlText (_display displayCtrl IDC_TRANSFER_SEARCH));

        private _poolList = _display displayCtrl IDC_TRANSFER_POOL;
        private _contList = _display displayCtrl IDC_TRANSFER_CONTAINER;
        lnbClear _poolList;
        lnbClear _contList;

        private _fnc_addRows = {
            params ["_ctrl", "_entries"];
            private _rows = [];

            {
                _x params ["_class", "_count"];
                if (_class == "" || {_count == 0}) then {continue};

                private _name = [_class] call _fnc_nameOf;
                if (_filter != "" && {(toLowerANSI _name) find _filter < 0}) then {continue};

                _rows pushBack [_name, _class, _count];
            } forEach _entries;

            _rows sort [true, {_this select 0}];

            {
                _x params ["_name", "_class", "_count"];
                private _shown = if (_count == -1) then {"inf"} else {str _count};
                private _row = _ctrl lnbAddRow [_name, _shown];
                _ctrl lnbSetData [[_row, 0], _class];
            } forEach _rows;
        };

        private _poolEntries = [];
        if (!isNil "jna_dataList") then {
            {
                private _tab = _forEachIndex;
                if (_tab in [JNA_TAB_FACE, JNA_TAB_VOICE, JNA_TAB_INSIGNIA, JNA_TAB_CARGOMAG, JNA_TAB_CARGOBULLET]) then {continue};
                _poolEntries append _x;
            } forEach jna_dataList;
        };
        [_poolList, _poolEntries] call _fnc_addRows;

        private _contCargo = _container call jn_fnc_arsenal_cargoToArray;
        private _contEntries = [];
        {
            private _tab = _forEachIndex;
            if (_tab in [JNA_TAB_FACE, JNA_TAB_VOICE, JNA_TAB_INSIGNIA, JNA_TAB_CARGOBULLET]) then {continue};
            _contEntries append _x;
        } forEach _contCargo;
        [_contList, _contEntries] call _fnc_addRows;

        (_display displayCtrl IDC_TRANSFER_INFO) ctrlSetText "";
    };

    case "toContainer": {
        private _display = findDisplay IDD_TRANSFER;
        private _list = _display displayCtrl IDC_TRANSFER_POOL;
        private _row = lnbCurSelRow _list;
        if (_row < 0) exitWith {(_display displayCtrl IDC_TRANSFER_INFO) ctrlSetText "Select something in the arsenal list."};

        private _class = _list lnbData [_row, 0];
        private _amount = round parseNumber (ctrlText (_display displayCtrl IDC_TRANSFER_AMOUNT));
        [QGVAR(transferRequest), [player, GVAR(transferContainer), _class, (1 max _amount), "toContainer"]] call CBA_fnc_serverEvent;
    };

    case "toPool": {
        private _display = findDisplay IDD_TRANSFER;
        private _list = _display displayCtrl IDC_TRANSFER_CONTAINER;
        private _row = lnbCurSelRow _list;
        if (_row < 0) exitWith {(_display displayCtrl IDC_TRANSFER_INFO) ctrlSetText "Select something in the container list."};

        private _class = _list lnbData [_row, 0];
        private _amount = round parseNumber (ctrlText (_display displayCtrl IDC_TRANSFER_AMOUNT));
        [QGVAR(transferRequest), [player, GVAR(transferContainer), _class, (1 max _amount), "toPool"]] call CBA_fnc_serverEvent;
    };
};
