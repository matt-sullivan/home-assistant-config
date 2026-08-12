"""Tuya based cover and blinds."""
from zigpy.profiles import zha
import zigpy.types as t

from zhaquirks.tuya import (
    TUYA_CLUSTER_ID,
    TUYA_DP_ID_CONTROL,
    TUYA_DP_ID_DIRECTION_CHANGE,
    TUYA_DP_ID_PERCENT_CONTROL,
    TUYA_DP_ID_PERCENT_STATE,
    TuyaManufacturerWindowCover,
    TuyaManufCluster,
    TuyaWindowCover,
    TuyaWindowCoverControl,
)
from zhaquirks.tuya.builder import TuyaQuirkBuilder
from zhaquirks.tuya.ts0601_cover import MotorDirection, BorderSetting

TUYA_DP_ID_BATTERY_PERCENT = 0x0D
TUYA_DP_ID_LIMIT_SETTINGS = 0x10
TUYA_DP_ID_SMALL_STEP = 0x14

class SmallStep(t.enum8):
    """Small step direction values."""

    Open = 0x00
    Close = 0x01

(
    # Another tuya window cover device.
    #
    # This variant supports:
    #     - configurable motor direction
    #     - battery percentage remaining
    #     - set and delete open and close limits
    #     - moving a small step open and close
    #
    # "_TZE200_eevqq1uv", "TS0601" - Zemismart ZM25R3 roller blind motor
    TuyaQuirkBuilder("_TZE200_eevqq1uv", "TS0601")
    .applies_to("_TZE200_68nvbio9", "TS0601")
    .tuya_cover(
        control_dp=TUYA_DP_ID_CONTROL,
        position_state_dp=TUYA_DP_ID_PERCENT_STATE,
        position_control_dp=TUYA_DP_ID_PERCENT_CONTROL,
    )
    .tuya_battery(dp_id=TUYA_DP_ID_BATTERY_PERCENT)
    .tuya_enum(
        dp_id=TUYA_DP_ID_DIRECTION_CHANGE,
        attribute_name="motor_direction",
        enum_class=MotorDirection,
        translation_key="motor_direction",
        fallback_name="Motor direction",
    )
    .tuya_dp_attribute(
        dp_id=TUYA_DP_ID_LIMIT_SETTINGS,
        attribute_name="border",
        type=BorderSetting,
    )
    .write_attr_button(
        attribute_name="border",
        attribute_value=BorderSetting.Up,
        cluster_id=TUYA_CLUSTER_ID,
        unique_id_suffix="border_up",
        translation_key="set_upper_limit",
        fallback_name="Set upper limit",
    )
    .write_attr_button(
        attribute_name="border",
        attribute_value=BorderSetting.Down,
        cluster_id=TUYA_CLUSTER_ID,
        unique_id_suffix="border_down",
        translation_key="set_lower_limit",
        fallback_name="Set lower limit",
    )
    .write_attr_button(
        attribute_name="border",
        attribute_value=BorderSetting.Up_delete,
        cluster_id=TUYA_CLUSTER_ID,
        unique_id_suffix="border_up_delete",
        translation_key="delete_upper_limit",
        fallback_name="Delete upper limit",
    )
    .write_attr_button(
        attribute_name="border",
        attribute_value=BorderSetting.Down_delete,
        cluster_id=TUYA_CLUSTER_ID,
        unique_id_suffix="border_down_delete",
        translation_key="delete_lower_limit",
        fallback_name="Delete lower limit",
    )
    .write_attr_button(
        attribute_name="border",
        attribute_value=BorderSetting.Remove_top_bottom,
        cluster_id=TUYA_CLUSTER_ID,
        unique_id_suffix="border_remove_all",
        translation_key="delete_all_limits",
        fallback_name="Delete all limits",
    )
    .tuya_dp_attribute(
        dp_id=TUYA_DP_ID_SMALL_STEP,
        attribute_name="small_step",
        type=SmallStep,
    )
    .write_attr_button(
        attribute_name="small_step",
        attribute_value=SmallStep.Open,
        cluster_id=TUYA_CLUSTER_ID,
        unique_id_suffix="small_step_open",
        translation_key="small_step_open",
        fallback_name="Small step open",
    )
    .write_attr_button(
        attribute_name="small_step",
        attribute_value=SmallStep.Close,
        cluster_id=TUYA_CLUSTER_ID,
        unique_id_suffix="small_step_close",
        translation_key="small_step_close",
        fallback_name="Small step close",
    )
    .skip_configuration()
    .add_to_registry()
)
