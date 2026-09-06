#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * ACEAX (ACE3 Arsenal Extended) compat - installed only if ACEAX's arsenal
 * component is actually loaded (isNil guards below), same capture-then-
 * reassign wrap pattern as the JNA hooks in XEH_postInit.sqf.
 *
 * Root cause (confirmed via source, then via a field report that the
 * weak-match suppression alone did NOT fix the phantom left-panel row):
 * some weapon packs (e.g. Robert Hammer's M4/M16 family) define each
 * grip+camo combination as its own separate, hardcoded weapon class rather
 * than a base weapon with CBA-switchable sub-attachments - the model's
 * option space is SPARSE, not a full cartesian product of every option
 * value. ACE's own left panel already lists each such class as its own
 * independent row with its own stock, entirely unrelated to ACEAX. ACEAX's
 * per-attribute checkbox UI (aceax_arsenal_fnc_changeCurrentConfig)
 * layers a "toggle one attribute at a time, apply immediately" model on
 * top of that - fine when every combination is a real variant (an
 * orthogonal option space), but for a sparse one, reaching a variant that
 * differs by two attributes needs an intermediate combination that isn't
 * itself real. ACEAX's own fallback for that intermediate step
 * (aceax_gearinfo_fnc_findConfigByValue, which ACEAX's own source calls a
 * "weak match") jumps to the first variant sharing just the one toggled
 * value - producing the field-reported stuck/duplicate row - and simply
 * rejecting that fallback (an earlier version of this fix) makes such
 * variants flatly unreachable instead, since a valid single-attribute-at-a-
 * time path genuinely does not exist for a sparse space.
 *
 * Fix: detect sparse models (FUNC(isSparseModel) - real variation count via
 * aceax_gearinfo_fnc_getVariations is less than the full cartesian product
 * of every option's value count) and, only for those, replace the
 * per-attribute checkboxes with a flat list of the real, fully-valid
 * variants - sidesteps path-finding entirely instead of trying to make an
 * incremental UI reach a sparse target. Orthogonal models (the common case)
 * are untouched and keep ACEAX's native per-attribute UI.
 *
 * Implementation deliberately reuses ACEAX's own
 * aceax_arsenal_fnc_generateOptionsUI rendering (image+checkbox+button grid
 * positioning, scrollbar workaround, config panel sizing) rather than
 * building new UI from scratch - this addon has no way to visually verify
 * pixel layout at all (no in-game testing in this environment), so the only
 * way to keep that risk bounded is to change what feeds the existing,
 * already-correct layout code, not add a second one. For a sparse model,
 * aceax_gearinfo_fnc_getModelOptions is temporarily swapped out (restored
 * immediately after the synchronous call-through completes - safe, nothing
 * else can run getModelOptions concurrently mid-call) to return one
 * synthetic option whose values are the real variants themselves, each
 * value's name set directly to that variant's own classname; then, once
 * generateOptionsUI is done creating controls, this addon rewires each
 * synthetic button's ButtonClick handler to directly apply the exact
 * config that produced it via configFile >> _classRoot >> _valueName - it
 * is not going back through
 * aceax_arsenal_fnc_changeCurrentConfig/onValueButton at all for these,
 * since that function's option-index/single-attribute-tuple bookkeeping
 * doesn't fit "the whole variant was picked directly" and isn't meant to.
 * The direct-apply tail (lbSetData/lbSetText/tooltip/picture,
 * onSelChangedLeft) mirrors ACEAX's own fnc_changeCurrentConfig.sqf's known-
 * working final steps exactly - only the option-index/exact-vs-weak-match
 * resolution above it is skipped, since a sparse-model button already
 * carries a real, fully-resolved config, no resolution needed.
 *
 * Stock counts (aceax_arsenal_fnc_generateOptionsUI's decoration pass) are
 * baked directly into each sparse-model value's label instead, since the
 * generic per-button decoration pass below only understands ACEAX's normal
 * per-attribute idcToConfig shape.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 */

// True if _model's real, config-defined variant count is less than the
// full cartesian product of every one of its options' value counts - i.e.
// at least one attribute combination has no real variant behind it at all.
GVAR(aceaxIsSparseModel) = {
    params ["_classRoot", "_model"];

    private _modelDefinition = configFile >> "XtdGearModels" >> _classRoot >> _model;
    private _optionsNames = getArray (_modelDefinition >> "options");
    if (_optionsNames isEqualTo []) exitWith {false};

    private _fullCartesian = 1;
    {
        _fullCartesian = _fullCartesian * (count (getArray ((_modelDefinition >> _x) >> "values")));
    } forEach _optionsNames;

    private _variations = [_classRoot, _model] call aceax_gearinfo_fnc_getVariations;

    (count _variations) < _fullCartesian
};

// Synthetic getModelOptions replacement for a sparse model - one option
// ("variant") whose values are the model's real, fully-valid variants
// (aceax_gearinfo_fnc_getVariations), each value's name set to that
// variant's own classname directly (not a per-attribute token). Matches
// aceax_gearinfo_fnc_getModelOptions's own return shape exactly so
// generateOptionsUI's rendering loop needs no changes at all. Texture
// options are left empty for sparse models - a separate axis from the
// grip/camo reachability problem this addon is fixing, not something to
// take on here too.
GVAR(aceaxSparseModelOptions) = {
    params ["_classRoot", "_model", ["_modelDefinition", configNull], ["_kind", "options"]];
    if (_kind != "options") exitWith {[]};

    private _variations = [_classRoot, _model] call aceax_gearinfo_fnc_getVariations;

    private _values = [];
    {
        private _config = _y;
        private _classname = configName _config;
        private _displayName = getText (_config >> "displayName");
        private _stock = (_classname call FUNC(poolFind)) select 1;

        _values pushBack [
            _classname,
            format ["%1 (%2)", _displayName, _stock],
            getText (_config >> "picture"),
            "",
            format ["%1\n%2 in stock", _displayName, _stock],
            []
        ];
    } forEach _variations;

    [["variant", "Variant", "", 0, _values, 0, true, [], false]]
};

if (!isNil "aceax_arsenal_fnc_changeCurrentConfig") then {
    GVAR(originalAceaxChangeCurrentConfig) = aceax_arsenal_fnc_changeCurrentConfig;
    aceax_arsenal_fnc_changeCurrentConfig = {
        params ["", "_data"];
        _data params ["_optionIndex", "", "", "_valueName", ["_type", ""]];

        if (_type != "textureoptions" && {(aceax_arsenal_currentModelOptions select _optionIndex) != _valueName}) then {
            private _options = +aceax_arsenal_currentModelOptions;
            _options set [_optionIndex, _valueName];

            private _exactMatch = [aceax_arsenal_currentConfig, aceax_arsenal_currentModel, _options] call aceax_gearinfo_fnc_findConfig;
            if (isNull _exactMatch) exitWith {
                ["That combination isn't a valid variant on its own - some options can't be mixed."] call BIS_fnc_error;
            };
        };

        _this call GVAR(originalAceaxChangeCurrentConfig);
    };
};

if (!isNil "aceax_arsenal_fnc_generateOptionsUI") then {
    GVAR(originalAceaxGenerateOptionsUI) = aceax_arsenal_fnc_generateOptionsUI;
    aceax_arsenal_fnc_generateOptionsUI = {
        params ["_display", ["_classRoot", ""], ["_selectedModel", ""]];

        private _sparse = _selectedModel != "" && {[_classRoot, _selectedModel] call GVAR(aceaxIsSparseModel)};

        if (_sparse) then {
            private _realGetModelOptions = aceax_gearinfo_fnc_getModelOptions;
            aceax_gearinfo_fnc_getModelOptions = GVAR(aceaxSparseModelOptions);
            _this call GVAR(originalAceaxGenerateOptionsUI);
            aceax_gearinfo_fnc_getModelOptions = _realGetModelOptions;

            {
                private _idc = _x;
                private _data = aceax_arsenal_idcToConfig getOrDefault [_idc, []];
                if (_data isEqualTo []) then {continue};

                _data params ["", "", "", "_valueName", "_kind"];
                if (_kind != "options") then {continue};

                private _button = _display displayCtrl (_idc + 2);
                if (isNull _button) then {continue};

                private _targetConfig = configFile >> _classRoot >> _valueName;
                if (isNull _targetConfig) then {continue};

                _button ctrlRemoveAllEventHandlers "ButtonClick";
                _button ctrlAddEventHandler ["ButtonClick", {
                    params ["_control"];
                    private _display = ctrlParent _control;
                    private _match = _control getVariable [QGVAR(aceaxTargetConfig), configNull];
                    if (isNull _match) exitWith {};

                    // 13 == ACEAX's own IDC_leftTabContent (addons/arsenal/defines.hpp) -
                    // hardcoded since that header isn't ours to #include; confirmed
                    // against ACEAX's own source, not guessed.
                    private _ctrlPanel = _display displayCtrl 13;
                    private _i = lbCurSel _ctrlPanel;
                    if (_i == -1) exitWith {};

                    private _previous = _ctrlPanel lbData _i;
                    private _newValue = configName _match;

                    (call aceax_arsenal_fnc_leftPanelConfig) params ["", "_virt", "_virtSub"];
                    private _virtItems = aceax_arsenal_filteredVirtualItems get _virt;
                    if (_virtSub != -1) then {_virtItems = _virtItems get _virtSub};
                    _virtItems deleteAt _previous;
                    _virtItems set [_newValue, nil];

                    private _displayName = getText (_match >> "displayName");
                    _ctrlPanel lbSetData [_i, _newValue];
                    _ctrlPanel lbSetText [_i, _displayName];
                    _ctrlPanel lbSetTooltip [_i, format ["%1\n%2", _displayName, _newValue]];
                    _ctrlPanel lbSetPicture [_i, getText (_match >> "picture")];

                    [_ctrlPanel, _i] call aceax_arsenal_fnc_onSelChangedLeft;
                }];
                _button setVariable [QGVAR(aceaxTargetConfig), _targetConfig];
            } forEach aceax_arsenal_valuesIdc;
        } else {
            _this call GVAR(originalAceaxGenerateOptionsUI);

            if (!isNil "jna_dataList") then {
                {
                    private _idc = _x;
                    private _data = aceax_arsenal_idcToConfig getOrDefault [_idc, []];
                    if (_data isEqualTo []) then {continue};

                    _data params ["_optionIndex", "", "", "_valueName", "_kind"];
                    if (_kind == "textureoptions") then {continue};

                    private _button = _display displayCtrl (_idc + 2);
                    if (isNull _button) then {continue};

                    private _options = +aceax_arsenal_currentModelOptions;
                    _options set [_optionIndex, _valueName];

                    private _match = [aceax_arsenal_currentConfig, aceax_arsenal_currentModel, _options] call aceax_gearinfo_fnc_findConfig;
                    if (isNull _match) then {continue};

                    private _stock = ((configName _match) call FUNC(poolFind)) select 1;
                    private _label = ctrlText _button;
                    private _tooltip = ctrlTooltip _button;

                    _button ctrlSetText format ["%1 (%2)", _label, _stock];
                    _button ctrlSetTooltip ([format ["%1 in stock", _stock], format ["%1\n%2 in stock", _tooltip, _stock]] select (_tooltip != ""));
                } forEach aceax_arsenal_valuesIdc;
            };
        };
    };
};
