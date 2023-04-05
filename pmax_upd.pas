program pmax_upd;


{$librarypath '../Window_Library/src'}
{$librarypath '../PokeyMAX/'}

{$DEFINE BASICOFF}

uses crt, sysutils, stringUtils, a8defines, a8defwin, a8libwin, a8libgadg, a8libmenu, a8libmisc, pm_detect, pm_config, pm_flash;

const
    version: string = 'PokeyMAX Update v.0.13';

    SCREEN_ADDRESS = $BC40;
    DL_BLANK8 = %01110000; // 8 blank lines
    DL_MODE_40x24T2 = 2;
    DL_LMS = %01000000; // Order to set new memory address
    DL_JVB = %01000001; // Jump to begining

    display_list: array [0..31] of byte = (
        DL_BLANK8, DL_BLANK8, DL_BLANK8, DL_MODE_40x24T2 + DL_LMS, Lo(SCREEN_ADDRESS), Hi(SCREEN_ADDRESS),
        DL_MODE_40x24T2, DL_MODE_40x24T2, DL_MODE_40x24T2, DL_MODE_40x24T2, DL_MODE_40x24T2, DL_MODE_40x24T2,
        DL_MODE_40x24T2, DL_MODE_40x24T2, DL_MODE_40x24T2, DL_MODE_40x24T2, DL_MODE_40x24T2, DL_MODE_40x24T2,
        DL_MODE_40x24T2, DL_MODE_40x24T2, DL_MODE_40x24T2, DL_MODE_40x24T2, DL_MODE_40x24T2, DL_MODE_40x24T2,
        DL_MODE_40x24T2, DL_MODE_40x24T2, DL_MODE_40x24T2, DL_MODE_40x24T2, DL_MODE_40x24T2, DL_JVB,
        lo(word(@display_list)), hi(word(@display_list))
    );
    
    menu_main: array[0..2] of string = (' PokeyMAX ', ' Config ', ' About ');
    str_buttons_accept : array[0..1] of string = ('[  OK  ]', '[Cancel]');
    string_confirm = 'Are you sure?';

var
    win_main, win_details, win_progress: Byte;  // opend window handles on main screen
    selected_menu: Byte;                        // which menu is current
    status_end: Boolean;                        // flag to indicate application is going to close
    status_close: Byte;                         // flag to indicate current window will close
    PMAX_present: Boolean = false;              // Set to true if PokeyMax is present
    read_input: Byte;                           // Contains value of selected option in the window or pressed key
    buffer: array[0..0] of Byte;                // flash buffer
    val: LongWord;
    i:  Word;
    pmax_version: String[8];
    // pmax_version: PString;
    file_version: String[8];
    f: File;

function convert_bool(value: Boolean): String;
begin
    if value then result:= 'Yes'
    else result:= 'No';    
end;


procedure remember_input(var remember: Byte);
begin
    if ((read_input <> XESC) and (read_input <> XTAB)) then
    begin
        remember := read_input;
    end
    else if (read_input = XESC) then
    begin
        status_close:= XESC;
    end;    
end;

procedure FlashSaveConfig;
begin
    win_progress:=WOpen(9, 10, 22, 7, WOFF);
    WOrn(win_progress, WPTOP, 2, 'Progress');
    GProg(win_progress, 1, 2, 0);
    WPrint(win_progress, 2, 3, WOFF, 'Backing up');
    GetMem(buffer, pmax_config.pagesize * 4);
    WOrn(win_progress, WPTOP, WPRGT, IntToStr(pmax_config.pagesize));
    for i:= 2 to pmax_config.pagesize - 1 do
    begin
        buffer[i]:=PMAX_ReadFlash(i, 0);
        GProg(win_progress, 1, 2, (i * 100) div pmax_config.pagesize + 1);
        WOrn(win_progress, WPBOT, WPRGT, IntToStr(i));
    end;

    PMAX_WriteProtect(false);
    // reset variable for failed attempts
    read_input:=0;
    WPrint(win_progress, 2, 3, WOFF, 'Erasing page 0      ');
    PMAX_ErasePage(0);
    // PMAX_ErasePage;
    GProg(win_progress, 1, 2, 0);
    WPrint(win_progress, 2, 3, WOFF, 'Writing             ');
    PMAX_FetchFlashAddress; // fetch value to flash1 and flash2 variables; 
    buffer[0]:= flash1;
    buffer[1]:= flash2;
    for i:=0 to pmax_config.pagesize - 1 do
    begin
        GProg(win_progress, 1, 2, (i * 100) div pmax_config.pagesize + 1);
        PMAX_WriteFlash(i, 0, buffer[i]);
    end;
    
    WPrint(win_progress, 2, 3, WOFF, 'Verifying           ');
    for i:=0 to pmax_config.pagesize - 1 do
    begin
        GProg(win_progress, 1, 2, (i * 100) div pmax_config.pagesize + 1);
        val:=PMAX_ReadFlash(i, 0);
        if val <> buffer[i] then
        begin
            WPrint(win_progress, 2, 3, WOFF, 'Failed at page      ');
            WPrint(win_progress, 17, 3, WOFF, IntToStr(i));
            read_input:=1;
            break;
        end;
    end;
    if read_input = 0 then
    begin
        WPrint(win_progress, 2, 3, WOFF, 'Completed           ');
    end;
    PMAX_WriteProtect(true);

    FreeMem(buffer, pmax_config.pagesize * 4);
    WPrint(win_progress, WPCNT, 5, WON, '[  OK  ]');
    read_input:= WaitKCX(WOFF);
    WClose(win_progress);
end;


procedure menu_about;
var
    win_about: Byte;

begin
    win_about:=WOpen(4, 5, 31, 12, WOFF);
    WOrn(win_about, WPTOP, WPLFT, 'About');
    WPrint(win_about, WPCNT, 2, WOFF, version);
    WPrint(win_about, WPCNT, 4, WOFF, '(c) 2023 MADRAFi');
    WPrint(win_about, WPCNT, 5, WOFF, 'Based on flash code by Foft');
    WPrint(win_about, WPCNT, 6, WOFF, 'Developped using MAD-Pascal');
    WPrint(win_about, WPCNT, 7, WOFF, 'and Windows Library');
    WPrint(win_about, WPCNT, 9, WON, '[  OK  ]');

    WaitKCX(WOFF);
    WClose(win_about);
end;
// procedure read_dir(drive: String[3]);



procedure menu_flash;
var
    // win_flash: Byte;
    info : TSearchRec;
    pmax_right: String[5];
    file_right: String[5];

    function VerifyCore(filename : String[15]): Boolean;
    begin
        assign(f, filename);
        reset(f, 1);
        blockread(f, file_version[1], 8);
        close(f);
        file_version[0]:= #8;
        pmax_right:= strRight(pmax_version,5);
        file_right:= strRight(file_version,5);
        // WPrint(win_progress, 2, 6, WON, pmax_right);
        // WPrint(win_progress, 2, 7, WON, file_right);
        // if strRight(pmax_version,5) <> strRight(file_version,5) then
        if pmax_right <> file_right then
        begin
            // WPrint(win_progress, 2, 8, WON, 'different');
            if pmax_version[6] <> file_version[6] then
            begin
                // WPrint(win_progress, 2, 9, WON, '6 char diff');
                if (pmax_version[4] = file_version[4]) then
                    WPrint(win_progress, 2, 8, WOFF, 'Core for different FPGA!');
                Result:= false;
            end
            else begin
                if pmax_version[5] = file_version[5] then
                begin
                    // WPrint(win_progress, 2, 10, WON, '5 char =');
                    WPrint(win_progress, 2, 8, WOFF, 'Rewiring maybe required');
                    Result:= true;
                end
                else begin
                    // WPrint(win_progress, 2, 10, WON, '5 char diff');
                    Result:=false;
                end;
            end;
        end
        else begin
            // WPrint(win_progress, 2, 8, WON, 'file and core same');
            Result:= true;
        end;
    end;
    procedure UpdateCore(filename: String[15]);
    begin
        WClr(win_progress);
        WPrint(win_progress, 2, 2, WOFF, 'File:');
        WPrint(win_progress, 8, 2, WOFF, filename);
        if FileExists(filename) then
        begin
            if VerifyCore(filename) then
            begin
                // WPrint(win_progress, 2, 4, WOFF, 'File version:');
                // WPrint(win_progress, 16, 4, WOFF, file_version);
                // WPrint(win_progress, 2, 5, WOFF, 'Core version:');
                // WPrint(win_progress, 16, 5, WOFF, pmax_version);
                WPrint(win_progress, 2, 3, WOFF, 'File ver:');
                WPrint(win_progress, 11, 3, WOFF, file_version);
                WPrint(win_progress, 2, 4, WOFF, 'Core ver:');
                WPrint(win_progress, 11, 4, WOFF, pmax_version);
                WPrint(win_progress, WPCNT, 9, WOFF, '   Please wait   ');
                WPrint(win_progress, WPCNT, 10, WON, ' DO NOT TURN OFF ');

                //   flash1:= PMAX_ReadFlash(0, 0);
                //   flash2:= PMAX_ReadFlash(1, 0);
                val:=0;
                repeat
                    i:=((val * 100) div pmax_config.max_address);
                    WPrint(win_progress, 1, 6, WOFF, ' (');
                    GProg(win_progress, 3, 6, i);
                    WPrint(win_progress, 23, 6, WOFF, ') ');
                    WPrint(win_progress, WPCNT, 7, WOFF, HexStr(val,5));
                    Delay(10);
                Inc(val, 256);
                until val > pmax_config.max_address;
            end
            else begin
                WPrint(win_progress, WPCNT, 4, WON, '     Invalid Core     ');
            end;
        end
        else begin
            WPrint(win_progress, WPCNT, 4, WON, '     File not found!     ');

            // if FindFirst('D:*.BIN', faAnyFile, info) = 0 then
            // begin
            //     i:= 1;
            //     repeat
            //         WPrint(win_progress, 2, 3 + i, WOFF, Trim(info.Name));
            //         Inc(i);
            //     until FindNext(info) <> 0;
            //     FindClose(info);
            // end;
        end;
    end;
begin
    win_progress:= WOpen(7, 4, 26, 13, WOFF);
    WOrn(win_progress, WPTOP, WPLFT, 'CORE Flashing');
    WPrint(win_progress, 2,1,WOFF,'Read file');
    UpdateCore('D:CORE.BIN');
    WaitKCX(WOFF);
    UpdateCore('D:CORE1_27.BIN');
    // WaitKCX(WOFF);
    // UpdateCore('D:CORE1_23.BIN');
    WPrint(win_progress, WPCNT, 9, WOFF, '                 ');
    WPrint(win_progress, WPCNT, 10, WOFF, '                 ');
    WPrint(win_progress, WPCNT, 11, WON, '[  OK  ]');
    WaitKCX(WOFF);
    WClose(win_progress);
end;

// function menu_file: Boolean;


// const
//     list_drives: array[0..7] of string = ('D1:', 'D2:', 'D3:', 'D4:', 'D5:', 'D6:', 'D7:', 'D8:');
//     buttons : array[0..1] of string = ('[  OK  ]', '[Cancel]');
    
//     FILENAME_SIZE = 12;

// var
//     win_file: Byte;
//     // list_files: array[0..9] of string = ('FILE.XEX', 'FILE2.TXT', 'FILE3.DAT', 'CORE.BIN', 'FILE555.BIN', 'FILE6.BIN', 'FILE77.BIN', 'FILE8.BIN', 'FILE999.BIN', 'FILE101010.BIN');
//     list_files: array[0..128] of string[FILENAME_SIZE];
//     count_files: Byte = 0;
//     selected_drive: Byte;
//     read_file: Byte;
//     selected_file: String[FILENAME_SIZE];
//     selected_list: Byte;
//     // read_drive, read_list: Byte;
    
//     tmp, i: Byte;    

// procedure read_dir;

// var
//     info : TSearchRec;
//     i: Byte;
//     // s: String[3];

// begin
//     // WOrn(win_file, WPBOT, WPRGT, CHBALL);
//     WOrn(win_file, WPBOT, WPRGT, ' O ');
//     if FindFirst(Concat(list_drives[selected_drive - 1],'*.BIN'), faAnyFile, info) = 0 then
//     // if FindFirst('D:*.BIN', faAnyFile, info) = 0 then
//     begin
//         i:= 1; // 0
//         repeat
//             // s:= ' O ';
//             // WOrn(win_file, WPBOT, WPRGT, CHO_L);
//             WOrn(win_file, WPBOT, WPRGT, ' . ');
//             list_files[i]:= Trim(info.Name);
//             Inc(i);
//             // WOrn(win_file, WPBOT, WPRGT, CHBALL);
//             WOrn(win_file, WPBOT, WPRGT, ' O ');
//         until FindNext(info) <> 0;
//         FindClose(info);
//         count_files:= i - 1;
//     end;
//     WOrn(win_file, WPBOT, WPRGT, '   ');
// end;

// begin
//     Result:= false;
//     selected_drive:=1;
//     selected_list:=1;
    
//     win_file:=WOpen(5, 4, 30, 16, WOFF);
//     WOrn(win_file, WPTOP, WPLFT, 'Choose a file');
//     WOrn(win_file, WPBOT, WPRGT, '   ');

//     read_dir;

//     if (count_files > 0) then
//     begin
//         selected_file:= list_files[selected_list - 1];
//         tmp:= Length(selected_file);
//         SetLength(selected_file, FILENAME_SIZE);
//         FillChar(@selected_file[tmp + 1], FILENAME_SIZE - tmp, CHSPACE );
//     end
//     else selected_file:='            ';
//     WPrint(win_file, 2, 2, WOFF, 'File:');
//     // WDiv(win_file, 3, WON);

//     WPrint(win_file, 21, 4, WOFF, 'Drive:');
//     GCombo(win_file, 21, 5, GDISP, selected_drive, 8, list_drives);
    
//     // WPrint(win_file, 2, 4, WOFF, 'List:');
//     // if count_files > 0 then 
//     //     GList(win_file, 2, 5, GDISP, selected_list, 8, count_files, list_files);

//     GButton(win_file, 19, 11, GVERT, GDISP, 2, buttons);
    
//     repeat
//         // file
//         read_input:= GInput(win_file, 8, 2, GFILE, 12, selected_file);
//         // if (read_input <> XESC) and (count_files > 0) then
//         // begin
//         //     for i:=0 to count_files - 1 do
//         //     begin
//         //         if list_files[i] = Trim(selected_file) then
//         //         begin
//         //             selected_list:= i + 1;
//         //             GList(win_file, 2, 5, GDISP, selected_list, 8, count_files, list_files);
//         //         end;
//         //     end; 
//         // end;

//         // Drives combo
//         read_input:= GCombo(win_file, 21, 5, GEDIT, selected_drive, 8, list_drives);
//         if (read_input <> XESC) then
//         begin
//             selected_drive := read_input;
//         end
//         else if (read_input = XESC) then
//         begin
//             status_close:= XESC;
//             break;
//         end;
        
//         GCombo(win_file, 21, 5, GDISP, selected_drive, 8, list_drives);

//         // Files List
//         // if (count_files > 0) then 
//         // begin
//         //     read_input:= GList(win_file, 2, 5, GEDIT, selected_list, 8, count_files, list_files);
//         //     if (read_input <> XESC) then
//         //     begin
//         //         selected_list := read_input;
//         //         selected_file:= list_files[selected_list - 1];
//         //         tmp:= Length(selected_file);
//         //         SetLength(selected_file, FILENAME_SIZE);
//         //         FillChar(@selected_file[tmp + 1], FILENAME_SIZE - tmp, CHSPACE );
//         //         WPrint(win_file, 8, 2, WOFF, selected_file);
//         //     end
//         //     else if (read_input = XESC) then
//         //     begin
//         //         status_close:= XESC;
//         //         break;
//         //     end;
            
//         //     GList(win_file, 2, 5, GDISP, selected_list, 8, count_files, list_files);
//         // end;

//         // Buttons to confirm
//         status_close := GButton(win_file, 19, 11, GVERT, GEDIT, 2, buttons);    
//         GButton(win_file, 19, 11, GVERT, GDISP, 2, buttons);

//     until status_close <> XTAB;

//     if status_close = 1 then
//     begin
//         Result:=true;
//         GAlert(Concat(Concat('Processing...', list_drives[selected_drive - 1]), selected_file));
//     end;

//       WClose(win_file);

// end;

procedure menu_reboot;
begin
    if PMAX_present then PMAX_EnableConfig(false);
    Poke(580, 1);
    // asm {
	// 	;lda:cmp:req 20
	// 	sei
	// 	mva #0 NMIEN
	// 	mva port_b D301
	// 	jmp ($fffc)
    // };
end;

function menu_mode: Boolean;

const
    core_option: array[0..2] of string = ('Mono', 'Stereo', 'Quad');

    BUTTONS_POSX = 4; BUTTONS_POSY = 7;
    OPTION_POSX = 2; OPTION_POSY = 3;
    ENABLE_POSX = 13; ENABLE_POSY = 3;

var
    win_mode: Byte;

    // selected_sid, selected_psg, selected_covox: Byte;
    // read_sid, read_psg, read_covox: Byte;

    selected_option: Byte;
    // read_option: Byte;

    // status_close: Byte;

begin
    Result:= false;
    status_close:= 0;
    // selected_option:= pmax_config.mode_pokey;
    // selected_sid:= Byte(pmax_config.mode_sid);
    // selected_psg:= Byte(pmax_config.mode_psg);
    // selected_covox:= Byte(pmax_config.mode_covox);

    win_mode:=WOpen(8, 3, 24, 10, WOFF);
    WOrn(win_mode, WPTOP, WPLFT, ' MODE ');

    WPrint(win_mode, OPTION_POSX, OPTION_POSY - 1, WOFF, 'Option:');
    GRadio(win_mode, OPTION_POSX, OPTION_POSY, GVERT, GDISP, pmax_config.mode_pokey, Length(core_option), core_option);

    WPrint(win_mode, ENABLE_POSX, ENABLE_POSY - 1, WOFF, 'Enable:');
    WPrint(win_mode, ENABLE_POSX + 4, ENABLE_POSY, WOFF, 'SID');
    WPrint(win_mode, ENABLE_POSX + 4, ENABLE_POSY + 1, WOFF, 'PSG');
    WPrint(win_mode, ENABLE_POSX + 4, ENABLE_POSY + 2, WOFF, 'Covox');

    GCheck(win_mode, ENABLE_POSX, ENABLE_POSY, GDISP, pmax_config.mode_sid);
    GCheck(win_mode, ENABLE_POSX, ENABLE_POSY + 1, GDISP, pmax_config.mode_psg);
    GCheck(win_mode, ENABLE_POSX, ENABLE_POSY + 2, GDISP, pmax_config.mode_covox);

    GButton(win_mode, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GDISP, 2, str_buttons_accept);

    repeat

        // pokey option
        read_input:= GRadio(win_mode, OPTION_POSX, OPTION_POSY, GVERT, GEDIT, pmax_config.mode_pokey, Length(core_option), core_option);
        remember_input(pmax_config.mode_pokey);
        if status_close = XESC then break;
        
        GRadio(win_mode, OPTION_POSX, OPTION_POSY, GVERT, GDISP, pmax_config.mode_pokey, Length(core_option), core_option);
        
        // enable sid
        read_input:= GCheck(win_mode, ENABLE_POSX, ENABLE_POSY, GEDIT, pmax_config.mode_sid);
        remember_input(pmax_config.mode_sid);
        if status_close = XESC then break;
        GCheck(win_mode, ENABLE_POSX, ENABLE_POSY, GDISP, pmax_config.mode_sid);

        // enable psg
        read_input:= GCheck(win_mode, ENABLE_POSX, ENABLE_POSY + 1, GEDIT, pmax_config.mode_psg);
        remember_input(pmax_config.mode_psg);
        if status_close = XESC then break;
        GCheck(win_mode, ENABLE_POSX, ENABLE_POSY + 1, GDISP, pmax_config.mode_psg);

        // enable covox
        read_input:= GCheck(win_mode, ENABLE_POSX, ENABLE_POSY + 2, GEDIT, pmax_config.mode_covox);
        remember_input(pmax_config.mode_covox);
        if status_close = XESC then break;
        GCheck(win_mode, ENABLE_POSX, ENABLE_POSY + 2, GDISP, pmax_config.mode_covox);
 
        // Buttons to confirm
        // if status_close <> XESC then
        // begin
            status_close := GButton(win_mode, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GEDIT, 2, str_buttons_accept);    
            GButton(win_mode, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GDISP, 2, str_buttons_accept);
        // end;
    until status_close <> XTAB;

    if status_close = 1 then
    begin
        Result:=true;
        if GConfirm(string_confirm) then
        begin
            PMAX_WriteConfig;
            if PMAX_isFlashPresent then
            begin
                FlashSaveConfig;
            end;
        end;
    end;

    WClose(win_mode);
end;

function menu_core: Boolean;

const
    core_mono: array[0..1] of string = ('Left Only', 'Both Channels');
    core_divide: array[0..3] of string = (' 1 ', ' 2 ', ' 4 ', ' 8 ');
    core_phi: array[0..1] of string = ('NTSC (4/7)', 'PAL (5/9)');

    BUTTONS_POSX = 16; BUTTONS_POSY = 16;
    MONO_POSX = 2; MONO_POSY = 3;
    PHI_POSX = 19; PHI_POSY = 3;
    DIV_POSX = 15; DIV_POSY = 8;
    GTIA_POSX = 23; GTIA_POSY = 8;
    OUT_POSX = 29; OUT_POSY = 8;


var
    win_core: Byte;

    // selected_out1, selected_out2, selected_out3, selected_out4, selected_out5: Byte;
    // read_out1, read_out2, read_out3, read_out4, read_out5: Byte;

    // selected_gtia1, selected_gtia2, selected_gtia3, selected_gtia4: Byte;
    // read_gtia1, read_gtia2, read_gtia3, read_gtia4: Byte;

    // selected_div1, selected_div2, selected_div3, selected_div4: Byte;
    // read_div1, read_div2, read_div3, read_div4: Byte;

    // selected_mono, selected_phi: Byte;
    // read_mono, read_phi: Byte;

    // status_close: Byte;

begin
    Result:= false;
    status_close:= 0;
    
    // selected_mono:=pmax_config.mode_mono;
    // selected_phi:=pmax_config.mode_phi;

    // selected_div1:=pmax_config.core_div1;
    // selected_div2:=pmax_config.core_div2;
    // selected_div3:=pmax_config.core_div3;
    // selected_div4:=pmax_config.core_div4;

    // selected_gtia1:=Byte(pmax_config.core_gtia1);
    // selected_gtia2:=Byte(pmax_config.core_gtia2);
    // selected_gtia3:=Byte(pmax_config.core_gtia3);
    // selected_gtia4:=Byte(pmax_config.core_gtia4);

    // selected_out1:=Byte(pmax_config.core_out1);
    // selected_out2:=Byte(pmax_config.core_out2);
    // selected_out3:=Byte(pmax_config.core_out3);
    // selected_out4:=Byte(pmax_config.core_out4);
    // selected_out5:=Byte(pmax_config.core_out5);

    win_core:=WOpen(2, 3, 36, 19, WOFF);
    WOrn(win_core, WPTOP, WPLFT, ' CORE ');
    
    WPrint(win_core, MONO_POSX, MONO_POSY - 1, WOFF, 'Mono:');
    GRadio(win_core, MONO_POSX, MONO_POSY, GVERT, GDISP, pmax_config.mode_mono, Length(core_mono), core_mono);

    WPrint(win_core, PHI_POSX, PHI_POSY - 1, WOFF, 'PHI2->1MHz:');
    GRadio(win_core, PHI_POSX, PHI_POSY, GVERT, GDISP, pmax_config.mode_phi, Length(core_phi), core_phi);

    WPrint(win_core, MONO_POSX , DIV_POSY, WOFF, '1 High L');
    WPrint(win_core, MONO_POSX , DIV_POSY + 1, WOFF, '2 High R');
    WPrint(win_core, MONO_POSX , DIV_POSY + 3, WOFF, '3 Low L');
    WPrint(win_core, MONO_POSX , DIV_POSY + 4, WOFF, '4 Low R');
    WPrint(win_core, MONO_POSX , DIV_POSY + 6, WOFF, '5 SPDIF');

    WPrint(win_core, DIV_POSX - 2, DIV_POSY - 1, WOFF, 'Divide:');

    GCombo(win_core, DIV_POSX, DIV_POSY, GDISP, pmax_config.core_div1, Length(core_divide), core_divide);
    GCombo(win_core, DIV_POSX, DIV_POSY + 1, GDISP, pmax_config.core_div2, Length(core_divide), core_divide);
    GCombo(win_core, DIV_POSX, DIV_POSY + 3, GDISP, pmax_config.core_div3, Length(core_divide), core_divide);
    GCombo(win_core, DIV_POSX, DIV_POSY + 4, GDISP, pmax_config.core_div4, Length(core_divide), core_divide);


    WPrint(win_core, GTIA_POSX - 2, GTIA_POSY - 1, WOFF, 'GTIA:');
    GCheck(win_core, GTIA_POSX, GTIA_POSY, GDISP, pmax_config.core_gtia1);
    GCheck(win_core, GTIA_POSX, GTIA_POSY + 1, GDISP, pmax_config.core_gtia2);
    GCheck(win_core, GTIA_POSX, GTIA_POSY + 3, GDISP, pmax_config.core_gtia3);
    GCheck(win_core, GTIA_POSX, GTIA_POSY + 4, GDISP,  pmax_config.core_gtia4);
    
    WPrint(win_core, OUT_POSX - 2, OUT_POSY - 1, WOFF, 'Output:');
    GCheck(win_core, OUT_POSX, OUT_POSY, GDISP,  pmax_config.core_out1);
    GCheck(win_core, OUT_POSX, OUT_POSY + 1, GDISP,  pmax_config.core_out2);
    GCheck(win_core, OUT_POSX, OUT_POSY + 3, GDISP,  pmax_config.core_out3);
    GCheck(win_core, OUT_POSX, OUT_POSY + 4, GDISP,  pmax_config.core_out4);
    GCheck(win_core, OUT_POSX, OUT_POSY + 6, GDISP,  pmax_config.core_out5);


    GButton(win_core, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GDISP, 2, str_buttons_accept);

    repeat

        // mono
        read_input:= GRadio(win_core, MONO_POSX, MONO_POSY, GVERT, GEDIT, pmax_config.mode_mono, Length(core_mono), core_mono);
        remember_input(pmax_config.mode_mono);
        if status_close = XESC then break;
        GRadio(win_core, MONO_POSX, MONO_POSY, GVERT, GDISP, pmax_config.mode_mono, Length(core_mono), core_mono);

        // phi
        read_input:= GRadio(win_core, PHI_POSX, PHI_POSY, GVERT, GEDIT, pmax_config.mode_phi, Length(core_phi), core_phi);
        remember_input(pmax_config.mode_phi);
        if status_close = XESC then break;
        GRadio(win_core, PHI_POSX, PHI_POSY, GVERT, GDISP, pmax_config.mode_phi, Length(core_phi), core_phi);


        // divider 1
        read_input:= GCombo(win_core, DIV_POSX, DIV_POSY, GEDIT, pmax_config.core_div1, Length(core_divide), core_divide);
        remember_input(pmax_config.core_div1);
        if status_close = XESC then break;
        GCombo(win_core, DIV_POSX, DIV_POSY, GDISP, pmax_config.core_div1, Length(core_divide), core_divide);

        // divider 2
        read_input:= GCombo(win_core, DIV_POSX, DIV_POSY + 1, GEDIT, pmax_config.core_div2, Length(core_divide), core_divide);
        remember_input(pmax_config.core_div2);
        if status_close = XESC then break;
        GCombo(win_core, DIV_POSX, DIV_POSY + 1, GDISP, pmax_config.core_div2, Length(core_divide), core_divide);

        // divider 3
        read_input:= GCombo(win_core, DIV_POSX, DIV_POSY + 3, GEDIT, pmax_config.core_div3, Length(core_divide), core_divide);
        remember_input(pmax_config.core_div3);
        if status_close = XESC then break;
        GCombo(win_core, DIV_POSX, DIV_POSY + 3, GDISP, pmax_config.core_div3, Length(core_divide), core_divide);

        // divider 4
        read_input:= GCombo(win_core, DIV_POSX, DIV_POSY + 4, GEDIT, pmax_config.core_div4, Length(core_divide), core_divide);
        remember_input(pmax_config.core_div4);
        if status_close = XESC then break;
        GCombo(win_core, DIV_POSX, DIV_POSY + 4, GDISP, pmax_config.core_div4, Length(core_divide), core_divide);


        // gtia 1
        read_input:= GCheck(win_core, GTIA_POSX, GTIA_POSY, GEDIT, pmax_config.core_gtia1);
        remember_input(pmax_config.core_gtia1);
        if status_close = XESC then break;
        GCheck(win_core, GTIA_POSX, GTIA_POSY, GDISP, pmax_config.core_gtia1);

        // gtia 2
        read_input:= GCheck(win_core, GTIA_POSX, GTIA_POSY + 1, GEDIT, pmax_config.core_gtia2);
        remember_input(pmax_config.core_gtia2);
        if status_close = XESC then break;
        GCheck(win_core, GTIA_POSX, GTIA_POSY + 1, GDISP, pmax_config.core_gtia2);

        // gtia 3
        read_input:= GCheck(win_core, GTIA_POSX, GTIA_POSY + 3, GEDIT, pmax_config.core_gtia3);
        remember_input(pmax_config.core_gtia3);
        if status_close = XESC then break;
        GCheck(win_core, GTIA_POSX, GTIA_POSY + 3, GDISP, pmax_config.core_gtia3);

        // gtia 4
        read_input:= GCheck(win_core, GTIA_POSX, GTIA_POSY + 4, GEDIT, pmax_config.core_gtia4);
        remember_input(pmax_config.core_gtia4);
        if status_close = XESC then break;
        GCheck(win_core, GTIA_POSX, GTIA_POSY + 4, GDISP, pmax_config.core_gtia4);

        // output 1
        read_input:= GCheck(win_core, OUT_POSX, OUT_POSY, GEDIT, pmax_config.core_out1);
        remember_input(pmax_config.core_out1);
        if status_close = XESC then break;
        GCheck(win_core, OUT_POSX, OUT_POSY, GDISP, pmax_config.core_out1);

        // output 2
        read_input:= GCheck(win_core, OUT_POSX, OUT_POSY + 1, GEDIT, pmax_config.core_out2);
        remember_input(pmax_config.core_out2);
        if status_close = XESC then break;
        GCheck(win_core, GTIA_POSX, OUT_POSY + 1, GDISP, pmax_config.core_out2);

        // output 3
        read_input:= GCheck(win_core, OUT_POSX, OUT_POSY + 3, GEDIT, pmax_config.core_out3);
        remember_input(pmax_config.core_out3);
        if status_close = XESC then break;
        GCheck(win_core, GTIA_POSX, OUT_POSY + 3, GDISP, pmax_config.core_out3);

        // output 4
        read_input:= GCheck(win_core, OUT_POSX, OUT_POSY + 4, GEDIT, pmax_config.core_out4);
        remember_input(pmax_config.core_out4);
        if status_close = XESC then break;
        GCheck(win_core, OUT_POSX, OUT_POSY + 4, GDISP, pmax_config.core_out4);

        // output 5
        read_input:= GCheck(win_core, OUT_POSX, OUT_POSY + 6, GEDIT, pmax_config.core_out5);
        remember_input(pmax_config.core_out5);
        if status_close = XESC then break;
        GCheck(win_core, OUT_POSX, OUT_POSY + 6, GDISP, pmax_config.core_out5);

        // Buttons to confirm
        status_close := GButton(win_core, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GEDIT, 2, str_buttons_accept);    
        GButton(win_core, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GDISP, 2, str_buttons_accept);

    until status_close <> XTAB;

    if status_close = 1 then
    begin
        Result:=true;
        if GConfirm(string_confirm) then
        begin
            PMAX_WriteConfig;
            if PMAX_isFlashPresent then
            begin
                FlashSaveConfig;
            end;
        end;
    end;

    WClose(win_core);
end;

function menu_pokey: Boolean;
var
    win_pokey: Byte;
    // read_mixing, read_channel, read_irq: Byte;
    // selected_mixing, selected_channel, selected_irq: Byte;
    // status_close: Byte;

const  
    pokey_mixing: array[0..1] of string = ('Non-linear', 'Linear');
    pokey_channel: array[0..1] of string = ('Off', 'On');
    pokey_irq: array[0..1] of string = ('One', 'All');

    BUTTONS_POSX = 12; BUTTONS_POSY = 10;
    MIXING_POSX = 2; MIXING_POSY = 3;
    CHANNEL_POSX = 16; CHANNEL_POSY = 3;
    IRQ_POSX = 2; IRQ_POSY = 7;

begin
    Result:= false;
    status_close:= 0;
    // selected_mixing:= pmax_config.pokey_mixing;
    // selected_channel:= pmax_config.pokey_channel;
    // selected_irq:= pmax_config.pokey_irq;
    
    win_pokey:=WOpen(5, 4, 31, 13, WOFF);
    WOrn(win_pokey, WPTOP, WPLFT, ' POKEY ');
    

    WPrint(win_pokey, MIXING_POSX, MIXING_POSY - 1, WOFF, 'Mixing:');
    GRadio(win_pokey, MIXING_POSX, MIXING_POSY, GVERT, GDISP, pmax_config.pokey_mixing, Length(pokey_mixing), pokey_mixing);

    WPrint(win_pokey, CHANNEL_POSX, CHANNEL_POSY - 1, WOFF, 'Channel mode:');
    GRadio(win_pokey, CHANNEL_POSX, CHANNEL_POSY, GVERT, GDISP, pmax_config.pokey_channel, Length(pokey_channel), pokey_channel);

    WPrint(win_pokey, IRQ_POSX, IRQ_POSY - 1, WOFF, 'IRQ:');
    GRadio(win_pokey, IRQ_POSX, IRQ_POSY, GVERT, GDISP, pmax_config.pokey_irq, Length(pokey_irq), pokey_irq);

    GButton(win_pokey, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GDISP, 2, str_buttons_accept);

    repeat

        // mixing
        read_input:= GRadio(win_pokey, MIXING_POSX, MIXING_POSY, GVERT, GEDIT, pmax_config.pokey_mixing, Length(pokey_mixing), pokey_mixing);
        remember_input(pmax_config.pokey_mixing);
        if status_close = XESC then break;
        GRadio(win_pokey, MIXING_POSX, MIXING_POSY, GVERT, GDISP, pmax_config.pokey_mixing, Length(pokey_mixing), pokey_mixing);

        // channel
        read_input:= GRadio(win_pokey, CHANNEL_POSX, CHANNEL_POSY, GVERT, GEDIT, pmax_config.pokey_channel, Length(pokey_channel), pokey_channel);
        remember_input(pmax_config.pokey_channel);
        if status_close = XESC then break;
        GRadio(win_pokey, CHANNEL_POSX, CHANNEL_POSY, GVERT, GDISP, pmax_config.pokey_channel, Length(pokey_channel), pokey_channel);

        // irq
        read_input:= GRadio(win_pokey, IRQ_POSX, IRQ_POSY, GVERT, GEDIT, pmax_config.pokey_irq, Length(pokey_irq), pokey_irq);
        remember_input(pmax_config.pokey_irq);
        if status_close = XESC then break;
        GRadio(win_pokey, IRQ_POSX, IRQ_POSY, GVERT, GDISP, pmax_config.pokey_irq, Length(pokey_irq), pokey_irq);


        // Buttons to confirm
        status_close := GButton(win_pokey, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GEDIT, 2, str_buttons_accept);    
        GButton(win_pokey, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GDISP, 2, str_buttons_accept);

    until status_close <> XTAB;

    if status_close = 1 then
    begin
        Result:=true;
        if GConfirm(string_confirm) then
        begin
            PMAX_WriteConfig;
            if PMAX_isFlashPresent then
            begin
                FlashSaveConfig;
            end;
        end;
    end;

    WClose(win_pokey);
end;

function menu_sid: Boolean;
var
    win_sid: Byte;
    // read_sid1, read_sid2: Byte;
    // selected_sid1, selected_sid2: Byte;
    // status_close: Byte;

const  
    sid_options: array[0..2] of string = ('6581', '8580', '8580 Digi');

    BUTTONS_POSX = 12; BUTTONS_POSY = 7;
    SID1_POSX = 2; SID1_POSY = 3;
    SID2_POSX = 15; SID2_POSY = 3;

begin
    Result:= false;
    status_close:= 0;
    // selected_sid1:= pmax_config.sid_1;
    // selected_sid2:= pmax_config.sid_2;
    
    win_sid:=WOpen(5, 5, 30, 10, WOFF);
    WOrn(win_sid, WPTOP, WPLFT, ' SID ');
    

    WPrint(win_sid, SID1_POSX, SID1_POSY - 1, WOFF, 'SID 1:');
    GRadio(win_sid, SID1_POSX, SID1_POSY, GVERT, GDISP, pmax_config.sid_1, Length(sid_options), sid_options);

    WPrint(win_sid, SID2_POSX, SID2_POSY - 1, WOFF, 'SID 2:');
    GRadio(win_sid, SID2_POSX, SID2_POSY, GVERT, GDISP, pmax_config.sid_2, Length(sid_options), sid_options);


    GButton(win_sid, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GDISP, 2, str_buttons_accept);

    repeat

        // sid 1
        read_input:= GRadio(win_sid, SID1_POSX, SID1_POSY, GVERT, GEDIT, pmax_config.sid_1, Length(sid_options), sid_options);
        remember_input(pmax_config.sid_1);
        if status_close = XESC then break;
        GRadio(win_sid, SID1_POSX, SID1_POSY, GVERT, GDISP, pmax_config.sid_1, Length(sid_options), sid_options);

        // sid 2
        read_input:= GRadio(win_sid, SID2_POSX, SID2_POSY, GVERT, GEDIT, pmax_config.sid_2, Length(sid_options), sid_options);
        remember_input(pmax_config.sid_2);
        if status_close = XESC then break;
        GRadio(win_sid, SID2_POSX, SID2_POSY, GVERT, GDISP, pmax_config.sid_2, Length(sid_options), sid_options);

        // Buttons to confirm
        status_close := GButton(win_sid, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GEDIT, 2, str_buttons_accept);    
        GButton(win_sid, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GDISP, 2, str_buttons_accept);

    until status_close <> XTAB;

    if status_close = 1 then
    begin
        Result:=true;
        if GConfirm(string_confirm) then
        begin
            PMAX_WriteConfig;
            if PMAX_isFlashPresent then
            begin
                FlashSaveConfig;
            end;
        end;
    end;

    WClose(win_sid);
end;

function menu_psg: Boolean;
var
    win_psg: Byte;
    // read_freq, read_stereo, read_envelope, read_volume: Byte;
    // selected_freq, selected_stereo, selected_envelope, selected_volume: Byte;
    // status_close: Byte;

const  
    str_psg_freq: array[0..2] of string = ('2 MHz', '1 MHz', 'PHI2');
    str_psg_stereo: array[0..3] of string = ('Mono   (L:ABC R:ABC)', 'Polish (L:AB  R:BC )', 'Czech  (L:AC  R:BC )', 'L / R  (L:111 R:222)');
    str_psg_envelope: array[0..1] of string = ('32 steps', '16 steps');
    str_psg_volume: array[0..3] of string = ('AY Log', 'YM2149 Log 1', 'YM2149 Log 2', 'Linear');

    BUTTONS_POSX = 12; BUTTONS_POSY = 16;
    STEREO_POSX = 2; STEREO_POSY = 2;
    FREQ_POSX = 2; FREQ_POSY = 8;
    ENVEL_POSX = 2; ENVEL_POSY = 13;
    VOL_POSX = 14; VOL_POSY = 8;

begin
    Result:= false;
    status_close:= 0;
    // selected_freq:= pmax_config.psg_freq;
    // selected_stereo:= pmax_config.psg_stereo;
    // selected_envelope:= pmax_config.psg_envelope;
    // selected_volume:= pmax_config.psg_volume;

    win_psg:=WOpen(3, 3, 32, 19, WOFF);
    WOrn(win_psg, WPTOP, WPLFT, ' PSG ');
    

    WPrint(win_psg, STEREO_POSX, STEREO_POSY - 1, WOFF, 'Stereo:');
    GRadio(win_psg, STEREO_POSX, STEREO_POSY, GVERT, GDISP, pmax_config.psg_stereo, Length(str_psg_stereo), str_psg_stereo);

    WPrint(win_psg, FREQ_POSX, FREQ_POSY - 1, WOFF, 'Frequency:');
    GRadio(win_psg, FREQ_POSX, FREQ_POSY, GVERT, GDISP, pmax_config.psg_freq, Length(str_psg_freq), str_psg_freq);

    WPrint(win_psg, ENVEL_POSX, ENVEL_POSY - 1, WOFF, 'Envelope:');
    GRadio(win_psg, ENVEL_POSX, ENVEL_POSY, GVERT, GDISP, pmax_config.psg_envelope, Length(str_psg_envelope), str_psg_envelope);

    WPrint(win_psg, VOL_POSX, VOL_POSY - 1, WOFF, 'Volume:');
    GRadio(win_psg, VOL_POSX, VOL_POSY, GVERT, GDISP, pmax_config.psg_volume, Length(str_psg_volume), str_psg_volume);


    GButton(win_psg, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GDISP, 2, str_buttons_accept);

    repeat

        // stereo
        read_input:= GRadio(win_psg, STEREO_POSX, STEREO_POSY, GVERT, GEDIT, pmax_config.psg_stereo, Length(str_psg_stereo), str_psg_stereo);
        remember_input(pmax_config.psg_stereo);
        if status_close = XESC then break;
        GRadio(win_psg, STEREO_POSX, STEREO_POSY, GVERT, GDISP, pmax_config.psg_stereo, Length(str_psg_stereo), str_psg_stereo);

        // freq
        read_input:= GRadio(win_psg, FREQ_POSX, FREQ_POSY, GVERT, GEDIT, pmax_config.psg_freq, Length(str_psg_freq), str_psg_freq);
        remember_input(pmax_config.psg_freq);
        if status_close = XESC then break;
        GRadio(win_psg, FREQ_POSX, FREQ_POSY, GVERT, GDISP, pmax_config.psg_freq, Length(str_psg_freq), str_psg_freq);

        // envelope
        read_input:= GRadio(win_psg, ENVEL_POSX, ENVEL_POSY, GVERT, GEDIT, pmax_config.psg_envelope, Length(str_psg_envelope), str_psg_envelope);
        remember_input(pmax_config.psg_envelope);
        if status_close = XESC then break;
        GRadio(win_psg, ENVEL_POSX, ENVEL_POSY, GVERT, GDISP, pmax_config.psg_envelope, Length(str_psg_envelope), str_psg_envelope);

        // volume
        read_input:= GRadio(win_psg, VOL_POSX, VOL_POSY, GVERT, GEDIT, pmax_config.psg_volume, Length(str_psg_volume), str_psg_volume);
        remember_input(pmax_config.psg_volume);
        if status_close = XESC then break;
        GRadio(win_psg, VOL_POSX, VOL_POSY, GVERT, GDISP, pmax_config.psg_volume, Length(str_psg_volume), str_psg_volume);
        
        // Buttons to confirm
        status_close := GButton(win_psg, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GEDIT, 2, str_buttons_accept);    
        GButton(win_psg, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GDISP, 2, str_buttons_accept);

    until status_close <> XTAB;

    if status_close = 1 then
    begin
        Result:=true;
        if GConfirm(string_confirm) then
        begin
            PMAX_WriteConfig;
            if PMAX_isFlashPresent then
            begin
                FlashSaveConfig;
            end;
        end;
    end;

    WClose(win_psg);
end;


procedure menu_pokeymax;
var
    win_pokeymax: Byte;
    selected: Byte;
    // status_close: Boolean;
const
    menu_pmax: array[0..2] of string = (' Flash  ', ' Reboot ', ' Exit   ');

begin
    status_close:= 0;
    selected:= 1;
    win_pokeymax:=WOpen(1, 3, 10, 5, WOFF);

    while status_close<>XESC do
    begin
        selected:=WMenu(win_pokeymax, 1, 1, GVERT, WOFF, selected, Length(menu_pmax), menu_pmax);
        case selected of
            1: begin
                    if PMAX_present then
                    begin
                        status_close:= XESC;
                        // menu_file;
                        menu_flash;
                    end;
               end;
            2: menu_reboot;
            3: begin
                    status_end:= true;
                    status_close:= XESC;
               end;
            XESC: status_close:= XESC;
        end;
    end;
    WClose(win_pokeymax);
end;

procedure menu_config;
var
    win_config: Byte;
    selected: Byte;
    // status_close: Boolean;
const
    menu_cfg: array[0..4] of string = (' Mode   ', ' CORE   ', ' Pokey  ', ' SID    ', ' PSG    ');

begin
    selected:= 1;
    status_close:= 0;

    win_config:=WOpen(12, 2, 10, 7, WOFF);

    while status_close<>XESC do
    begin
        selected:=WMenu(win_config, 1, 1, GVERT, WOFF, selected, Length(menu_cfg), menu_cfg);
        case selected of
            1: if PMAX_present then
                begin
                    status_close:= XESC;
                    menu_mode;
                end;        
            2: if PMAX_present then
                begin
                    status_close:= XESC;
                    menu_core;
                end;
            3: if PMAX_present then
                begin
                    status_close:= XESC;
                    menu_pokey;
                end;
            4: if (PMAX_present) then
                begin
                    status_close:= XESC;
                    menu_sid;
                end;
            5: if (PMAX_present) then
                begin
                    status_close:= XESC;
                    menu_psg;
                end;
            XESC: status_close:= XESC;
        end;
    end;
    WClose(win_config);
end;

procedure details;
var
    s_pokey: String;

begin

    if PMAX_present then
    begin
        case PMAX_GetPokeys of
            1: s_pokey:='Mono';
            2: s_pokey:='Stereo';
            4: s_pokey:='Quad';
        end;
        WPrint(win_details, 1, 1, WOFF, 'Core:'); 
        WPrint(win_details, 1, 2, WOFF, 'Pokey:');
        WPrint(win_details, 1, 3, WOFF, 'SID:');
        
        WPrint(win_details, 16, 1, WOFF, 'Flash:');
        WPrint(win_details, 16, 2, WOFF, 'PSG:');
        WPrint(win_details, 16, 3, WOFF, 'Covox:');

        WPrint(win_details, 28, 3, WOFF, 'Sample:');

        WPrint(win_details, 7, 1, WOFF, pmax_version);
        WPrint(win_details, 8, 2, WOFF, s_pokey);
        WPrint(win_details, 8, 3, WOFF, convert_bool(PMAX_isSIDPresent));
        
        WPrint(win_details, 23, 1, WOFF, convert_bool(PMAX_isFlashPresent));
        WPrint(win_details, 23, 2, WOFF, convert_bool(PMAX_isPSGPresent));
        WPrint(win_details, 23, 3, WOFF, convert_bool(PMAX_isCovoxPresent));

        WPrint(win_details, 36, 3, WOFF, convert_bool(PMAX_isSamplePresent));
    end
    else begin
        WPrint(win_details, WPCNT, 2, WON, ' PokeyMAX not found. ');
    end;
end;

begin
    DPoke($230, Word(@display_list));
    WInit;
    WBack($2e);
    status_end:= false;
    selected_menu:= 1;
    pmax_config.mode_pokey:= 1;
    pmax_config.mode_sid:= 0;
    pmax_config.mode_psg:= 0;
    pmax_config.mode_covox:= 0;
    pmax_config.mode_mono:= 1;
    pmax_config.mode_phi:= 1;
    pmax_config.core_div1:= 1;
    pmax_config.core_div2:= 1;
    pmax_config.core_div3:= 1;
    pmax_config.core_div4:= 1;
    pmax_config.core_gtia1:= 0;
    pmax_config.core_gtia2:= 0;
    pmax_config.core_gtia3:= 0;
    pmax_config.core_gtia4:= 0;
    pmax_config.core_out1:= 0;
    pmax_config.core_out2:= 0;
    pmax_config.core_out3:= 0;
    pmax_config.core_out4:= 0;
    pmax_config.core_out5:= 0;
    pmax_config.pokey_mixing:= 1;
    pmax_config.pokey_channel:= 1;
    pmax_config.pokey_irq:= 1;
    pmax_config.psg_freq:= 1;
    pmax_config.psg_stereo:= 1;
    pmax_config.psg_envelope:= 1;
    pmax_config.psg_volume:= 1;
    pmax_config.sid_1:= 1;
    pmax_config.sid_2:= 1;

    win_main:=WOpen(0, 0, 40, 3, WOFF);
    WOrn(win_main, WPTOP, WPCNT, version);
    {$IFDEF DEBUG}
    PMAX_present:= true;
    pmax_config.pagesize:=1024;
    pmax_config.max_address:=$e600;
    pmax_version:= '123M08QP';
    {$ELSE}
    PMAX_present:= PMAX_Detect;

    if PMAX_present then 
    begin
        PMAX_EnableConfig(true);
        PMAX_ReadConfig;
        PMAX_ReadFlashType;
        pmax_version:= PMAX_GetCoreVersion;
    end;
    {$ENDIF}
    win_details:=WOpen(0, 18, 40, 5, WOFF);
    WOrn(win_details, WPTOP, WPLFT, 'Details');
    WOrn(win_details, WPTOP,WPRGT, IntToStr(pmax_config.pagesize));

    while not status_end do
    begin
        details;

        selected_menu:=WMenu(win_main, 1, 1, GHORZ, WON, selected_menu, Length(menu_main), menu_main);
        case selected_menu of
            1: menu_pokeymax;
            2: menu_config;
            3: menu_about;
        end;
        if selected_menu = XESC then
        begin
            selected_menu:= 1;
        end;
    end;
    if PMAX_present then PMAX_EnableConfig(false);
    WClose(win_details);
    WClose(win_main);
    // asm {
    //     jmp $a
    // };
end.
