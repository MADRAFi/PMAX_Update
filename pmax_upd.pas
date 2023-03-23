program pmax_upd;


{$librarypath '../Window Library/src'}
{$librarypath '../PokeyMAX/'}

uses crt, sysutils, misc, a8defines, a8defwin, a8libwin, a8libgadg, a8libmenu, a8libmisc, pm_detect, a8libstr;

const
    version: string = 'PokeyMAX Update v.0.2';
    menu_main: array[0..2] of string = (' PokeyMAX ', ' Config ', ' About ');
    buttons_accept : array[0..1] of string = ('[  OK  ]', '[Cancel]');

var
    win_main, win_details: Byte;
    selected_menu: Byte;
    status_end: Boolean;
    pMAX_present: Boolean = false;




function convert_bool(value: Boolean): String;
begin
    if value then result:= 'Yes'
    else result:= 'No';    
end;

procedure menu_about;
var
    win_about: Byte;

begin
    win_about:=WOpen(5, 5, 30, 12, WOFF);
    WOrn(win_about, WPTOP, WPLFT, 'About');
    WPrint(win_about, WPCNT, 2, WOFF, version);
    WPrint(win_about, WPCNT, 4, WOFF, '(c) 2023 MADRAFi');
    WPrint(win_about, WPCNT, 5, WOFF, 'Flash code by Foft');
    WPrint(win_about, WPCNT, 6, WOFF, 'Developped using');
    WPrint(win_about, WPCNT, 7, WOFF, 'MAD-Pascal and');
    WPrint(win_about, WPCNT, 8, WOFF, 'Windows Library');
    WPrint(win_about, WPCNT, 10, WON, '[  OK  ]');

    WaitKCX(WOFF);
    WClose(win_about);
end;
// procedure read_dir(drive: String[3]);




function menu_file: Boolean;


const
    list_drives: array[0..7] of string = ('D1:', 'D2:', 'D3:', 'D4:', 'D5:', 'D6:', 'D7:', 'D8:');
    buttons : array[0..1] of string = ('[  OK  ]', '[Cancel]');
    
    FILENAME_SIZE = 12;

var
    win_file: Byte;
    // list_files: array[0..9] of string = ('FILE.XEX', 'FILE2.TXT', 'FILE3.DAT', 'CORE.BIN', 'FILE555.BIN', 'FILE6.BIN', 'FILE77.BIN', 'FILE8.BIN', 'FILE999.BIN', 'FILE101010.BIN');
    list_files: array[0..128] of string[12];
    count_files: Byte = 0;
    read_drive, selected_drive: Byte;
    read_file: Byte;
    selected_file: String[FILENAME_SIZE];
    selected_list: Byte;
    read_list: Byte;
    bM: Byte;
    tmp, i: Byte;    

procedure read_dir;

var
    info : TSearchRec;
    i: Byte;
    // s: String[3];

begin
    // WOrn(win_file, WPBOT, WPRGT, CHBALL);
    WOrn(win_file, WPBOT, WPRGT, ' O ');
    if FindFirst(Concat(list_drives[selected_drive - 1],'*.BIN'), faAnyFile, info) = 0 then
    // if FindFirst('D:*.BIN', faAnyFile, info) = 0 then
    begin
        i:= 0;
        repeat
            // s:= ' O ';
            // WOrn(win_file, WPBOT, WPRGT, CHO_L);
            WOrn(win_file, WPBOT, WPRGT, ' . ');
            list_files[i]:= Trim(info.Name);
            Inc(i);
            // WOrn(win_file, WPBOT, WPRGT, CHBALL);
            WOrn(win_file, WPBOT, WPRGT, ' O ');
        until FindNext(info) <> 0;
        FindClose(info);
        count_files:= i - 1;
    end;
    WOrn(win_file, WPBOT, WPRGT, '   ');
end;

begin
    Result:= false;
    selected_drive:=1;
    selected_list:=1;
    // selected_file:='            ';
    
    win_file:=WOpen(5, 4, 30, 16, WOFF);
    WOrn(win_file, WPTOP, WPLFT, 'Choose a file');
    WOrn(win_file, WPBOT, WPRGT, '   ');

    read_dir;

    if (count_files > 0) then
    begin
        selected_file:= list_files[selected_list - 1];
        tmp:= Length(selected_file);
        SetLength(selected_file, FILENAME_SIZE);
        FillChar(@selected_file[tmp + 1], FILENAME_SIZE - tmp, CHSPACE );
    end;
    WPrint(win_file, 2, 2, WOFF, 'File:');
    WDiv(win_file, 3, WON);

    WPrint(win_file, 21, 4, WOFF, 'Drive:');
    GCombo(win_file, 21, 5, GDISP, selected_drive, 8, list_drives);
    
    WPrint(win_file, 2, 4, WOFF, 'List:');
    if count_files > 0 then 
        GList(win_file, 2, 5, GDISP, selected_list, 8, count_files, list_files);

    GButton(win_file, 19, 11, GVERT, GDISP, 2, buttons);
    
    repeat
        // file
        read_file:= GInput(win_file, 8, 2, GFILE, 12, selected_file);
        if (read_file <> XESC) and (count_files > 0) then
        begin
            for i:=0 to count_files - 1 do
            begin
                if list_files[i] = Trim(selected_file) then
                begin
                    selected_list:= i + 1;
                    GList(win_file, 2, 5, GDISP, selected_list, 8, count_files, list_files);
                end;
            end; 
        end;

        // Drives combo
        read_drive:= GCombo(win_file, 21, 5, GEDIT, selected_drive, 8, list_drives);
        if (read_drive <> XESC) then
        begin
            selected_drive := read_drive;
        end;
        GCombo(win_file, 21, 5, GDISP, selected_drive, 8, list_drives);

        // Files List
        if (count_files > 0) then 
        begin
            read_list:= GList(win_file, 2, 5, GEDIT, selected_list, 8, count_files, list_files);
            if (read_list <> XESC) then
            begin
                selected_list := read_list;
                selected_file:= list_files[selected_list - 1];
                tmp:= Length(selected_file);
                SetLength(selected_file, FILENAME_SIZE);
                FillChar(@selected_file[tmp + 1], FILENAME_SIZE - tmp, CHSPACE );
                WPrint(win_file, 8, 2, WOFF, selected_file);
            end;
            GList(win_file, 2, 5, GDISP, selected_list, 8, count_files, list_files);
        end;

        // Buttons to confirm
        bM := GButton(win_file, 19, 11, GVERT, GEDIT, 2, buttons);    
        GButton(win_file, 19, 11, GVERT, GDISP, 2, buttons);

    until bM <> XTAB;

    if bM = 1 then
    begin
        Result:=true;
        GAlert(Concat(Concat('Processing...', list_drives[selected_drive - 1]), selected_file));
    end;

      WClose(win_file);

end;

procedure menu_reboot;
begin
    if pMAX_present then PMAX_EnableConfig(false);
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
    core_option: array[0..2] of string = ('Quad', 'Stereo', 'Mono');

    BUTTONS_POSX = 4; BUTTONS_POSY = 7;
    OPTION_POSX = 2; OPTION_POSY = 3;
    ENABLE_POSX = 13; ENABLE_POSY = 3;

var
    win_mode: Byte;

    selected_sid, selected_psg, selected_covox: Byte;
    read_sid, read_psg, read_covox: Byte;

    selected_option: Byte;
    read_option: Byte;

    status_close: Byte;

begin
    Result:= false;
    status_close:= 0;
    selected_option:= 1;
    selected_sid:= GCON;
    selected_psg:= GCON;
    selected_covox:= GCON;

    win_mode:=WOpen(8, 3, 24, 10, WOFF);
    WOrn(win_mode, WPTOP, WPLFT, ' MODE ');
    

    WPrint(win_mode, OPTION_POSX, OPTION_POSY - 1, WOFF, 'Option:');
    GRadio(win_mode, OPTION_POSX, OPTION_POSY, GVERT, GDISP, selected_option, Length(core_option), core_option);

    WPrint(win_mode, ENABLE_POSX, ENABLE_POSY - 1, WOFF, 'Enable:');
    WPrint(win_mode, ENABLE_POSX + 4, ENABLE_POSY, WOFF, 'SID');
    WPrint(win_mode, ENABLE_POSX + 4, ENABLE_POSY + 1, WOFF, 'PSG');
    WPrint(win_mode, ENABLE_POSX + 4, ENABLE_POSY + 2, WOFF, 'Covox');

    GCheck(win_mode, ENABLE_POSX, ENABLE_POSY, GDISP, selected_sid);
    GCheck(win_mode, ENABLE_POSX, ENABLE_POSY + 1, GDISP, selected_psg);
    GCheck(win_mode, ENABLE_POSX, ENABLE_POSY + 2, GDISP, selected_covox);

    GButton(win_mode, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GDISP, 2, buttons_accept);

    repeat

        // // option
        read_option:= GRadio(win_mode, OPTION_POSX, OPTION_POSY, GVERT, GEDIT, selected_option, Length(core_option), core_option);
        if ((read_option <> XESC) and (read_option <> XTAB)) then
        begin
            selected_option := read_option;
        end
        else if (read_option = XESC) then 
        begin
            status_close:= XESC;
            break;
        end;
        GRadio(win_mode, OPTION_POSX, OPTION_POSY, GVERT, GDISP, selected_option, Length(core_option), core_option);

        // enable sid
        read_sid:= GCheck(win_mode, ENABLE_POSX, ENABLE_POSY, GEDIT, selected_sid);
        if ((read_sid <> XESC) and (read_sid <> XTAB)) then
        begin
            selected_sid := read_sid;
        end
        else if (read_sid = XESC) then 
        begin
            status_close:= XESC;
            break;
        end;
        GCheck(win_mode, ENABLE_POSX, ENABLE_POSY, GDISP, selected_sid);

        // enable psg
        read_psg:= GCheck(win_mode, ENABLE_POSX, ENABLE_POSY + 1, GEDIT, selected_psg);
        if ((read_psg <> XESC) and (read_psg <> XTAB)) then
        begin
            selected_psg := read_psg;
        end
        else if (read_psg = XESC) then 
        begin
            status_close:= XESC;
            break;
        end;
        GCheck(win_mode, ENABLE_POSX, ENABLE_POSY + 1, GDISP, selected_psg);

        // enable covox
        read_covox:= GCheck(win_mode, ENABLE_POSX, ENABLE_POSY + 2, GEDIT, selected_covox);
        if ((read_covox <> XESC) and (read_covox <> XTAB)) then
        begin
            selected_covox := read_covox;
        end
        else if (read_covox = XESC) then 
        begin
            status_close:= XESC;
            break;
        end;
        GCheck(win_mode, ENABLE_POSX, ENABLE_POSY + 2, GDISP, selected_covox);
 
        // Buttons to confirm
        // if status_close <> XESC then
        // begin
            status_close := GButton(win_mode, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GEDIT, 2, buttons_accept);    
            GButton(win_mode, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GDISP, 2, buttons_accept);
        // end;
    until status_close <> XTAB;

    if status_close = 1 then
    begin
        Result:=true;
        GAlert('Processing...');
    end;

    WClose(win_mode);
end;

function menu_core: Boolean;

const
    core_mono: array[0..1] of string = ('Both Channels', 'Left Only');
    core_divide: array[0..3] of string = (' 1 ', ' 2 ', ' 4 ', ' 8 ');
    core_phi: array[0..1] of string = ('PAL (5/9)', 'NTSC (4/7)');

    BUTTONS_POSX = 16; BUTTONS_POSY = 16;
    MONO_POSX = 2; MONO_POSY = 3;
    PHI_POSX = 19; PHI_POSY = 3;
    DIV_POSX = 2; DIV_POSY = 7;
    GTIA_POSX = 2; GTIA_POSY = 10;
    OUT_POSX = 2; OUT_POSY = 12;

var
    win_core: Byte;

    selected_out1, selected_out2, selected_out3, selected_out4, selected_out5: Byte;
    read_out1, read_out2, read_out3, read_out4, read_out5: Byte;

    selected_gtia1, selected_gtia2, selected_gtia3, selected_gtia4: Byte;
    read_gtia1, read_gtia2, read_gtia3, read_gtia4: Byte;

    selected_div1, selected_div2, selected_div3, selected_div4: Byte;
    read_div1, read_div2, read_div3, read_div4: Byte;

    selected_mono, selected_phi: Byte;
    read_mono, read_phi: Byte;

    status_close: Byte;

begin
    Result:= false;
    status_close:= 0;
    // selected_option:= 1;
    // selected_sid:= GCON;
    // selected_psg:= GCON;
    // selected_covox:= GCON;
    selected_mono:=1;
    selected_phi:=1;

    selected_div1:=1;
    selected_div2:=1;
    selected_div3:=1;
    selected_div4:=1;

    selected_gtia1:=1;
    selected_gtia2:=1;
    selected_gtia3:=1;
    selected_gtia4:=1;

    selected_out1:=1;
    selected_out2:=1;
    selected_out3:=1;
    selected_out4:=1;
    selected_out5:=1;

    win_core:=WOpen(3, 3, 34, 19, WOFF);
    WOrn(win_core, WPTOP, WPLFT, ' CORE ');
    
    WPrint(win_core, MONO_POSX, MONO_POSY - 1, WOFF, 'Mono:');
    GRadio(win_core, MONO_POSX, MONO_POSY, GVERT, GDISP, selected_mono, Length(core_mono), core_mono);

    WPrint(win_core, PHI_POSX, PHI_POSY - 1, WOFF, 'PHI2->1MHz:');
    GRadio(win_core, PHI_POSX, PHI_POSY, GVERT, GDISP, selected_phi, Length(core_phi), core_phi);
    // WPrint(win_core, ENABLE_POSX, ENABLE_POSY - 1, WOFF, 'Enable:');
    // WPrint(win_core, ENABLE_POSX + 4, ENABLE_POSY, WOFF, 'SID');
    // WPrint(win_core, ENABLE_POSX + 4, ENABLE_POSY + 1, WOFF, 'PSG');
    // WPrint(win_core, ENABLE_POSX + 4, ENABLE_POSY + 2, WOFF, 'Covox');

    // GCheck(win_core, ENABLE_POSX, ENABLE_POSY, GDISP, selected_sid);
    // GCheck(win_core, ENABLE_POSX, ENABLE_POSY + 1, GDISP, selected_psg);
    // GCheck(win_core, ENABLE_POSX, ENABLE_POSY + 2, GDISP, selected_covox);

    WPrint(win_core, DIV_POSX, DIV_POSY - 1, WOFF, 'Divide:');
    WPrint(win_core, DIV_POSX, DIV_POSY, WOFF, '1:');
    GCombo(win_core, DIV_POSX + 2, DIV_POSY, GDISP, selected_div1, Length(core_divide), core_divide);

    WPrint(win_core, DIV_POSX + 8, DIV_POSY, WOFF, '2:');
    GCombo(win_core, DIV_POSX + 2 + 8, DIV_POSY, GDISP, selected_div2, Length(core_divide), core_divide);

    WPrint(win_core, DIV_POSX + 16, DIV_POSY, WOFF, '3:');
    GCombo(win_core, DIV_POSX + 2 + 16, DIV_POSY, GDISP, selected_div3, Length(core_divide), core_divide);

    WPrint(win_core, DIV_POSX + 24, DIV_POSY, WOFF, '4:');
    GCombo(win_core, DIV_POSX + 2 + 24, DIV_POSY, GDISP, selected_div4, Length(core_divide), core_divide);


    WPrint(win_core, GTIA_POSX, GTIA_POSY - 1, WOFF, 'GTIA:');
    WPrint(win_core, GTIA_POSX, GTIA_POSY, WOFF, '1:');

    WPrint(win_core, GTIA_POSX + 8, GTIA_POSY, WOFF, '2:');
    WPrint(win_core, GTIA_POSX + 16, GTIA_POSY, WOFF, '3:');
    WPrint(win_core, GTIA_POSX + 24, GTIA_POSY, WOFF, '4:');

    WPrint(win_core, OUT_POSX, OUT_POSY - 1, WOFF, 'Output:');
    WPrint(win_core, OUT_POSX, OUT_POSY, WOFF, '1:');

    WPrint(win_core, OUT_POSX + 8, OUT_POSY, WOFF, '2:');
    WPrint(win_core, OUT_POSX + 16, OUT_POSY, WOFF, '3:');
    WPrint(win_core, OUT_POSX + 24, OUT_POSY, WOFF, '4:');
    // WPrint(win_core, GTIA_POSX + 24, GTIA_POSY, WOFF, '4:');


    GButton(win_core, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GDISP, 2, buttons_accept);

    repeat

        // // // option
        // read_option:= GRadio(win_core, OPTION_POSX, OPTION_POSY, GVERT, GEDIT, selected_option, Length(core_option), core_option);
        // if ((read_option <> XESC) and (read_option <> XTAB)) then
        // begin
        //     selected_option := read_option;
        // end;
        // GRadio(win_core, OPTION_POSX, OPTION_POSY, GVERT, GDISP, selected_option, Length(core_option), core_option);

        // // enable sid
        // read_sid:= GCheck(win_core, ENABLE_POSX, ENABLE_POSY, GEDIT, selected_sid);
        // if ((read_sid <> XESC) and (read_sid <> XTAB)) then
        // begin
        //     selected_sid := read_sid;
        // end;
        // GCheck(win_core, ENABLE_POSX, ENABLE_POSY, GDISP, selected_sid);

        // // enable psg
        // read_psg:= GCheck(win_core, ENABLE_POSX, ENABLE_POSY + 1, GEDIT, selected_psg);
        // if ((read_psg <> XESC) and (read_psg <> XTAB)) then
        // begin
        //     selected_psg := read_psg;
        // end;
        // GCheck(win_core, ENABLE_POSX, ENABLE_POSY + 1, GDISP, selected_psg);

        // // enable covox
        // read_covox:= GCheck(win_core, ENABLE_POSX, ENABLE_POSY + 2, GEDIT, selected_covox);
        // if ((read_covox <> XESC) and (read_covox <> XTAB)) then
        // begin
        //     selected_covox := read_covox;
        // end;
        // GCheck(win_core, ENABLE_POSX, ENABLE_POSY + 2, GDISP, selected_covox);

        // // envelope
        // read_envelope:= GRadio(win_core, ENVEL_POSX, ENVEL_POSY, GVERT, GEDIT, selected_envelope, Length(psg_envelope), psg_envelope);
        // if (read_envelope <> XESC) and (read_envelope <> XTAB) then
        // // if (read_envelope <> XESC) then
        // begin
        //     selected_envelope := read_envelope;
        // end;
        // GRadio(win_core, ENVEL_POSX, ENVEL_POSY, GVERT, GDISP, selected_envelope, Length(psg_envelope), psg_envelope);

        // // volume
        // read_volume:= GRadio(win_core, VOL_POSX, VOL_POSY, GVERT, GEDIT, selected_volume, Length(psg_volume), psg_volume);
        // if (read_volume <> XESC) and (read_volume <> XTAB) then
        // // if (read_envelope <> XESC) then
        // begin
        //     selected_volume := read_volume;
        // end;
        // GRadio(win_core, VOL_POSX, VOL_POSY, GVERT, GDISP, selected_volume, Length(psg_volume), psg_volume);
        
        // Buttons to confirm
        status_close := GButton(win_core, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GEDIT, 2, buttons_accept);    
        GButton(win_core, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GDISP, 2, buttons_accept);

    until status_close <> XTAB;

    if status_close = 1 then
    begin
        Result:=true;
        GAlert('Processing...');
    end;

    WClose(win_core);
end;

function menu_pokey: Boolean;
var
    win_pokey: Byte;
    read_mixing, read_channel, read_irq: Byte;
    selected_mixing, selected_channel, selected_irq: Byte;
    status_close: Byte;

const  
    pokey_mixing: array[0..1] of string = ('Non-linear', 'Linear');
    pokey_channel: array[0..1] of string = ('On', 'Off');
    pokey_irq: array[0..1] of string = ('All', 'One');

    BUTTONS_POSX = 12; BUTTONS_POSY = 10;
    MIXING_POSX = 2; MIXING_POSY = 3;
    CHANNEL_POSX = 16; CHANNEL_POSY = 3;
    IRQ_POSX = 2; IRQ_POSY = 7;

begin
    Result:= false;
    status_close:= 0;
    selected_mixing:= 1;
    selected_channel:= 1;
    selected_irq:= 1;
    
    win_pokey:=WOpen(5, 4, 31, 13, WOFF);
    WOrn(win_pokey, WPTOP, WPLFT, ' POKEY ');
    

    WPrint(win_pokey, MIXING_POSX, MIXING_POSY - 1, WOFF, 'Mixing:');
    GRadio(win_pokey, MIXING_POSX, MIXING_POSY, GVERT, GDISP, selected_mixing, Length(pokey_mixing), pokey_mixing);

    WPrint(win_pokey, CHANNEL_POSX, CHANNEL_POSY - 1, WOFF, 'Channel mode:');
    GRadio(win_pokey, CHANNEL_POSX, CHANNEL_POSY, GVERT, GDISP, selected_channel, Length(pokey_channel), pokey_channel);

    WPrint(win_pokey, IRQ_POSX, IRQ_POSY - 1, WOFF, 'IRQ:');
    GRadio(win_pokey, IRQ_POSX, IRQ_POSY, GVERT, GDISP, selected_irq, Length(pokey_irq), pokey_irq);

    GButton(win_pokey, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GDISP, 2, buttons_accept);

    repeat

        // mixing
        read_mixing:= GRadio(win_pokey, MIXING_POSX, MIXING_POSY, GVERT, GEDIT, selected_mixing, Length(pokey_mixing), pokey_mixing);
        if ((read_mixing <> XESC) and (read_mixing <> XTAB)) then
        begin
            selected_mixing := read_mixing;
        end
        else if (read_mixing = XESC) then
        begin
            status_close:= XESC;
            break;
        end;
        GRadio(win_pokey, MIXING_POSX, MIXING_POSY, GVERT, GDISP, selected_mixing, Length(pokey_mixing), pokey_mixing);

        // channel
        read_channel:= GRadio(win_pokey, CHANNEL_POSX, CHANNEL_POSY, GVERT, GEDIT, selected_channel, Length(pokey_channel), pokey_channel);
        if ((read_channel <> XESC) and (read_channel <> XTAB)) then
        begin
            selected_channel := read_channel;
        end
        else if (read_channel = XESC) then
        begin
            status_close:= XESC;
            break;
        end;
        GRadio(win_pokey, CHANNEL_POSX, CHANNEL_POSY, GVERT, GDISP, selected_channel, Length(pokey_channel), pokey_channel);

        // irq
        read_irq:= GRadio(win_pokey, IRQ_POSX, IRQ_POSY, GVERT, GEDIT, selected_irq, Length(pokey_irq), pokey_irq);
        if ((read_irq <> XESC) and (read_irq <> XTAB)) then
        begin
            selected_irq := read_irq;
        end
        else if (read_irq = XESC) then
        begin
            status_close:= XESC;
            break;
        end;
        GRadio(win_pokey, IRQ_POSX, IRQ_POSY, GVERT, GDISP, selected_irq, Length(pokey_irq), pokey_irq);


        // Buttons to confirm
        status_close := GButton(win_pokey, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GEDIT, 2, buttons_accept);    
        GButton(win_pokey, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GDISP, 2, buttons_accept);

    until status_close <> XTAB;

    if status_close = 1 then
    begin
        Result:=true;
        GAlert('Processing...');
    end;

    WClose(win_pokey);
end;

function menu_sid: Boolean;
var
    win_sid: Byte;
    read_sid1, read_sid2: Byte;
    selected_sid1, selected_sid2: Byte;
    status_close: Byte;

const  
    sid_options: array[0..2] of string = ('8580', '6581', '8580 Digi');

    BUTTONS_POSX = 12; BUTTONS_POSY = 7;
    SID1_POSX = 2; SID1_POSY = 3;
    SID2_POSX = 15; SID2_POSY = 3;

begin
    Result:= false;
    status_close:= 0;
    selected_sid1:= 1;
    selected_sid2:= 1;
    
    win_sid:=WOpen(5, 5, 30, 10, WOFF);
    WOrn(win_sid, WPTOP, WPLFT, ' SID ');
    

    WPrint(win_sid, SID1_POSX, SID1_POSY - 1, WOFF, 'SID 1:');
    GRadio(win_sid, SID1_POSX, SID1_POSY, GVERT, GDISP, selected_sid1, Length(sid_options), sid_options);

    WPrint(win_sid, SID2_POSX, SID2_POSY - 1, WOFF, 'SID 2:');
    GRadio(win_sid, SID2_POSX, SID2_POSY, GVERT, GDISP, selected_sid2, Length(sid_options), sid_options);


    GButton(win_sid, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GDISP, 2, buttons_accept);

    repeat

        // sid 1
        read_sid1:= GRadio(win_sid, SID1_POSX, SID1_POSY, GVERT, GEDIT, selected_sid1, Length(sid_options), sid_options);
        if ((read_sid1 <> XESC) and (read_sid1 <> XTAB)) then
        begin
            selected_sid1 := read_sid1;
        end
        else if (read_sid1 = XESC) then
        begin
            status_close:= XESC;
            break;
        end;
        GRadio(win_sid, SID1_POSX, SID1_POSY, GVERT, GDISP, selected_sid1, Length(sid_options), sid_options);

        // sid 2
        read_sid2:= GRadio(win_sid, SID2_POSX, SID2_POSY, GVERT, GEDIT, selected_sid2, Length(sid_options), sid_options);
        if ((read_sid2 <> XESC) and (read_sid2 <> XTAB)) then
        begin
            selected_sid2 := read_sid2;
        end
        else if (read_sid2 = XESC) then
        begin
            status_close:= XESC;
            break;
        end;
        GRadio(win_sid, SID2_POSX, SID2_POSY, GVERT, GDISP, selected_sid2, Length(sid_options), sid_options);

        // Buttons to confirm
        status_close := GButton(win_sid, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GEDIT, 2, buttons_accept);    
        GButton(win_sid, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GDISP, 2, buttons_accept);

    until status_close <> XTAB;

    if status_close = 1 then
    begin
        Result:=true;
        GAlert('Processing...');
    end;

    WClose(win_sid);
end;

function menu_psg: Boolean;
var
    win_psg: Byte;
    read_freq, read_stereo, read_envelope, read_volume: Byte;
    selected_freq, selected_stereo, selected_envelope, selected_volume: Byte;
    status_close: Byte;

const  
    psg_freq: array[0..2] of string = ('2 MHz', '1 MHz', 'PHI2');
    psg_stereo: array[0..3] of string = ('Mono   (L:ABC R:ABC)', 'Polish (L:AB  R:BC )', 'Czech  (L:AC  R:BC )', 'L / R  (L:111 R:222)');
    psg_envelope: array[0..1] of string = ('16 steps', '32 steps');
    psg_volume: array[0..1] of string = ('Linear', 'Log');

    BUTTONS_POSX = 12; BUTTONS_POSY = 16;
    STEREO_POSX = 2; STEREO_POSY = 2;
    FREQ_POSX = 2; FREQ_POSY = 8;
    ENVEL_POSX = 15; ENVEL_POSY = 8;
    VOL_POSX = 2; VOL_POSY = 13;

begin
    Result:= false;
    status_close:= 0;
    selected_freq:= 1;
    selected_stereo:= 1;
    selected_envelope:= 1;
    selected_volume:= 1;

    win_psg:=WOpen(5, 3, 30, 19, WOFF);
    WOrn(win_psg, WPTOP, WPLFT, ' PSG ');
    

    WPrint(win_psg, STEREO_POSX, STEREO_POSY - 1, WOFF, 'Stereo:');
    GRadio(win_psg, STEREO_POSX, STEREO_POSY, GVERT, GDISP, selected_stereo, Length(psg_stereo), psg_stereo);

    WPrint(win_psg, FREQ_POSX, FREQ_POSY - 1, WOFF, 'Frequency:');
    GRadio(win_psg, FREQ_POSX, FREQ_POSY, GVERT, GDISP, selected_freq, Length(psg_freq), psg_freq);

    WPrint(win_psg, ENVEL_POSX, ENVEL_POSY - 1, WOFF, 'Envelope:');
    GRadio(win_psg, ENVEL_POSX, ENVEL_POSY, GVERT, GDISP, selected_envelope, Length(psg_envelope), psg_envelope);

    WPrint(win_psg, VOL_POSX, VOL_POSY - 1, WOFF, 'Volume:');
    GRadio(win_psg, VOL_POSX, VOL_POSY, GVERT, GDISP, selected_volume, Length(psg_envelope), psg_volume);


    GButton(win_psg, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GDISP, 2, buttons_accept);

    repeat

        // stereo
        read_stereo:= GRadio(win_psg, STEREO_POSX, STEREO_POSY, GVERT, GEDIT, selected_stereo, Length(psg_stereo), psg_stereo);
        if ((read_stereo <> XESC) and (read_stereo <> XTAB)) then
        begin
            selected_stereo := read_stereo;
        end
        else if (read_stereo = XESC) then
        begin
            status_close:= XESC;
            break;
        end;
        GRadio(win_psg, STEREO_POSX, STEREO_POSY, GVERT, GDISP, selected_stereo, Length(psg_stereo), psg_stereo);

        // freq
        read_freq:= GRadio(win_psg, FREQ_POSX, FREQ_POSY, GVERT, GEDIT, selected_freq, Length(psg_freq), psg_freq);
        if ((read_freq <> XESC) and (read_freq <> XTAB)) then
        begin
            selected_freq := read_freq;
        end
        else if (read_freq = XESC) then
        begin
            status_close:= XESC;
            break;
        end;
        GRadio(win_psg, FREQ_POSX, FREQ_POSY, GVERT, GDISP, selected_freq, Length(psg_freq), psg_freq);

        // envelope
        read_envelope:= GRadio(win_psg, ENVEL_POSX, ENVEL_POSY, GVERT, GEDIT, selected_envelope, Length(psg_envelope), psg_envelope);
        if ((read_envelope <> XESC) and (read_envelope <> XTAB)) then
        begin
            selected_envelope := read_envelope;
        end
        else if (read_envelope = XESC) then
        begin
            status_close:= XESC;
            break;
        end;
        GRadio(win_psg, ENVEL_POSX, ENVEL_POSY, GVERT, GDISP, selected_envelope, Length(psg_envelope), psg_envelope);

        // volume
        read_volume:= GRadio(win_psg, VOL_POSX, VOL_POSY, GVERT, GEDIT, selected_volume, Length(psg_volume), psg_volume);
        if ((read_volume <> XESC) and (read_volume <> XTAB)) then
        begin
            selected_volume := read_volume;
        end
        else if (read_volume = XESC) then
        begin
            status_close:= XESC;
            break;
        end;
        GRadio(win_psg, VOL_POSX, VOL_POSY, GVERT, GDISP, selected_volume, Length(psg_volume), psg_volume);
        
        // Buttons to confirm
        status_close := GButton(win_psg, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GEDIT, 2, buttons_accept);    
        GButton(win_psg, BUTTONS_POSX, BUTTONS_POSY, GHORZ, GDISP, 2, buttons_accept);

    until status_close <> XTAB;

    if status_close = 1 then
    begin
        Result:=true;
        GAlert('Processing...');
    end;

    WClose(win_psg);
end;


procedure menu_pokeymax;
var
    win_pokeymax: Byte;
    selected: Byte;
    status_close: Boolean;
const
    menu: array[0..2] of string = (' Flash  ', ' Reboot ', ' Exit   ');

begin
    status_close:= false;
    selected:= 1;
    win_pokeymax:=WOpen(1, 3, 10, 5, WOFF);

    while not status_close do
    begin
        selected:=MenuV(win_pokeymax, 1, 1, WOFF, selected, Length(menu), menu);
        case selected of
            1: begin
                    if pMAX_present then
                    begin
                        status_close:= true;
                        menu_file;  // menu_flash
                    end;
               end;
            2: menu_reboot;
            3: begin
                    status_end:= true;
                    status_close:= true;
               end;
            XESC: status_close:= true;
        end;
    end;
    WClose(win_pokeymax);
end;

procedure menu_config;
var
    win_config: Byte;
    selected: Byte;
    status_close: Boolean;
const
    menu: array[0..4] of string = (' Mode   ', ' CORE   ', ' Pokey  ', ' SID    ', ' PSG    ');

begin
    selected:= 1;
    status_close:= false;

    win_config:=WOpen(12, 2, 10, 7, WOFF);

    while not status_close do
    begin
        selected:=MenuV(win_config, 1, 1, WOFF, selected, Length(menu), menu);
        case selected of
            1: if pMAX_present then
                begin
                    status_close:= true;
                    menu_mode;
                end;        
            2: if pMAX_present then
                begin
                    status_close:= true;
                    menu_core;
                end;
            3: if pMAX_present then
                begin
                    status_close:= true;
                    menu_pokey;
                end;
            4: if pMAX_present then
                begin
                    status_close:= true;
                    menu_sid;
                end;
            5: if pMAX_present then
                begin
                    status_close:= true;
                    menu_psg;
                end;
            XESC: status_close:= true;
        end;
    end;
    WClose(win_config);
end;

procedure details;
var
    s_pokey: String;

begin

    if pMAX_present then
    begin
        case PMAX_GetPokey of
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

        WPrint(win_details, 30, 3, WOFF, 'Sample:');

        WPrint(win_details, 7, 1, WOFF, PMAX_GetCoreVersion);
        WPrint(win_details, 8, 2, WOFF, s_pokey);
        WPrint(win_details, 8, 3, WOFF, convert_bool(PMAX_isSIDPresent));
        
        WPrint(win_details, 23, 1, WOFF, convert_bool(PMAX_isFlashPresent));
        WPrint(win_details, 23, 2, WOFF, convert_bool(PMAX_isPSGPresent));
        WPrint(win_details, 23, 3, WOFF, convert_bool(PMAX_isCovoxPresent));

        WPrint(win_details, 38, 3, WOFF, convert_bool(PMAX_isSamplePresent));
    end
    else begin
        WPrint(win_details, WPCNT, 2, WON, ' PokeyMAX not found. ');
    end;
end;

begin
    WInit;
    WBack(3);
    status_end:= false;
    selected_menu:= 1;

    win_main:=WOpen(0, 0, 40, 3, WOFF);
    WOrn(win_main, WPTOP, WPCNT, version);
    {$IFDEF DEBUG}
    pMAX_present:= true;
    {$ELSE}
    pMAX_present:= PMAX_Detect;
    {$ENDIF}
    if pMAX_present then PMAX_EnableConfig(true);

    win_details:=WOpen(0, 18, 40, 5, WOFF);
    WOrn(win_details, WPTOP, WPLFT, 'Details');

    while not status_end do
    begin
        details;

        selected_menu:=MenuH(win_main, 1, 1, WON, selected_menu, Length(menu_main), menu_main);
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
    if pMAX_present then PMAX_EnableConfig(false);
    WClose(win_details);
    WClose(win_main);
end.