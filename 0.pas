{$reference System.Drawing.dll}

begin
  var b := new System.Drawing.Bitmap('in.bmp');
  var b2 := new System.Drawing.Bitmap(b, b.Width*4, b.Height*4);
  b2.Save('in2.bmp');
end.