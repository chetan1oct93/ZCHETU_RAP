CLASS zbgpf_chetu_travel_93 DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_bgmc_operation.
    INTERFACES if_bgmc_op_single.
    INTERFACES if_bgmc_op_single_tx_uncontr.
    INTERFACES if_serializable_object.

    TYPES: BEGIN OF ts_rap_bo_entity_key,
             traveluuid TYPE sysuuid_x16,
           END OF ts_rap_bo_entity_key.

    CLASS-METHODS run_via_bgpf
      IMPORTING i_rap_bo_entity_key             TYPE ts_rap_bo_entity_key
      RETURNING VALUE(r_process_monitor_string) TYPE string
      RAISING   cx_bgmc.

    CLASS-METHODS run_via_bgpf_tx_uncontrolled
      IMPORTING i_rap_bo_entity_key             TYPE   ts_rap_bo_entity_key
      RETURNING VALUE(r_process_monitor_string) TYPE string
      RAISING   cx_bgmc.

    METHODS constructor
      IMPORTING i_rap_bo_entity_key TYPE ts_rap_bo_entity_key.

  PRIVATE SECTION.
    DATA travel_uuid TYPE ts_rap_bo_entity_key-traveluuid.
ENDCLASS.


CLASS zbgpf_chetu_travel_93 IMPLEMENTATION.
  METHOD constructor.
    travel_uuid = i_rap_bo_entity_key-traveluuid.
  ENDMETHOD.

  METHOD if_bgmc_op_single_tx_uncontr~execute.
    INSERT zchetu_bgpf FROM @( VALUE #( travel_uuid = travel_uuid ) ).
  ENDMETHOD.

  METHOD if_bgmc_op_single~execute.
    " implement if controlled behavior is needed
  ENDMETHOD.

  METHOD run_via_bgpf.
    TRY.
        DATA(process_monitor) = cl_bgmc_process_factory=>get_default( )->create(
                                              )->set_name( |Calculate inventory data|
                                              )->set_operation(
                                                  NEW zbgpf_chetu_travel_93( i_rap_bo_entity_key = i_rap_bo_entity_key )
                                              )->save_for_execution( ).

        r_process_monitor_string = process_monitor->to_string( ).

      CATCH cx_bgmc INTO DATA(lx_bgmc). " TODO: variable is assigned but never used (ABAP cleaner)

    ENDTRY.
  ENDMETHOD.

  METHOD run_via_bgpf_tx_uncontrolled.
    TRY.
        DATA(process_monitor) = cl_bgmc_process_factory=>get_default( )->create(
                                              )->set_name( |Send email via BGPF|
                                              )->set_operation_tx_uncontrolled(
                                                  NEW zbgpf_chetu_travel_93( i_rap_bo_entity_key = i_rap_bo_entity_key )
                                              )->save_for_execution( ).

        r_process_monitor_string = process_monitor->to_string( ).

      CATCH cx_bgmc INTO DATA(lx_bgmc). " TODO: variable is assigned but never used (ABAP cleaner)
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
