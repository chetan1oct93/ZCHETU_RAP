@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: '###GENERATED Core Data Service Entity'

@Metadata.allowExtensions: true

define view entity ZC_CHETU_BOOKSP_93
  as projection on ZR_CHETU_BOOKSP_93

{
  key SupplementUuid,

      TravelUuid,
      BookingUuid,

      @Consumption.valueHelpDefinition: [ { entity: { name: '/DMO/I_Supplement_StdVH', element: 'SupplementID' },
                                            additionalBinding: [ { localElement: 'Price',
                                                                   element: 'Price',
                                                                   usage: #RESULT },
                                                                 { localElement: 'CurrencyCode',
                                                                   element: 'CurrencyCode',
                                                                   usage: #RESULT } ],
                                            useForValidation: true } ]
      @ObjectModel.text.element: [ 'SupplementDescription' ]
      SupplementId,

      _SupplementText.Description as SupplementDescription : localized,
      Price,

      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_CurrencyStdVH', element: 'Currency' },
                                            useForValidation: true } ]
      CurrencyCode,

      LastChangedAt,

      /* Associations */
      _Booking : redirected to parent ZC_CHETU_BOOKNG_93,
      _Travel: redirected to ZC_CHETU_TRAVEL_93
}
