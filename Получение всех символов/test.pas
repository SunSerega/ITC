{$reference System.Drawing.dll}

const
  //Размеры 1 пикселя, с которыми выполнялось 0.pas
  w = 8;
  h = 12;
  
  bpm = ((w*h-1) div 8) + 1;

begin
  var br := new System.IO.BinaryReader(System.IO.File.OpenRead($'sym masks {w}x{h}'));
  System.IO.Directory.CreateDirectory('symbols test');
  System.IO.Directory.EnumerateFiles('symbols test').ForEach(System.IO.File.Delete);
  
  while true do
  try
    var id := br.ReadUInt16;
    var ba := new System.Collections.BitArray(br.ReadBytes(bpm));
    
    var bmp := new System.Drawing.Bitmap(w,h);
    
//    foreach var row in ba.Cast&<boolean>.Batch(w).Numerate(0) do
//      foreach var el in row[1].Numerate(0) do
//        if el[1] then
//          bmp.SetPixel(el[0], row[0], System.Drawing.Color.FromArgb(255, 192,192,192)) else
//          bmp.SetPixel(el[0], row[0], System.Drawing.Color.FromArgb(255,   0,  0,  0));
    
    var enm := ba.GetEnumerator;
    var temp_arr := MatrGen(
      h,w,
      (y,x)->
      begin
        if not enm.MoveNext then raise new Exception;
        Result := boolean(enm.Current);
      end
    );
    
    for var x := 0 to w-1 do
      for var y := 0 to h-1 do
        bmp.SetPixel(x,y,
          temp_arr[y,x]?
          System.Drawing.Color.FromArgb(255, 192,192,192):
          System.Drawing.Color.FromArgb(255,   0,  0,  0)
        );
    
    bmp.Save($'symbols test\sym #{id}.bmp');
  except
    on System.IO.EndOfStreamException do break;
  end;
  
end.