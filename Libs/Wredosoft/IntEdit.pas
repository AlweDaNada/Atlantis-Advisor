unit IntEdit;

interface

uses Windows, Classes, StdCtrls, ExtCtrls, Controls, Messages, SysUtils,
  Forms, Graphics, Menus, Buttons, Spin
  {$IFDEF LAZ}
  , LCLType, LCLIntf, LMessages, SpinEx //LazControlDsgn, LazControls,
  {$ENDIF}

  ;

type

{ TFuckSpinEdit }
  TFuckSpinEdit = class (TSpinEditEx)
    private
      FChangeBoundsLock: Boolean;
    public
      constructor Create(AOwner: TComponent); override;
      procedure SetBounds(aLeft, aTop, aWidth, aHeight: integer); override;
    protected
      procedure ChangeBounds(ALeft, ATop, AWidth, AHeight: Integer; KeepBase: Boolean); override;

  end;

{ TIntEdit }

  TIntEdit = class(TCustomEdit)
  private
    FInput: boolean;
    FMinValue: LongInt;
    FMaxValue: LongInt;
    FIncrement: LongInt;
    {$IFDEF LAZ}
    FButton: TFuckSpinEdit;
    {$ELSE}
    FButton: TSpinButton;
    {$ENDIF}
    FEditorEnabled: Boolean;
    function GetMinHeight: Integer;
    function GetValue: LongInt;
    function CheckValue (NewValue: LongInt): LongInt;
    procedure SetValue (NewValue: LongInt);
    procedure SetEditRect;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
    {$IFDEF LAZ}
    procedure DoEnter(var Message: TLMSetFocus); message CM_ENTER;
    procedure DoExit(var Message: TLMExit);   message CM_EXIT;
    {$ELSE}
    procedure CMEnter(var Message: TCMGotFocus); message CM_ENTER;
    procedure CMExit(var Message: TCMExit);   message CM_EXIT;
    {$ENDIF}
    procedure WMPaste(var Message: TWMPaste);   message WM_PASTE;
    procedure WMCut(var Message: TWMCut);   message WM_CUT;
  protected
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    function IsValidChar(Key: Char): Boolean; virtual;
    procedure UpClick (Sender: TObject); virtual;
    procedure DownClick (Sender: TObject); virtual;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    {$IFDEF LAZ}
    procedure CreateParams(var Params: TCreateParams); override;

    {$ELSE}
    procedure CreateParams(var Params: TCreateParams); override;
    {$ENDIF}
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    {$IFDEF LAZ}
    property Button: TFuckSpinEdit read FButton;
    {$ELSE}
    property Button: TSpinButton read FButton;
    {$ENDIF}
  published
    property Anchors;
    property AutoSelect;
    property AutoSize;
    property Color;
    property Constraints;
    {$IFNDEF LAZ}
    property Ctl3D;
    {$ENDIF}
    property DragCursor;
    property DragMode;
    property EditorEnabled: Boolean read FEditorEnabled write FEditorEnabled default True;
    property Enabled;
    property Font;
    property Increment: LongInt read FIncrement write FIncrement default 1;
    property MaxLength;
    property MaxValue: LongInt read FMaxValue write FMaxValue;
    property MinValue: LongInt read FMinValue write FMinValue;
    property ParentColor;
    {$IFNDEF LAZ}
    property ParentCtl3D;
    {$ENDIF}
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Value: LongInt read GetValue write SetValue;
    property Visible;
    property OnChange;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDrag;
  end;

procedure Register;

implementation

procedure Register;
 begin
   RegisterClasses([TIntEdit]);
   RegisterComponents('Additional', [TIntEdit]);
 end;


{ TIntEdit }

constructor TIntEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  {$IFDEF LAZ}
  FButton := TFuckSpinEdit.Create (Self);
  {$ELSE}
  FButton := TSpinButton.Create (Self);
  {$ENDIF}
  FButton.Width := 15;
  FButton.Height := 17;
  FButton.Visible := True;  
  FButton.Parent := Self;
  {$IFDEF LAZ}
  FButton.OnClick := OnClick;
  {$ELSE}
  FButton.FocusControl := Self;
  FButton.OnUpClick := UpClick;
  FButton.OnDownClick := DownClick;
  {$ENDIF}
  Text := '0';
  ControlStyle := ControlStyle - [csSetCaption];
  FIncrement := 1;
  FEditorEnabled := True;
end;

destructor TIntEdit.Destroy;
begin
  FButton := nil;
  inherited Destroy;
end;

procedure TIntEdit.GetChildren(Proc: TGetChildProc; Root: TComponent);
begin
end;

procedure TIntEdit.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if Key = VK_UP then UpClick (Self)
  else if Key = VK_DOWN then DownClick (Self);
  inherited KeyDown(Key, Shift);
  FInput := True;
end;

procedure TIntEdit.KeyUp(var Key: Word; Shift: TShiftState);
begin
  FInput := False;
end;

procedure TIntEdit.KeyPress(var Key: Char);
begin
  if not IsValidChar(Key) then
  begin
    Key := #0;
    MessageBeep(0)
  end;
  if Key <> #0 then inherited KeyPress(Key);
end;

function TIntEdit.IsValidChar(Key: Char): Boolean;
begin
  Result := (Key in [DecimalSeparator, '+', '-', '0'..'9']) or
    ((Key < #32) and (Key <> Chr(VK_RETURN)));
  if not FEditorEnabled and Result and ((Key >= #32) or
      (Key = Char(VK_BACK)) or (Key = Char(VK_DELETE))) then
    Result := False;
end;

procedure TIntEdit.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
{  Params.Style := Params.Style and not WS_BORDER;  }
  Params.Style := Params.Style or ES_MULTILINE or WS_CLIPCHILDREN;
end;

procedure TIntEdit.CreateWnd;
begin
  inherited CreateWnd;
  SetEditRect;
end;

procedure TIntEdit.SetEditRect;
var
  Loc: TRect;
begin
  SendMessage(Handle, EM_GETRECT, 0, LongInt(@Loc));
  Loc.Bottom := ClientHeight + 1;  {+1 is workaround for windows paint bug}
  Loc.Right := ClientWidth - FButton.Width - 2;
  Loc.Top := 0;  
  Loc.Left := 0;  
  SendMessage(Handle, EM_SETRECTNP, 0, LongInt(@Loc));
  SendMessage(Handle, EM_GETRECT, 0, LongInt(@Loc));  {debug}
end;

procedure TIntEdit.WMSize(var Message: TWMSize);
var
  MinHeight: Integer;
begin
  inherited;
  MinHeight := GetMinHeight;
    { text edit bug: if size to less than minheight, then edit ctrl does
      not display the text }
  if Height < MinHeight then   
    Height := MinHeight
  else if FButton <> nil then
  begin
    {$IFDEF LAZ}
    if NewStyleControls then
    {$ELSE}
    if NewStyleControls and Ctl3D then
    {$ENDIF}
      FButton.SetBounds(Width - FButton.Width - 5, 0, FButton.Width, Height - 5)
    else FButton.SetBounds (Width - FButton.Width, 1, FButton.Width, Height - 3);
    SetEditRect;
  end;
end;

function TIntEdit.GetMinHeight: Integer;
var
  DC: HDC;
  SaveFont: HFont;
  I: Integer;
  SysMetrics, Metrics: TTextMetric;
begin
  DC := GetDC(0);
  GetTextMetrics(DC, SysMetrics);
  SaveFont := SelectObject(DC, Font.Handle);
  GetTextMetrics(DC, Metrics);
  SelectObject(DC, SaveFont);
  ReleaseDC(0, DC);
  I := SysMetrics.tmHeight;
  if I > Metrics.tmHeight then I := Metrics.tmHeight;
  Result := Metrics.tmHeight + I div 4 + GetSystemMetrics(SM_CYBORDER) * 4 + 2;
end;

procedure TIntEdit.UpClick (Sender: TObject);
begin
  if ReadOnly then MessageBeep(0)
  else Value := Value + FIncrement;
end;

procedure TIntEdit.DownClick (Sender: TObject);
begin
  if ReadOnly then MessageBeep(0)
  else Value := Value - FIncrement;
end;

procedure TIntEdit.WMPaste(var Message: TWMPaste);
begin
  if not FEditorEnabled or ReadOnly then Exit;
  inherited;
end;

procedure TIntEdit.WMCut(var Message: TWMPaste);
begin
  if not FEditorEnabled or ReadOnly then Exit;
  inherited;
end;
{$IFDEF LAZ}
procedure TIntEdit.DoExit(var Message: TLMExit);
{$ELSE}
procedure TIntEdit.CMExit(var Message: TCMExit);
{$ENDIF}
begin
  inherited;
  if CheckValue (Value) <> Value then
    SetValue (Value);
  FInput := False;  
end;

function TIntEdit.GetValue: LongInt;
begin
  if Text = '' then Result := FMinValue
  else
  try
    Result := StrToInt(Text);
  except
    Result := FMinValue;
  end;
end;

procedure TIntEdit.SetValue (NewValue: LongInt);
begin
  if not FInput then
    Text := IntToStr(CheckValue (NewValue));
end;

function TIntEdit.CheckValue (NewValue: LongInt): LongInt;
begin
  Result := NewValue;
  if (FMaxValue <> FMinValue) then
  begin
    if NewValue < FMinValue then
      Result := FMinValue
    else if NewValue > FMaxValue then
      Result := FMaxValue;
  end;
end;
{$IFDEF LAZ}
procedure TIntEdit.DoEnter(var Message: TLMSetFocus);
{$ELSE}
procedure TIntEdit.CMEnter(var Message: TCMGotFocus);
{$ENDIF}
begin
  if AutoSelect and not (csLButtonDown in ControlState) then
    SelectAll;
  inherited;
end;


{$IFDEF LAZ}
constructor TFuckSpinEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csSetCaption];
  Anchors := [akLeft, akTop];
  AutoSize := False;
end;
{
  TControl.ChangeBounds loop detected!!! this code fixed
}
procedure TFuckSpinEdit.ChangeBounds(ALeft, ATop, AWidth, AHeight: integer;
  KeepBase: Boolean);
begin
  if (ALeft <> Left) or (ATop <> Top) or
     (AWidth <> Width) or (AHeight <> Height) then
    begin
      FChangeBoundsLock := True;
       try
         inherited ChangeBounds(ALeft, ATop, AWidth, AHeight, KeepBase);
       finally
         FChangeBoundsLock := False;
       end;
    end;
end;

procedure TFuckSpinEdit.SetBounds(aLeft, aTop, aWidth, aHeight: integer);
begin
  if (aLeft = Left) and (aTop = Top) and
     (aWidth = Width) and (aHeight = Height) then Exit;

  inherited SetBounds(aLeft, aTop, aWidth, aHeight);
end;

{$ENDIF}


initialization
  RegisterClasses([TIntEdit]);
end.

