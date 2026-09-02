#include "\a3\ui_f\hpp\defineCommonGrids.inc"

#define TRANSFER_X (GUI_GRID_CENTER_X + GUI_GRID_CENTER_W * 6)
#define TRANSFER_Y (GUI_GRID_CENTER_Y + GUI_GRID_CENTER_H * 3)
#define TRANSFER_W (GUI_GRID_CENTER_W * 28)
#define TRANSFER_H (GUI_GRID_CENTER_H * 19)

class GVAR(TransferDialog) {
    idd = IDD_TRANSFER;
    movingEnable = 1;
    enableSimulation = 1;
    onLoad = QUOTE([ARR_2('onLoad',_this)] call FUNC(transferDialog));
    onUnload = QUOTE([ARR_2('onUnload',_this)] call FUNC(transferDialog));

    class controlsBackground {
        class Background: RscText {
            idc = IDC_TRANSFER_BACKGROUND;
            x = QUOTE(TRANSFER_X); y = QUOTE(TRANSFER_Y); w = QUOTE(TRANSFER_W); h = QUOTE(TRANSFER_H);
            colorBackground[] = {0, 0, 0, 0.8};
        };
    };

    class controls {
        class Title: RscText {
            idc = IDC_TRANSFER_TITLE;
            text = "Arsenal <-> Container";
            x = QUOTE(TRANSFER_X); y = QUOTE(TRANSFER_Y); w = QUOTE(TRANSFER_W); h = QUOTE(GUI_GRID_CENTER_H);
            sizeEx = QUOTE(GUI_GRID_CENTER_H * 0.7);
        };

        class Search: RscEdit {
            idc = IDC_TRANSFER_SEARCH;
            x = QUOTE(TRANSFER_X); y = QUOTE(TRANSFER_Y + GUI_GRID_CENTER_H * 1.2);
            w = QUOTE(TRANSFER_W * 0.45); h = QUOTE(GUI_GRID_CENTER_H);
            onKeyUp = QUOTE([ARR_2('search',_this)] call FUNC(transferDialog));
        };

        class PoolTitle: RscText {
            idc = IDC_TRANSFER_POOLTITLE;
            text = "Arsenal";
            x = QUOTE(TRANSFER_X); y = QUOTE(TRANSFER_Y + GUI_GRID_CENTER_H * 2.4);
            w = QUOTE(TRANSFER_W * 0.45); h = QUOTE(GUI_GRID_CENTER_H * 0.8);
        };

        class Pool: RscListNBox {
            idc = IDC_TRANSFER_POOL;
            x = QUOTE(TRANSFER_X); y = QUOTE(TRANSFER_Y + GUI_GRID_CENTER_H * 3.2);
            w = QUOTE(TRANSFER_W * 0.45); h = QUOTE(TRANSFER_H - GUI_GRID_CENTER_H * 4.4);
            columns[] = {0, 0.78};
            rowHeight = 0.035;
        };

        class ContainerTitle: RscText {
            idc = IDC_TRANSFER_CONTAINERTITLE;
            text = "Container";
            x = QUOTE(TRANSFER_X + TRANSFER_W * 0.55); y = QUOTE(TRANSFER_Y + GUI_GRID_CENTER_H * 2.4);
            w = QUOTE(TRANSFER_W * 0.45); h = QUOTE(GUI_GRID_CENTER_H * 0.8);
        };

        class Container: RscListNBox {
            idc = IDC_TRANSFER_CONTAINER;
            x = QUOTE(TRANSFER_X + TRANSFER_W * 0.55); y = QUOTE(TRANSFER_Y + GUI_GRID_CENTER_H * 3.2);
            w = QUOTE(TRANSFER_W * 0.45); h = QUOTE(TRANSFER_H - GUI_GRID_CENTER_H * 4.4);
            columns[] = {0, 0.78};
            rowHeight = 0.035;
        };

        class Amount: RscEdit {
            idc = IDC_TRANSFER_AMOUNT;
            text = "1";
            x = QUOTE(TRANSFER_X + TRANSFER_W * 0.47); y = QUOTE(TRANSFER_Y + GUI_GRID_CENTER_H * 1.2);
            w = QUOTE(TRANSFER_W * 0.06); h = QUOTE(GUI_GRID_CENTER_H);
        };

        class ToContainer: RscButton {
            idc = IDC_TRANSFER_TOCONTAINER;
            text = ">>";
            x = QUOTE(TRANSFER_X + TRANSFER_W * 0.465); y = QUOTE(TRANSFER_Y + TRANSFER_H * 0.42);
            w = QUOTE(TRANSFER_W * 0.07); h = QUOTE(GUI_GRID_CENTER_H);
            onButtonClick = QUOTE([ARR_2('toContainer',_this)] call FUNC(transferDialog));
        };

        class ToPool: RscButton {
            idc = IDC_TRANSFER_TOPOOL;
            text = "<<";
            x = QUOTE(TRANSFER_X + TRANSFER_W * 0.465); y = QUOTE(TRANSFER_Y + TRANSFER_H * 0.5);
            w = QUOTE(TRANSFER_W * 0.07); h = QUOTE(GUI_GRID_CENTER_H);
            onButtonClick = QUOTE([ARR_2('toPool',_this)] call FUNC(transferDialog));
        };

        class Info: RscText {
            idc = IDC_TRANSFER_INFO;
            text = "";
            x = QUOTE(TRANSFER_X); y = QUOTE(TRANSFER_Y + TRANSFER_H - GUI_GRID_CENTER_H * 1.1);
            w = QUOTE(TRANSFER_W * 0.75); h = QUOTE(GUI_GRID_CENTER_H);
        };

        class Close: RscButton {
            idc = IDC_TRANSFER_CLOSE;
            text = "Close";
            x = QUOTE(TRANSFER_X + TRANSFER_W * 0.8); y = QUOTE(TRANSFER_Y + TRANSFER_H - GUI_GRID_CENTER_H * 1.1);
            w = QUOTE(TRANSFER_W * 0.2); h = QUOTE(GUI_GRID_CENTER_H);
            onButtonClick = QUOTE(closeDialog 0;);
        };
    };
};
