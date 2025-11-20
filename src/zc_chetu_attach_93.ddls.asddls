@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: '###GENERATED Core Data Service Entity'

@Metadata.allowExtensions: true

define view entity ZC_CHETU_ATTACH_93
  as projection on ZR_CHETU_ATTACH_93

{
  key AttachUuid,

      TravelUuid,
      Attachment,
      MimeType,
      FileName,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,
      /* Associations */
      _Travel : redirected to parent ZC_CHETU_TRAVEL_93
}
