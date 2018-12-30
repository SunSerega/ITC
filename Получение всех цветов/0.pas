{$reference System.Drawing.dll}

const
  //Размеры 1 пикселя, меняется в настройках консоли
  w = 8;
  h = 12;

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
    
    var cls := System.ConsoleColor.GetValues(typeof(System.ConsoleColor));
    
    System.Console.SetWindowSize(cls.Length+1,1+1);
    System.Console.SetBufferSize(cls.Length+1,1+1);
    Sleep(1000);
    var ch := #9608;
    foreach var c: System.ConsoleColor in cls do
    begin
      System.Console.ForegroundColor := c;
      System.Console.Write(ch);
    end;
    
    var bmp := new System.Drawing.Bitmap(w*cls.Length, h*1);
    var gr := System.Drawing.Graphics.FromImage(bmp);
    gr.CopyFromScreen(
      10,32,0,0,
      bmp.Size
    );
    
    var x := 0;
    foreach var c: System.ConsoleColor in cls do
    begin
      var rgb := bmp.GetPixel(x,0);
      writeln($' System.ConsoleColor.{System.Enum.GetName(typeof(System.ConsoleColor), c)}, ({rgb.R}, {rgb.G}, {rgb.B}) ');
      
      x += w;
    end;
    
//    
////    System.Console.Write(#9608);
////    gr.CopyFromScreen(
////      10,32,0,0,
////      bmp.Size
////    );
////    bmp.Save('temp.bmp');
//    
//    var sym_masks := new HashSet<SymMask>(new SymMaskComp);
//    var bw := new System.IO.BinaryWriter(System.IO.File.Create($'sym masks {w}x{h}'));
//    
//    var x := 0;
//    var y := 0;
//    var sym_wr := 0;
//    var sym_done := 0;
//    
//    var otp_thr := new System.Threading.Thread(()->
//    while true do
//    begin
//      System.Console.Title := $'Выписано {sym_wr} символов, обработано {sym_done}';
//      Sleep(100);
//    end);
//    otp_thr.Start;
//    
//    for var i := 0 to word.MaxValue do
//    try
//      
//      System.Console.SetCursorPosition(x,y);
//      System.Console.Write(char(i));
//      
//      sym_wr += 1;
//      
//      x += 1;
//      if x = sw then
//      begin
//        x := 0;
//        y += 1;
//        if y = sh then
//        begin
//          y := 0;
//          
//          gr.CopyFromScreen(
//            10,32,0,0,
//            bmp.Size
//          );
//          var bd := bmp.LockBits(
//            new System.Drawing.Rectangle(System.Drawing.Point.Empty, bmp.Size),
//            System.Drawing.Imaging.ImageLockMode.ReadOnly,
//            System.Drawing.Imaging.PixelFormat.Format32bppArgb
//          );
//          var ptr_id := bd.Scan0.ToInt64;
//          
//          loop sh do
//          begin
//            
//            loop sw do
//            begin
//              
//              var curr_mask := new SymMask(ptr_id, bd.Stride);
//              if sym_masks.Add(curr_mask) then
//              begin
//                bw.Write(word(sym_done));
//                curr_mask.Save(bw);
//                writeln($'сохранён символ #{sym_done}');
//              end;
//              
//              sym_done += 1;
//              ptr_id += w*4;
//            end;
//            
//            ptr_id += bd.Stride*(h-1);
//          end;
//          
//          Flush(output);
//          bmp.UnlockBits(bd);
//          System.Console.Clear;
//        end;
//      end;
//      
//      Flush(output);
//      
//    except
//      on e: Exception do
//      begin
//        writeln($'ошибка с символом #{i}');
//        writeln(e);
//        Flush(output);
//      end;
//    end;
//    
//    otp_thr.Abort;
//    bw.Close;
//    write($'всего добавлено {sym_masks.Count} символов');
//    //System.Console.WriteLine('ready');
//    //Readln;
    
  except
    on e: Exception do
    begin
      writeln('общая ошибка');
      write(e);
    end;
  end;
  Flush(output);
end.