@EndUserText.label: 'Abstract Entity for Attachment Popup'
define root abstract entity ZA_CHETU_ATTACH_93

{
  // Dummy is a dummy field
  @UI.hidden: true
  BookingUuid : sysuuid_x16;

  _StreamProperties : association [1] to ZA_CHETU_FILE_STREAM on 1 = 1;
}
