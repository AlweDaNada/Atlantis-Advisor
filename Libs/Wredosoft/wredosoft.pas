{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit Wredosoft;

{$warn 5023 off : no warning about unused units}
interface

uses
  IntEdit, CylinderMap, Painter, PowerGrid, ColorBtn, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('IntEdit', @IntEdit.Register);
  RegisterUnit('CylinderMap', @CylinderMap.Register);
  RegisterUnit('Painter', @Painter.Register);
  RegisterUnit('PowerGrid', @PowerGrid.Register);
  RegisterUnit('ColorBtn', @ColorBtn.Register);
end;

initialization
  RegisterPackage('Wredosoft', @Register);
end.
