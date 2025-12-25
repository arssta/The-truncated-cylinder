program RotatingTruncatedCylinder;
uses Crt, Dos;

const
  VESA_MODE = $103;
  SCREEN_WIDTH  = 800;
  SCREEN_HEIGHT = 600;

  POINTS_COUNT = 36;

  RADIUS = 100;
  LENGTH = 200;
  TILT   = 60;     
type
  Point3D = record
    x, y, z: real;
  end;

  Point2D = record
    x, y: integer;
  end;

var
  BottomPts, TopPts: array[1..POINTS_COUNT] of Point3D;
  ScrBottom, ScrTop: array[1..POINTS_COUNT] of Point2D;
  Angle: real;

{ ---------- VIDEO ---------- }

procedure SetVideoMode(mode: word);
begin
  asm
    mov ax, 4F02h
    mov bx, mode
    int 10h
  end;
end;

procedure PutPixel(x, y: integer; color: byte);
begin
  asm
    mov ah, 0Ch
    mov al, color
    mov bh, 0
    mov cx, x
    mov dx, y
    int 10h
  end;
end;

procedure ClearScreen;
var x, y: integer;
begin
  for x := 0 to SCREEN_WIDTH-1 do
    for y := 0 to SCREEN_HEIGHT-1 do
      PutPixel(x, y, 0);
end;

{ ---------- LINE ---------- }

procedure DrawLine(x1, y1, x2, y2: integer; color: byte);
var dx, dy, sx, sy, err, e2: integer;
begin
  dx := abs(x2 - x1);
  dy := abs(y2 - y1);
  if x1 < x2 then sx := 1 else sx := -1;
  if y1 < y2 then sy := 1 else sy := -1;
  err := dx - dy;

  while true do
  begin
    PutPixel(x1, y1, color);
    if (x1 = x2) and (y1 = y2) then break;
    e2 := 2 * err;
    if e2 > -dy then begin err := err - dy; x1 := x1 + sx; end;
    if e2 < dx then begin err := err + dx; y1 := y1 + sy; end;
  end;
end;

{ ---------- INIT ---------- }

procedure InitCylinder;
var i: integer; a: real;
begin
  for i := 1 to POINTS_COUNT do
  begin
    a := 2 * Pi * (i-1) / POINTS_COUNT;

    { нижнее основание }
    BottomPts[i].x := -LENGTH / 2;
    BottomPts[i].y := RADIUS * cos(a);
    BottomPts[i].z := RADIUS * sin(a);

    { верхнее основание — тот же радиус, но наклон по Y }
    TopPts[i].x :=  LENGTH / 2 - TILT * cos(a);  { УСЕЧЕНИЕ }
TopPts[i].y := RADIUS * cos(a);
TopPts[i].z := RADIUS * sin(a);

  end;
end;

{ ---------- ROTATION ---------- }

procedure RotatePoint(var p: Point3D; a: real);
var tx, tz: real;
begin
  tx := p.x * cos(a) - p.z * sin(a);
  tz := p.x * sin(a) + p.z * cos(a);
  p.x := tx;
  p.z := tz;
end;

procedure Project(p: Point3D; var x2, y2: integer);
var scale: real;
begin
  scale := 300 / (300 + p.z);
  x2 := 400 + round(p.x * scale);
  y2 := 300 - round(p.y * scale);
end;

{ ---------- DRAW ---------- }

procedure DrawCylinder;
var i, n: integer;
begin
  for i := 1 to POINTS_COUNT do
  begin
    RotatePoint(BottomPts[i], Angle);
    RotatePoint(TopPts[i], Angle);

    Project(BottomPts[i], ScrBottom[i].x, ScrBottom[i].y);
    Project(TopPts[i],    ScrTop[i].x,    ScrTop[i].y);
  end;

  for i := 1 to POINTS_COUNT do
  begin
    if i = POINTS_COUNT then n := 1 else n := i + 1;

    DrawLine(ScrBottom[i].x, ScrBottom[i].y,
             ScrBottom[n].x, ScrBottom[n].y, 15);

    DrawLine(ScrTop[i].x, ScrTop[i].y,
             ScrTop[n].x, ScrTop[n].y, 15);

    DrawLine(ScrBottom[i].x, ScrBottom[i].y,
             ScrTop[i].x,    ScrTop[i].y, (i mod 14) + 1);
  end;
end;

{ ---------- MAIN ---------- }

begin
  InitCylinder;
  Angle := 0;

  SetVideoMode(VESA_MODE);
  Delay(300);

  repeat
    ClearScreen;
    DrawCylinder;

    Angle := Angle + Pi / 12;
    if Angle > 2*Pi then Angle := Angle - 2*Pi;

    Delay(70);
  until KeyPressed;

  SetVideoMode(3);
end.
