@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'View Entity for Suppliments Entity'

@Metadata.allowExtensions: true

define view entity ZR_CHETU_BOOKSP_93
  as select from zchetu_booksp_93

  association        to parent ZR_CHETU_BOOKNG_93    as _Booking        on $projection.BookingUuid = _Booking.BookingUuid

  association [1..1] to        ZR_CHETU_TRAVEL_93    as _Travel         on $projection.TravelUuid = _Travel.TravelUuid
  association [1..1] to        /DMO/I_Supplement     as _Product        on $projection.SupplementId = _Product.SupplementID
  association [1..*] to        /DMO/I_SupplementText as _SupplementText on $projection.SupplementId = _SupplementText.SupplementID

{
  key supplement_uuid as SupplementUuid,

      travel_uuid     as TravelUuid,
      booking_uuid    as BookingUuid,
      supplement_id   as SupplementId,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      price           as Price,

      currency_code   as CurrencyCode,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at as LastChangedAt,

      _Travel,
      _Booking,
      _Product,
      _SupplementText
}
