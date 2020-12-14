String strip0x(String s)
{
  if(s.startsWith('0x'))
    return s.substring(2);
  return s;
}

String append0x(String s) {
  if(s.startsWith('0x'))
    return s;
  return '0x' + s;
}