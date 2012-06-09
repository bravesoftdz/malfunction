{
  Copyright 2003-2012 Michalis Kamburelis.

  This file is part of "malfunction".

  "malfunction" is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  "malfunction" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with "malfunction"; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

  ----------------------------------------------------------------------------
}

unit GameGeneral;

{ some general things, consts and funcs for "Malfunction" game.

  Ten modul NIE MOZE zalezec od jakiegokolwiek modulu ktory odwoluje
  sie do obiektu glw w swoim initialization (np. aby zrobic
  Window.OnInitList.Add()). To dlatego ze glw jest tworzony w
  initialization niniejszego modulu i jezeli tamten modul bedzie zalezal
  od GameGeneral a GameGeneral od niego to nie jest pewne ktore
  initialization zostanie wykonane jako pierwsze - a przeciez
  obiekt glw musi byc utworzony zanim sie do niego odwolasz.
}

interface

uses SysUtils, CastleWindow, CastleNotifications;

{$define read_interface}

const
  Version = '1.2.7';
  DisplayProgramName = 'malfunction';

var
  { Whole program uses this window.
    This is created and destroyed in init/fini of this module. }
  Window: TCastleWindowCustom;

{ Game modes.

  At every time, the program is in some "mode".
  Each mode has a specific callbacks to control
  window, each mode can also init some OpenGL state for itself.

  Events OnOpen, OnClose, OnCloseQuery are defined in this unit
  and cannot be redefined by modes. Other events are initialized to nil
  before calling GameModeEnter (so you don't have to set them to nil
  in every gameModeExit), and every gameModeEnter[] can set them
  to some mode-specific callbacks.

  As for OnResize : RasizeAllowed = raOnlyAtOpen. So we don't have to do
  anything in OnResize. So we register no OnResize callback.
  @bold(Every mode must) define some projection inside modeEnter.

  modeNone is a very specific mode : this is the initial mode
  when program starts. Never do SetGameMode(modeNone).

  You should terminate any TCastleWindowBase event handling after SetGameMode call. }

type
  TGameMode = (modeNone, modeMenu, modeGame);

function GameMode: TGameMode;
procedure SetGameMode(value: TGameMode);

var
  { gameModeEnter i Exit - inicjowana w initialization odpowiednich modulow
    mode*Unit, wszedzie indziej readonly. W czasie dzialania tych procedur
    GameMode bedzie ciagle rowne staremu mode'owi. }
  gameModeEnter, gameModeExit: array[TGameMode]of TProcedure;

{ game data directories ------------------------------------------------------ }

const
  imagesDir = 'images' +PathDelim;
  vrmlsDir = 'vrmls' +PathDelim;
  skiesDir = 'skies' +PathDelim;

{ ----------------------------------------------------------------------------
  zainicjowane w niszczone w tym module. Wyswietlane i Idle'owane w ModeGameUnit.
  Moze byc uzywane z kazdego miejsca. }

var
  Notifications: TCastleNotifications;

implementation

{$define read_implementation}

uses CastleGLUtils, CastleUtils, CastleMessages, ProgressUnit,
  CastleProgress, OpenGLBmpFonts, BFNT_BitstreamVeraSansMono_m18_Unit;

var fGameMode: TGameMode = modeNone;

function GameMode: TGameMode;
begin result := fGameMode end;

procedure SetGameMode(value: TGameMode);
begin
 Check(value <> modeNone, 'Can''t SetGameMode to modeNone');

 if gameModeExit[fGameMode] <> nil then gameModeExit[fGameMode];

 Window.OnDraw := nil;
 Window.OnKeyDown := nil;
 Window.OnKeyUp := nil;
 Window.OnIdle := nil;

 if gameModeEnter[value] <> nil then gameModeEnter[value];
 fGameMode := value;

 Window.PostRedisplay;
end;

{ glw general events handling ----------------------------------------------- }

procedure CloseQuery(Window: TCastleWindowBase);
begin
 if MessageYesNo(Window, 'Are you sure you want to quit ?') then Window.Close;
end;

procedure Open(Window: TCastleWindowBase);
begin
 MessagesTheme.Font := TGLBitmapFont.Create(@BFNT_BitstreamVeraSansMono_m18);

 Notifications := TCastleNotifications.Create(Window);
 Notifications.MaxMessages := 10;
 Notifications.VerticalPosition := vpUp;
 WindowProgressInterface.Window := Window;
 Progress.UserInterface := WindowProgressInterface;

 SetGameMode(modeMenu);
end;

procedure Close(Window: TCastleWindowBase);
begin
 if (fGameMode <> modeNone) and
    (gameModeExit[fGameMode] <> nil) then gameModeExit[fGameMode];
 fGameMode := modeNone;

 FreeAndNil(MessagesTheme.Font);
end;

initialization
 Window := TCastleWindowCustom.Create(nil);
 Window.FpsShowOnCaption := true;
 Window.OnCloseQuery := @CloseQuery;
 Window.OnOpen := @Open;
 Window.OnClose := @Close;

 {leave OnResize to nil - dont set default projection matrix
  (we will set it in modeEnter, and because we can't be resized -
  we will never have to set it in OnResize)}

 Window.ResizeAllowed := raOnlyAtOpen;
finalization
 FreeAndNil(Window);
end.
