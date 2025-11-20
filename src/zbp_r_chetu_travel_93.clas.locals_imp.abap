CLASS lhc_ZrChetuTravel93 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    CONSTANTS:
      BEGIN OF travel_status,
        open     TYPE c LENGTH 1 VALUE 'O', " Open
        accepted TYPE c LENGTH 1 VALUE 'A', " Accepted
        rejected TYPE c LENGTH 1 VALUE 'X', " Rejected
      END OF travel_status.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ZrChetuTravel93 RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR ZrChetuTravel93 RESULT result.
    METHODS precheck_update FOR PRECHECK
      IMPORTING entities FOR UPDATE ZrChetuTravel93.

    METHODS SetStatusToAccepted FOR MODIFY
      IMPORTING keys FOR ACTION ZrChetuTravel93~SetStatusToAccepted RESULT result.
    METHODS SetStatusToRejected FOR MODIFY
      IMPORTING keys FOR ACTION ZrChetuTravel93~SetStatusToRejected RESULT result.
    METHODS DeductDiscount FOR MODIFY
      IMPORTING keys FOR ACTION ZrChetuTravel93~DeductDiscount RESULT result.
    METHODS CopyTravel FOR MODIFY
      IMPORTING keys FOR ACTION ZrChetuTravel93~CopyTravel.
    METHODS ReCalcTotalPrice FOR MODIFY
      IMPORTING keys FOR ACTION ZrChetuTravel93~ReCalcTotalPrice.
    METHODS ValidateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZrChetuTravel93~ValidateDates.

    METHODS CalculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR ZrChetuTravel93~CalculateTotalPrice.
    METHODS SetStatusToOpen FOR DETERMINE ON MODIFY
      IMPORTING keys FOR ZrChetuTravel93~SetStatusToOpen.
    METHODS SetTravelNumber FOR DETERMINE ON SAVE
      IMPORTING keys FOR ZrChetuTravel93~SetTravelNumber.
    METHODS ValidateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZrChetuTravel93~ValidateCustomer.
    METHODS GetDefaultsForDeductDiscount FOR READ
      IMPORTING keys FOR FUNCTION ZrChetuTravel93~GetDefaultsForDeductDiscount RESULT result.

ENDCLASS.


CLASS lhc_ZrChetuTravel93 IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.

  " -------------------------------------------------------------------------
  " Instance-based dynamic feature control
  " -------------------------------------------------------------------------
  METHOD get_instance_features.
    READ ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
         ENTITY ZrChetuTravel93
         FIELDS ( overallstatus )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels)
         FAILED failed.

    result = VALUE #( FOR travel IN travels
                      ( %tky                        = travel-%tky

                        %features-%update           = COND #( WHEN travel-OverallStatus = travel_status-accepted
                                                              THEN if_abap_behv=>fc-o-disabled
                                                              ELSE if_abap_behv=>fc-o-enabled )

                        %features-%delete           = COND #( WHEN travel-OverallStatus = travel_status-open
                                                              THEN if_abap_behv=>fc-o-enabled
                                                              ELSE if_abap_behv=>fc-o-disabled )

                        %action-Edit                = COND #( WHEN travel-OverallStatus = travel_status-accepted
                                                              THEN if_abap_behv=>fc-o-disabled
                                                              ELSE if_abap_behv=>fc-o-enabled )

                        %action-SetStatusToAccepted = COND #( WHEN travel-OverallStatus = travel_status-accepted
                                                              THEN if_abap_behv=>fc-o-disabled
                                                              ELSE if_abap_behv=>fc-o-enabled )

                        %action-SetStatusToRejected = COND #( WHEN travel-OverallStatus = travel_status-rejected
                                                              THEN if_abap_behv=>fc-o-disabled
                                                              ELSE if_abap_behv=>fc-o-enabled )

                        %action-DeductDiscount      = COND #( WHEN travel-OverallStatus = travel_status-open
                                                              THEN if_abap_behv=>fc-o-enabled
                                                              ELSE if_abap_behv=>fc-o-disabled ) ) ).
  ENDMETHOD.

  " -------------------------------------------------------------------------
  " Instance-bound non-factory action:
  " Set the overall status to 'accepted' (A)
  " -------------------------------------------------------------------------
  METHOD SetStatusToAccepted.
    MODIFY ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
           ENTITY ZrChetuTravel93
           UPDATE FROM VALUE #( FOR key IN keys
                                ( TravelUuid             = key-TravelUuid
                                  OverallStatus          = travel_status-accepted " Accepted
                                  %control-OverallStatus = if_abap_behv=>mk-on ) )
           FAILED failed
           REPORTED reported.

    " Read changed data for action result
    READ ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
         ENTITY ZrChetuTravel93
         ALL FIELDS WITH
         CORRESPONDING #( keys )
         RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels
                      ( %tky   = travel-%tky
                        %param = travel ) ).
  ENDMETHOD.

  " -------------------------------------------------------------------------
  " Instance-bound non-factory action:
  " Set the overall status to 'rejected' (A)
  " -------------------------------------------------------------------------
  METHOD SetStatusToRejected.
    MODIFY ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
           ENTITY ZrChetuTravel93
           UPDATE FROM VALUE #( FOR key IN keys
                                ( TravelUuid             = key-TravelUuid
                                  OverallStatus          = travel_status-rejected " Rejected
                                  %control-OverallStatus = if_abap_behv=>mk-on ) )
           FAILED failed
           REPORTED reported.

    " Read changed data for action result
    READ ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
         ENTITY ZrChetuTravel93
         ALL FIELDS WITH
         CORRESPONDING #( keys )
         RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels
                      ( %tky   = travel-%tky
                        %param = travel ) ).
  ENDMETHOD.

  " -------------------------------------------------------------------------
  " Instance-bound non-factory action:
  " Deduct the specified discount from the booking fee (BookingFee)
  " -------------------------------------------------------------------------
  METHOD DeductDiscount.
    DATA travels_for_update TYPE TABLE FOR UPDATE zr_chetu_travel_93.

    DATA(keys_with_valid_discount) = keys.

    " check and handle invalid discount values
    LOOP AT keys_with_valid_discount ASSIGNING FIELD-SYMBOL(<key_with_valid_discount>)
         WHERE %param-discount_percent IS INITIAL OR %param-discount_percent > 100 OR %param-discount_percent <= 0.

      " report invalid discount value appropriately
      APPEND VALUE #( %tky = <key_with_valid_discount>-%tky ) TO failed-zrchetutravel93.

      APPEND VALUE #( %tky                       = <key_with_valid_discount>-%tky
                      %msg                       = NEW /dmo/cm_flight_messages(
                                                           textid   = /dmo/cm_flight_messages=>discount_invalid
                                                           severity = if_abap_behv_message=>severity-error )
                      %element-TotalPrice        = if_abap_behv=>mk-on  " Indicates the exact field or element within a BO instance that caused an error.
                      %op-%action-deductDiscount = if_abap_behv=>mk-on ) " Indicates that the message was caused by a custom action deductDiscount
             TO reported-zrchetutravel93.

      " remove invalid discount value
      DELETE keys_with_valid_discount.
    ENDLOOP.

    " check and go ahead with valid discount values
    IF keys_with_valid_discount IS INITIAL.
      RETURN.
    ENDIF.

    " read relevant travel instance data (only booking fee)
    READ ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
         ENTITY ZrChetuTravel93
         FIELDS ( BookingFee )
         WITH CORRESPONDING #( keys_with_valid_discount )
         RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      DATA percentage TYPE decfloat16.
      DATA(discount_percent) = keys_with_valid_discount[ KEY draft
                                                         %tky = <travel>-%tky ]-%param-discount_percent.
      percentage = discount_percent / 100.
      DATA(reduced_fee) = <travel>-BookingFee * ( 1 - percentage ).

      APPEND VALUE #( %tky       = <travel>-%tky
                      BookingFee = reduced_fee )
             TO travels_for_update.
    ENDLOOP.

    " update data with reduced fee
    MODIFY ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
           ENTITY ZrChetuTravel93
           UPDATE FIELDS ( BookingFee )
           WITH travels_for_update.

    " read changed data for action result
    READ ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
         ENTITY ZrChetuTravel93
         ALL FIELDS
         WITH CORRESPONDING #( travels )
         RESULT DATA(travels_with_discount).

    " set action result
    result = VALUE #( FOR travel IN travels_with_discount
                      ( %tky   = travel-%tky
                        %param = travel ) ).
  ENDMETHOD.

  " -------------------------------------------------------------------------
  " Instance-bound factory action:
  " Copy travel entity and create a new entity
  " -------------------------------------------------------------------------
  METHOD CopyTravel.
    DATA new_travels  TYPE TABLE FOR CREATE zr_chetu_travel_93\\ZrChetuTravel93.
    DATA new_bookings TYPE TABLE FOR CREATE zr_chetu_travel_93\\ZrChetuTravel93\_Booking.

    " remove travel instances with initial %cid (i.e., not set by caller API)
    READ TABLE keys WITH KEY %cid = '' INTO DATA(key_with_inital_cid).
    ASSERT key_with_inital_cid IS INITIAL.

    " read the data from the travel instances to be copied
    READ ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
         ENTITY ZrChetuTravel93 ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(travels)
         FAILED failed.

    READ ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
         ENTITY ZrChetuTravel93 BY \_Booking ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(bookings)
         FAILED failed.

    "%CID -Content ID is temporary key for an instance,its valid till actual primary key is not generated by runtime.
    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      " fill in travel container for creating new travel instance
      APPEND VALUE #( %cid      = keys[ KEY draft
                                        %tky = <travel>-%tky ]-%cid
                      %is_draft = keys[ KEY draft
                                        %tky = <travel>-%tky ]-%is_draft
                      %data     = CORRESPONDING #( <travel> EXCEPT TravelUuid TravelId ) )
             TO new_travels ASSIGNING FIELD-SYMBOL(<new_travel>).

      "%CID_REF - Specifies reference to content ID. If need to refer header and child record then %CID_REF is populated with header %CID value.
      " Fill %cid of travel as instance identifier for %cid_ref of cba booking
      APPEND VALUE #( %cid_ref = keys[ KEY draft
                                       %tky = <travel>-%tky ]-%cid )
             TO new_bookings ASSIGNING FIELD-SYMBOL(<bookings_cba>).

      " adjust the copied travel instance data
      " BeginDate must be on or after system date
      <new_travel>-BeginDate     = cl_abap_context_info=>get_system_date( ).
      " EndDate must be after BeginDate
      <new_travel>-EndDate       = cl_abap_context_info=>get_system_date( ) + 30.
      " OverallStatus of new instances must be set to open ('O')
      <new_travel>-OverallStatus = travel_status-open.

      LOOP AT bookings ASSIGNING FIELD-SYMBOL(<booking>) WHERE TravelUuid = <travel>-TravelUuid.
        " Fill booking container for creating booking with cba
        APPEND VALUE #( %cid  = keys[ KEY draft
                                      %tky = <travel>-%tky ]-%cid && <booking>-BookingUuid
                        %data = CORRESPONDING #(  bookings[ KEY draft
                                                            %tky = <booking>-%tky ] EXCEPT BookingUuid TravelUuid ) )
               TO <bookings_cba>-%target ASSIGNING FIELD-SYMBOL(<new_booking>).

        <new_booking>-BookingStatus = 'N'.
      ENDLOOP.
    ENDLOOP.

    " create new BO instance
    MODIFY ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
           ENTITY ZrChetuTravel93
           CREATE FIELDS ( AgencyID CustomerID BeginDate EndDate BookingFee
                             TotalPrice CurrencyCode OverallStatus Description )
           WITH new_travels
           CREATE BY \_Booking FIELDS ( BookingId BookingDate CustomerId CarrierId ConnectionId
                                       FlightDate FlightPrice CurrencyCode BookingStatus )
           WITH new_bookings
           MAPPED DATA(mapped_create).

    " set the new BO instances
    mapped-zrchetutravel93 = mapped_create-zrchetutravel93.
  ENDMETHOD.

  " -------------------------------------------------------------------------
  " Determination:
  " Set the overall status to 'open' (O) on modify.
  " -------------------------------------------------------------------------
  METHOD SetStatusToOpen.
    " Read travel instances of the transferred keys
    READ ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
         ENTITY ZrChetuTravel93
         FIELDS ( OverallStatus )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels)
         " TODO: variable is assigned but never used (ABAP cleaner)
         FAILED DATA(read_failed).

    " If overall travel status is already set, do nothing, i.e. remove such instances
    DELETE travels WHERE OverallStatus IS NOT INITIAL.
    IF travels IS INITIAL.
      RETURN.
    ENDIF.

    " else set overall travel status to open ('O')
    MODIFY ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
           ENTITY ZrChetuTravel93
           UPDATE FIELDS ( OverallStatus )
           WITH VALUE #( FOR travel IN travels
                         ( %tky          = travel-%tky
                           OverallStatus = travel_status-open ) )
           REPORTED DATA(update_reported).

    " Set the changing parameter
    reported = CORRESPONDING #( DEEP update_reported ).
  ENDMETHOD.

  " -------------------------------------------------------------------------
  " Validation:
  " Validate begin dates and end dates on save button.
  " -------------------------------------------------------------------------
  METHOD ValidateDates.
    READ ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
         ENTITY ZrChetuTravel93
         FIELDS ( BeginDate EndDate )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel).

      APPEND VALUE #( %tky        = travel-%tky
                      %state_area = 'VALIDATE_DATES' ) TO reported-zrchetutravel93.

      IF travel-BeginDate IS INITIAL.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-zrchetutravel93.

        APPEND VALUE #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = NEW /dmo/cm_flight_messages(
                                                     textid   = /dmo/cm_flight_messages=>enter_begin_date
                                                     severity = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on ) TO reported-zrchetutravel93.

      ENDIF.

      IF travel-BeginDate < cl_abap_context_info=>get_system_date( ) AND travel-BeginDate IS NOT INITIAL.

        APPEND VALUE #( %tky = travel-%tky ) TO failed-zrchetutravel93.

        APPEND VALUE #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = NEW /dmo/cm_flight_messages(
                                                     begin_date = travel-BeginDate
                                                     textid     = /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
                                                     severity   = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on ) TO reported-zrchetutravel93.

      ENDIF.

      IF travel-EndDate IS INITIAL.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-zrchetutravel93.

        APPEND VALUE #( %tky             = travel-%tky
                        %state_area      = 'VALIDATE_DATES'
                        %msg             = NEW /dmo/cm_flight_messages(
                                                   textid   = /dmo/cm_flight_messages=>enter_end_date
                                                   severity = if_abap_behv_message=>severity-error )
                        %element-EndDate = if_abap_behv=>mk-on ) TO reported-zrchetutravel93.
      ENDIF.

      IF     travel-EndDate  < travel-BeginDate AND travel-BeginDate IS NOT INITIAL
         AND travel-EndDate IS NOT INITIAL.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-zrchetutravel93.

        APPEND VALUE #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = NEW /dmo/cm_flight_messages(
                                                     textid     = /dmo/cm_flight_messages=>begin_date_bef_end_date
                                                     begin_date = travel-BeginDate
                                                     end_date   = travel-EndDate
                                                     severity   = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on
                        %element-EndDate   = if_abap_behv=>mk-on ) TO reported-zrchetutravel93.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  " -------------------------------------------------------------------------
  " Validation:
  " Validate length of description in real time.
  " -------------------------------------------------------------------------
  METHOD precheck_update.
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<travel>).
      IF <travel>-Description IS INITIAL OR strlen( <travel>-Description ) > 10.
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky    = <travel>-%tky
                      %update = if_abap_behv=>mk-on ) TO failed-zrchetutravel93.

      APPEND VALUE #(
          %tky                 = <travel>-%tky
          %msg                 = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = 'Description should be more than 10 characters' )
          %update              = if_abap_behv=>mk-on
          %element-Description = if_abap_behv=>mk-on ) TO reported-zrchetutravel93.
    ENDLOOP.
  ENDMETHOD.

  " -------------------------------------------------------------------------
  " Determination:
  " Determination to calculate the Total Price when Booking Fee
  "  has changed is added.
  " -------------------------------------------------------------------------
  METHOD CalculateTotalPrice.
    MODIFY ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
           ENTITY ZrChetuTravel93
           EXECUTE ReCalcTotalPrice
           FROM CORRESPONDING #( keys ).
  ENDMETHOD.

  " -------------------------------------------------------------------------
  " Instance-bound internal action:
  " Recalculate price
  " -------------------------------------------------------------------------
  METHOD ReCalcTotalPrice.
    TYPES: BEGIN OF ty_amount_per_currencycode,
             amount        TYPE /dmo/total_price,
             currency_code TYPE /dmo/currency_code,
           END OF ty_amount_per_currencycode.

    DATA amount_per_currencycode TYPE STANDARD TABLE OF ty_amount_per_currencycode.

    READ ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
         ENTITY ZrChetuTravel93
         FIELDS ( BookingFee CurrencyCode )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_travels).

    DELETE lt_travels WHERE CurrencyCode IS INITIAL.
    LOOP AT lt_travels ASSIGNING FIELD-SYMBOL(<fs_travel>).
      " Set the start for the calculation by adding the booking fee.
      amount_per_currencycode = VALUE #( ( amount        = <fs_travel>-BookingFee
                                           currency_code = <fs_travel>-CurrencyCode ) ).

      READ ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
           ENTITY ZrChetuTravel93
           BY \_Booking
           FIELDS ( FlightPrice CurrencyCode )
           WITH VALUE #( ( %tky = <fs_travel>-%tky ) )
           RESULT DATA(lt_bookings).

      LOOP AT lt_bookings ASSIGNING FIELD-SYMBOL(<fs_booking>).
        COLLECT VALUE ty_amount_per_currencycode( amount        = <fs_booking>-FlightPrice
                                                  currency_code = <fs_booking>-CurrencyCode )
                INTO amount_per_currencycode.
      ENDLOOP.

      CLEAR <fs_travel>-TotalPrice.
      LOOP AT amount_per_currencycode INTO DATA(single_amount_per_currencycode).
        " If needed do a Currency Conversion
        IF single_amount_per_currencycode-currency_code = <fs_travel>-CurrencyCode.
          <fs_travel>-TotalPrice += single_amount_per_currencycode-amount.
        ELSE.
          /dmo/cl_flight_amdp=>convert_currency(
            EXPORTING iv_amount               = single_amount_per_currencycode-amount
                      iv_currency_code_source = single_amount_per_currencycode-currency_code
                      iv_currency_code_target = <fs_travel>-CurrencyCode
                      iv_exchange_rate_date   = cl_abap_context_info=>get_system_date( )
            IMPORTING ev_amount               = DATA(total_booking_price_per_curr) ).
          <fs_travel>-TotalPrice += total_booking_price_per_curr.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    MODIFY ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
           ENTITY ZrChetuTravel93
           UPDATE FIELDS ( TotalPrice )
           WITH CORRESPONDING #( lt_travels ).
  ENDMETHOD.

  " -------------------------------------------------------------------------
  " Determination:
  " Determination to set the Travel Id number on save.
  " -------------------------------------------------------------------------
  METHOD SetTravelNumber.
    DATA travel_id_max TYPE /dmo/travel_id.

    " Ensure idempotence
    READ ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
         ENTITY ZrChetuTravel93
         FIELDS ( TravelID )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    DATA(entities_wo_travelid) = travels.
    DELETE entities_wo_travelid WHERE TravelID IS NOT INITIAL.
    IF entities_wo_travelid IS INITIAL.
      RETURN.
    ENDIF.

    " Get Numbers
    TRY.
        cl_numberrange_runtime=>number_get( EXPORTING nr_range_nr       = '01'
                                                      object            = '/DMO/TRV_M'
                                                      quantity          = CONV #( lines( entities_wo_travelid ) )
                                            IMPORTING number            = DATA(number_range_key)
                                                      returncode        = DATA(number_range_return_code)
                                                      returned_quantity = DATA(number_range_returned_quantity) ).
      CATCH cx_number_ranges INTO DATA(lx_number_ranges).
        LOOP AT entities_wo_travelid INTO DATA(entity).
          APPEND VALUE #( %tky = entity-%tky
                          %msg = lx_number_ranges )
                 TO reported-zrchetutravel93.
        ENDLOOP.
        RETURN.
    ENDTRY.

    CASE number_range_return_code.
      WHEN '1'.
        " 1 - the returned number is in a critical range (specified under “percentage warning” in the object definition)
        LOOP AT entities_wo_travelid INTO entity.
          APPEND VALUE #( %tky = entity-%tky
                          %msg = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>number_range_depleted
                                                              severity = if_abap_behv_message=>severity-warning ) )
                 TO reported-zrchetutravel93.
        ENDLOOP.

      WHEN '2' OR '3'.
        " 2 - the last number of the interval was returned
        " 3 - if fewer numbers are available than requested,  the return code is 3
        LOOP AT entities_wo_travelid INTO entity.
          APPEND VALUE #( %tky = entity-%tky
                          %msg = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>not_sufficient_numbers
                                                              severity = if_abap_behv_message=>severity-warning ) )
                 TO reported-zrchetutravel93.
        ENDLOOP.
        RETURN.
    ENDCASE.

    " At this point ALL entities get a number!
    ASSERT number_range_returned_quantity = lines( entities_wo_travelid ).
    travel_id_max = number_range_key - number_range_returned_quantity.

    " update involved instances
    MODIFY ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
           ENTITY ZrChetuTravel93
           UPDATE FIELDS ( TravelID )
           WITH VALUE #( FOR travel IN travels INDEX INTO i
                         ( %tky     = travel-%tky
                           TravelId = travel_id_max + i ) ).
  ENDMETHOD.

  " -------------------------------------------------------------------------
  " Validation:
  " Validate to validate customer number.
  " -------------------------------------------------------------------------
  METHOD ValidateCustomer.
    READ ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
         ENTITY ZrChetuTravel93
         FIELDS ( CustomerId )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_travels).

    DATA customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    " Optimization of DB select: extract distinct non-initial customer IDs
    customers = CORRESPONDING #( lt_travels DISCARDING DUPLICATES MAPPING customer_id = CustomerId EXCEPT * ).
    DELETE customers WHERE customer_id IS INITIAL.

    IF customers IS NOT INITIAL.
      " Check if customer ID is valid
      SELECT FROM /dmo/customer
        FIELDS customer_id
        FOR ALL ENTRIES IN @customers
        WHERE customer_id = @customers-customer_id
        INTO TABLE @DATA(lt_valid_customers).
    ENDIF.

    LOOP AT lt_travels INTO DATA(ls_travel).

      APPEND VALUE #( %tky        = ls_travel-%tky
                      %state_area = 'VALIDATE_CUSTOMER' )
             TO reported-zrchetutravel93.

      IF ls_travel-CustomerId IS INITIAL.

        APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-zrchetutravel93.

        APPEND VALUE #(
            %tky                = ls_travel-%tky
            %state_area         = 'VALIDATE_CUSTOMER'
            %msg                = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>enter_customer_id
                                                               severity = if_abap_behv_message=>severity-error )

            %element-customerid = if_abap_behv=>mk-on )
               TO reported-zrchetutravel93.
      ELSEIF ls_travel-CustomerID IS NOT INITIAL AND NOT line_exists(
                                                             lt_valid_customers[ customer_id = ls_travel-customerid ] ).
        APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-zrchetutravel93.

        APPEND VALUE #( %tky                = ls_travel-%tky
                        %state_area         = 'VALIDATE_CUSTOMER'
                        %msg                = NEW /dmo/cm_flight_messages(
                                                      customer_id = ls_travel-customerid
                                                      textid      = /dmo/cm_flight_messages=>customer_unkown
                                                      severity    = if_abap_behv_message=>severity-error )
                        %element-CustomerID = if_abap_behv=>mk-on )
               TO reported-zrchetutravel93.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD GetDefaultsForDeductDiscount.
    READ ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
         ENTITY ZrChetuTravel93
         FIELDS ( TravelUuid )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_travels).

    LOOP AT lt_travels INTO DATA(ls_travel).
      APPEND VALUE #( %tky                    = ls_travel-%tky
                      %param-discount_percent = 15 )
             TO result.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.


CLASS lhc_zrchetubookng93 DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    METHODS CalculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR ZrChetuBookng93~CalculateTotalPrice.
    METHODS SetBookingNumber FOR DETERMINE ON SAVE
      IMPORTING keys FOR ZrChetuBookng93~SetBookingNumber.
    METHODS SetCustomerId FOR DETERMINE ON MODIFY
      IMPORTING keys FOR ZrChetuBookng93~SetCustomerId.
    METHODS UploadData FOR MODIFY
      IMPORTING keys FOR ACTION ZrChetuBookng93~UploadData RESULT result.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ZrChetuBookng93 RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR ZrChetuBookng93 RESULT result.

ENDCLASS.


CLASS lhc_zrchetubookng93 IMPLEMENTATION.
  " -------------------------------------------------------------------------
  " Determination:
  " Determination to calculate the Total Price when FlightPrice is changed,
  " a new booking is created, or a booking is deleted
  " -------------------------------------------------------------------------
  METHOD CalculateTotalPrice.
    " Read all travels for the requested bookings
    " If multiple bookings of the same travel are requested, the travel is returned only once.
    READ ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
         ENTITY ZrChetuBookng93 BY \_Travel
         FIELDS ( TravelUUID )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_travels).

    " update involved instances
    MODIFY ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
           ENTITY ZrChetuTravel93
           EXECUTE recalctotalprice
           FROM CORRESPONDING #( lt_travels ).
  ENDMETHOD.

  METHOD SetBookingNumber.
    DATA max_bookingid   TYPE /dmo/booking_id.
    DATA bookings_update TYPE TABLE FOR UPDATE zr_chetu_travel_93\\ZrChetuBookng93.

    " Read all travels for the requested bookings
    " If multiple bookings of the same travel are requested, the travel is returned only once.
    READ ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
         ENTITY ZrChetuBookng93 BY \_Travel
         FIELDS ( TravelUUID )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    " Process all affected travels. Read respective bookings for one travel
    LOOP AT travels INTO DATA(travel).
      READ ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
           ENTITY ZrChetuTravel93 BY \_Booking
           FIELDS ( BookingID )
           WITH VALUE #( ( %tky = travel-%tky ) )
           RESULT DATA(bookings).

      " find max used bookingID in all bookings of this travel
      max_bookingid = '0000'.
      LOOP AT bookings INTO DATA(booking).
        IF booking-BookingID > max_bookingid.
          max_bookingid = booking-BookingID.
        ENDIF.
      ENDLOOP.

      " Provide a booking ID for all bookings of this travel that have none.
      LOOP AT bookings INTO booking WHERE BookingID IS INITIAL.
        max_bookingid += 1.
        APPEND VALUE #( %tky      = booking-%tky
                        BookingID = max_bookingid )
               TO bookings_update.
      ENDLOOP.
    ENDLOOP.

    " Provide a booking ID for all bookings that have none.
    MODIFY ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
           ENTITY ZrChetuBookng93
           UPDATE FIELDS ( BookingID )
           WITH bookings_update.
  ENDMETHOD.

  METHOD SetCustomerId.
    READ ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
         ENTITY ZrChetuBookng93 BY \_Travel
         ALL FIELDS " FIELDS ( CustomerId )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    IF travels[ 1 ]-customerId IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
           ENTITY ZrChetuBookng93
           UPDATE FIELDS ( CustomerId )
           WITH VALUE #( FOR key IN keys
                         ( %tky                = key-%tky
                           CustomerId          = travels[ 1 ]-CustomerId
                           %control-CustomerId = if_abap_behv=>mk-on ) )
           REPORTED DATA(update_reported).

    " Set the changing parameter
    reported = CORRESPONDING #( DEEP update_reported ).
  ENDMETHOD.

  METHOD UploadData.
    TYPES : BEGIN OF ty_sheet_data,
              SupplementId TYPE zr_chetu_booksp_93-SupplementId,
              Price        TYPE zr_chetu_booksp_93-Price,
              CurrencyCode TYPE zr_chetu_booksp_93-CurrencyCode,
            END OF ty_sheet_data.
    DATA lt_sheet_data  TYPE STANDARD TABLE OF ty_sheet_data.
    DATA new_supplement TYPE TABLE FOR CREATE zr_chetu_travel_93\\ZrChetuBookng93\_Supplement.

    DATA(lv_file_content) = VALUE #( keys[ 1 ]-%param-_streamproperties-attachment OPTIONAL ).
    DATA(lo_document) = xco_cp_xlsx=>document->for_file_content( lv_file_content )->read_access( ).

    DATA(lo_worksheet) = lo_document->get_workbook( )->worksheet->at_position( 1 ).

    DATA(o_sel_pattern) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to(
      )->from_column( xco_cp_xlsx=>coordinate->for_alphabetic_value( 'A' )  " Start reading from Column A
      )->to_column( xco_cp_xlsx=>coordinate->for_alphabetic_value( 'C' )   " End reading at Column N
      )->from_row( xco_cp_xlsx=>coordinate->for_numeric_value( 2 )    " *** Start reading from ROW 2 to skip the header ***
      )->get_pattern( ).

    lo_worksheet->select( o_sel_pattern
                               )->row_stream(
                               )->operation->write_to( REF #( lt_sheet_data )
                               )->set_value_transformation( xco_cp_xlsx_read_access=>value_transformation->string_value
                               )->execute( ).

    READ ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
         ENTITY ZrChetuBookng93 ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(bookings)
         FAILED failed.

    APPEND VALUE #( %tky = keys[ KEY draft
                                 %tky = bookings[ 1 ]-%tky ]-%tky )
           TO new_supplement ASSIGNING FIELD-SYMBOL(<new_supplement>).

    LOOP AT lt_sheet_data ASSIGNING FIELD-SYMBOL(<fs_sheet_data>).
      APPEND VALUE #( %cid         = keys[ KEY draft
                                           %tky = bookings[ 1 ]-%tky ]-%cid_ref && |CID{ sy-tabix }|
                      %is_draft    = keys[ KEY draft
                                           %tky = bookings[ 1 ]-%tky ]-%is_draft
                      SupplementID = <fs_sheet_data>-SupplementID
                      Price        = <fs_sheet_data>-Price
                      CurrencyCode = <fs_sheet_data>-CurrencyCode
                      TravelUUID   = bookings[ 1 ]-TravelUuid
                      BookingUUID  = bookings[ 1 ]-BookingUuid )
             TO <new_supplement>-%target.
    ENDLOOP.

    MODIFY ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
           ENTITY ZrChetuBookng93
           CREATE BY \_Supplement FIELDS ( SupplementId Price CurrencyCode )
           WITH new_supplement
           FAILED DATA(lt_failed).

    READ ENTITIES OF zr_chetu_travel_93 IN LOCAL MODE
         ENTITY ZrChetuBookng93 BY \_Supplement ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(lt_supplements).

    result = VALUE #( FOR supplement IN lt_supplements
                      ( %is_draft = supplement-%is_draft
                        %param    = supplement ) ).

    IF lt_failed IS NOT INITIAL.
      APPEND VALUE #( %tky               = bookings[ 1 ]-%tky ) TO failed-zrchetubookng93.

      APPEND VALUE #( %tky                 = bookings[ 1 ]-%tky
                      %msg                 = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                                    text     = 'Error uploading Supplements' )
                      %element-_supplement = if_abap_behv=>mk-on
                      %action-uploaddata   = if_abap_behv=>mk-on )
             TO reported-zrchetubookng93.

    ELSE.
      APPEND VALUE #( %tky                 = result[ 1 ]-%tky
                      %msg                 = new_message_with_text( severity = if_abap_behv_message=>severity-success
                                                                    text     = 'Supplements have been uploaded' )
                      %element-_supplement = if_abap_behv=>mk-on
                      %action-uploaddata   = if_abap_behv=>mk-on )
             TO reported-zrchetubookng93.
    ENDIF.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD get_instance_features.
  ENDMETHOD.
ENDCLASS.
