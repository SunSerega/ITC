{$reference System.Drawing.dll}

const
  //Размеры 1 пикселя, меняется в настройках консоли
  w = 8;
  h = 12;
  //размеры буфера, которые используются под одновременный вывод большого числа символов
  sw = 64;
  sh = 32;

type
  SymMask = record
    
    mask: array[,] of boolean;
    static fill := System.Drawing.Color.FromArgb(255,192,192,192);
    
    procedure Save(bw: System.IO.BinaryWriter);
    begin
      System.Console.Clear;
      var res: byte;
      var i := 0;
      
      foreach var b in mask.ElementsByCol do
      begin
        if b then
          res := res or (1 shl i);
        
        i += 1;
        if i=8 then
        begin
          bw.Write(res);
          res := 0;
          i := 0;
        end;
        
      end;
      
      if i<>0 then bw.Write(res);
      
    end;
    
    constructor(ptr_id: int64; stride: integer);
    begin
      mask := new boolean[w,h];
      
      for var y := 0 to h-1 do
      begin
        var x_ptr := ptr_id;
        
        for var x := 0 to w-1 do
        begin
          
          mask[x,y] :=
            (PByte(System.IntPtr.Create(x_ptr+0).ToPointer)^ = 192) and   //B
            (PByte(System.IntPtr.Create(x_ptr+1).ToPointer)^ = 192) and   //G
            (PByte(System.IntPtr.Create(x_ptr+2).ToPointer)^ = 192);      //R
          
          x_ptr += 4;
        end;
        
        ptr_id += stride;
      end;
      
    end;
    
  end;
  SymMaskComp = class(System.Collections.Generic.IEqualityComparer<SymMask>)
    
    public function Equals(m1,m2: SymMask): boolean :=
    m1.mask.ElementsByRow.SequenceEqual(m2.mask.ElementsByRow);
    
    public function GetHashCode(sm: SymMask): integer;
    begin
      var m := 1;
      
      foreach var b in sm.mask do
      begin
        
        if b then
          Result := Result xor m;
        
        m := m shl 1;
        if m=0 then m := 1;
      end;
      
    end;
    
  end;

function SetWindowPos(hWnd: System.IntPtr; hWndInsertAfter, X, Y, cx, cy: integer; wFlags: cardinal): System.IntPtr;
external 'user32.dll';

begin
  try
    Rewrite(output, 'Log.txt');
    
    SetWindowPos(
      System.Diagnostics.Process.GetCurrentProcess.MainWindowHandle,
      0,0,0,0,0,
      $1 or $4
    );
    System.Console.CursorVisible := false;
    //System.Console.SetBufferSize(1,1);
    System.Console.SetWindowSize(sw+1,sh+1);
    System.Console.SetBufferSize(sw+1,sh+1+100);
    Sleep(1000);
    
    var bmp := new System.Drawing.Bitmap(w*sw, h*sh);
    var gr := System.Drawing.Graphics.FromImage(bmp);
    
//    System.Console.Write(#9608);
//    gr.CopyFromScreen(
//      10,32,0,0,
//      bmp.Size
//    );
//    bmp.Save('temp.bmp');
    
    var sym_masks := new HashSet<SymMask>(new SymMaskComp);
    var bw := new System.IO.BinaryWriter(System.IO.File.Create($'sym masks {w}x{h}'));
    
    var x := 0;
    var y := 0;
    var sym_wr := 0;
    var sym_done := 0;
    
    var otp_thr := new System.Threading.Thread(()->
    while true do
    begin
      System.Console.Title := $'Выписано {sym_wr} символов, обработано {sym_done}';
      Sleep(100);
    end);
    otp_thr.Start;
    
    for var i := 0 to word.MaxValue do
    try
      
      System.Console.SetCursorPosition(x,y);
      System.Console.Write(char(i));
      
      sym_wr += 1;
      
      x += 1;
      if x = sw then
      begin
        x := 0;
        y += 1;
        if y = sh then
        begin
          y := 0;
          
          gr.CopyFromScreen(
            10,32,0,0,
            bmp.Size
          );
          var bd := bmp.LockBits(
            new System.Drawing.Rectangle(System.Drawing.Point.Empty, bmp.Size),
            System.Drawing.Imaging.ImageLockMode.ReadOnly,
            System.Drawing.Imaging.PixelFormat.Format32bppArgb
          );
          var ptr_id := bd.Scan0.ToInt64;
          
          loop sh do
          begin
            
            loop sw do
            begin
              
              var curr_mask := new SymMask(ptr_id, bd.Stride);
              if sym_masks.Add(curr_mask) then
              begin
                bw.Write(word(sym_done));
                curr_mask.Save(bw);
                writeln($'сохранён символ #{sym_done}');
              end;
              
              sym_done += 1;
              ptr_id += w*4;
            end;
            
            ptr_id += bd.Stride*(h-1);
          end;
          
          Flush(output);
          bmp.UnlockBits(bd);
          System.Console.Clear;
        end;
      end;
      
      Flush(output);
      
    except
      on e: Exception do
      begin
        writeln($'ошибка с символом #{i}');
        writeln(e);
        Flush(output);
      end;
    end;
    
    otp_thr.Abort;
    bw.Close;
    write($'всего добавлено {sym_masks.Count} символов');
    //System.Console.WriteLine('ready');
    //Readln;
    
  except
    on e: Exception do
    begin
      writeln('общая ошибка');
      write(e);
      Flush(output);
    end;
  end;
end.