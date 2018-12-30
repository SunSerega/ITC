{$reference ITC.dll}

begin
  //Rewrite(output, 'Log.txt');
  try
    ITC.ITC.Convert(8,12, 'abcchan.png');
  except
    on e: Exception do
      writeln(e);
  end;
  //output.Close;
  readln;
end.