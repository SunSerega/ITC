library ITC;
{$reference System.Drawing.dll}

//ToDo изменить алгоритм, чтоб использовало символы и для рисовки и для заливки

interface

procedure Convert(w,h: integer; im_fname: string);

implementation

function SetWindowPos(hWnd: System.IntPtr; hWndInsertAfter, X, Y, cx, cy: integer; wFlags: cardinal): System.IntPtr;
external 'user32.dll';

type
  Color = record
    
    R,G,B: byte;
    
    constructor(R,G,B: byte);
    begin
      self.R := R;
      self.G := G;
      self.B := B;
    end;
    
  end;
  CColor = System.ConsoleColor;

var
  ColorConv := Arr(
    ( CColor.Black,        new Color(0, 0, 0) ),
    ( CColor.DarkBlue,     new Color(0, 0, 128) ),
    ( CColor.DarkGreen,    new Color(0, 128, 0) ),
    ( CColor.DarkCyan,     new Color(0, 128, 128) ),
    ( CColor.DarkRed,      new Color(128, 0, 0) ),
    ( CColor.DarkMagenta,  new Color(128, 0, 128) ),
    ( CColor.DarkYellow,   new Color(128, 128, 0) ),
    ( CColor.Gray,         new Color(192, 192, 192) ),
    ( CColor.DarkGray,     new Color(128, 128, 128) ),
    ( CColor.Blue,         new Color(0, 0, 255) ),
    ( CColor.Green,        new Color(0, 255, 0) ),
    ( CColor.Cyan,         new Color(0, 255, 255) ),
    ( CColor.Red,          new Color(255, 0, 0) ),
    ( CColor.Magenta,      new Color(255, 0, 255) ),
    ( CColor.Yellow,       new Color(255, 255, 0) ),
    ( CColor.White,        new Color(255, 255, 255) )
  );

function ElementsInRange<T>(self: array[,] of T; x1,x2, y1,y2: integer): array[,] of T; extensionmethod;
begin
  Result := new T[x2-x1+1, y2-y1+1];
  for var y := y1 to y2 do
    for var x := x1 to x2 do
      Result[x-x1, y-y1] := self[x,y];
end;

function GetPrimColors(cls: sequence of Color): (CColor, List<Color>, CColor);
begin
  
  var res :=
    ColorConv.SelectMany((cc1,i)->ColorConv.Skip(i+1).Select(cc2->(cc1,cc2)))
    .Select(t->
    begin
      var len_sum := 0.0;
      
      var l :=
        cls.Select(c->(
          
          sqr(c.R-t[0][1].R)+
          sqr(c.G-t[0][1].G)+
          sqr(c.B-t[0][1].B),
          
          sqr(c.R-t[1][1].R)+
          sqr(c.G-t[1][1].G)+
          sqr(c.B-t[1][1].B),
          
          c
        )).Select(
          lt->
          begin
            
            if lt[0] < lt[1] then
            begin
              len_sum += lt[0];
              Result := (t[0][0], lt[2]);
            end else
            begin
              len_sum += lt[1];
              Result := (t[1][0], lt[2]);
            end;
            
          end
        ).ToList;
      
      Result := (
        l, len_sum,
        t[0][0], t[1][0]
      );
    end)
    .MinBy(t->t[1]);
  
  var l: List<(CColor, Color)> := res[0];
  var c1: CColor := res[2];
  var c2: CColor := res[3];
  
  Result := (
    c1, l.Where(t->t[0]=c1).Select(t->t[1]).Distinct.ToList,
    c2
  );
end;

var
  masks := new Dictionary<string, array of (array[,] of boolean, char)>;

procedure LoadMask(w,h:integer; id: string);
begin
  if masks.ContainsKey(id) then exit;
  
  var str := System.IO.File.OpenRead($'sym masks {id}');
  var br := new System.IO.BinaryReader(str);
  
  var bpm := ((w*h-1) div 8) + 1;
  
  masks[id] := ArrGen(str.Length div (2+bpm),
    i->
    begin
      var ch := char(br.ReadUInt16);
      var enm := System.Collections.BitArray.Create(br.ReadBytes(bpm)).GetEnumerator;
      
      var res := new boolean[w,h];
      for var y := 0 to h-1 do
        for var x := 0 to w-1 do
        begin
          enm.MoveNext;
          res[x,y] := boolean(enm.Current);
        end;
      
      Result := (res, ch);
    end
  );
  
end;

///Result[1] = не_надо менять порядок
///Result[2] = сколько писелей совпали
function GetCorrectChar(inp: array[,] of boolean; mask: array of (array[,] of boolean, char)): (char, boolean, integer) :=
mask.SelectMany(
  t->
  Arr(
    t.Add(true),
    t.Add(false)
  )
).Select(
  t->(
    
    t[1],
    t[2],
    
    t[0].Cast&<boolean>.Zip(
      inp.Cast&<boolean>,
      (b1,b2)->
      (b1=b2) = t[2]
    ).Count(b->b)
    
  )
).MaxBy(t->t[2]);

procedure Convert(w,h: integer; im_fname: string);
begin
  
  System.Console.Clear;
  SetWindowPos(
    System.Diagnostics.Process.GetCurrentProcess.MainWindowHandle,
    0,0,0,0,0,
    $1 or $4
  );
  
  var bmp := new System.Drawing.Bitmap(im_fname);
  
  var sw := ((bmp.Width -1) div w) + 1;
  var sh := ((bmp.Height-1) div h) + 1;
  
  System.Console.SetWindowSize(sw+1,sh+1);
  System.Console.SetBufferSize(sw+1,sh+1);
  
  var cls := new Color[sw * w, sh * h];
  
  for var y := 0 to bmp.Height-1 do
    for var x := 0 to bmp.Width-1 do
    begin
      var c := bmp.GetPixel(x,y);//ToDo медленно
      cls[x,y] := new Color(c.R,c.G,c.B);
    end;
  bmp.Dispose;
  bmp := nil;
  
  var mask_id := $'{w}x{h}';
  LoadMask(w,h, mask_id);
  var mask := masks[mask_id];
  
  var lc1 := System.Console.ForegroundColor;
  var lc2 := System.Console.BackgroundColor;
  var c1 := lc1;
  var c2 := lc2;
  var sb := new StringBuilder;
  
  var FlushLetters: ()->() := ()->
  begin
    if sb.Length=0 then exit;
    
    if lc1<>c1 then
    begin
      System.Console.ForegroundColor := c1;
      lc1 := c1;
    end;
    
    if lc2<>c2 then
    begin
      System.Console.BackgroundColor := c2;
      lc2 := c2;
    end;
    
    System.Console.Write(sb.ToString);
    sb.Clear;
  end;
  
  var AddLetter: (char, CColor, CColor)->() := (ch, nc1, nc2)->
  begin
    if (nc1 <> c1) or (nc2 <> c2) then
    begin
      FlushLetters;
      c1 := nc1;
      c2 := nc2;
    end;
    
    sb += ch;
    
  end;
  
  for var y := 0 to sh-1 do
  begin
    
    for var x := 0 to sw-1 do
    begin
      var bx := x*w;
      var by := y*h;
      var ncls := cls.ElementsInRange(
        bx,bx+w-1,
        by,by+h-1
      );
      
      var pcls := GetPrimColors(ncls.Cast&<Color>);
      var ccd := GetCorrectChar(ncls.ConvertAll(c->pcls[1].Contains(c)), mask);
      
      if ccd[1] then
        AddLetter(ccd[0], pcls[0], pcls[2]) else
        AddLetter(ccd[0], pcls[2], pcls[0]);
    end;
    
    FlushLetters;
    System.Console.Write(#10);
  end;
  
end;

end.