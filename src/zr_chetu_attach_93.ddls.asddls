@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'View Entity for Attachment Entity'

@Metadata.allowExtensions: true

define view entity ZR_CHETU_ATTACH_93
  as select from zchetu_attach_93

  association to parent ZR_CHETU_TRAVEL_93 as _Travel on $projection.TravelUuid = _Travel.TravelUuid

{
  key attach_uuid           as AttachUuid,

      travel_uuid           as TravelUuid,

      @Semantics.largeObject: { mimeType: 'MimeType',   //case-sensitive
                                fileName: 'FileName',         //case-sensitive
                                acceptableMimeTypes: ['image/png', 'image/jpeg', 'application/pdf'],
                                contentDispositionPreference: #ATTACHMENT }
      attachment            as Attachment,

      mime_type             as MimeType,
      file_name             as FileName,

      @Semantics.user.createdBy: true
      created_by            as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,

      @Semantics.user.localInstanceLastChangedBy: true
      last_changed_by       as LastChangedBy,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      _Travel
}
