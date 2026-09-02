#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Client-side: shows the server's verdict on a fnc_transferDialog.sqf
 * transfer request. Registered against QGVAR(transferResult) in
 * XEH_postInit.sqf.
 *
 * Arguments:
 * 0: Message <STRING>
 *
 * Return Value:
 * None
 */

params [["_msg", "", [""]]];

private _display = findDisplay IDD_TRANSFER;

if (isNull _display) exitWith {
    [_msg] call BIS_fnc_error;
};

(_display displayCtrl IDC_TRANSFER_INFO) ctrlSetText _msg;
