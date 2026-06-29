local hid_sctrl = Proto('hid_sctrl', 'HID Steam Controller')

-- from SDL enum FeatureReportMessageIDs
local ID_SET_DIGITAL_MAPPINGS = 0x80
local ID_CLEAR_DIGITAL_MAPPINGS = 0x81
local ID_GET_DIGITAL_MAPPINGS = 0x82
local ID_GET_ATTRIBUTES_VALUES = 0x83
local ID_GET_ATTRIBUTE_LABEL = 0x84
local ID_SET_DEFAULT_DIGITAL_MAPPINGS = 0x85
local ID_FACTORY_RESET = 0x86
local ID_SET_SETTINGS_VALUES = 0x87
local ID_CLEAR_SETTINGS_VALUES = 0x88
local ID_GET_SETTINGS_VALUES = 0x89
local ID_GET_SETTING_LABEL = 0x8A
local ID_GET_SETTINGS_MAXS = 0x8B
local ID_GET_SETTINGS_DEFAULTS = 0x8C
local ID_SET_CONTROLLER_MODE = 0x8D
local ID_LOAD_DEFAULT_SETTINGS = 0x8E
local ID_TRIGGER_HAPTIC_PULSE = 0x8F
-- referenced in firmware updater and in firmware
local ID_REBOOT_TO_BOOTLOADER = 0x90
-- from SDL, also referenced in firmware
local ID_TURN_OFF_CONTROLLER = 0x9F

local feature_report_message_ids = {
  [ID_SET_DIGITAL_MAPPINGS] = 'ID_SET_DIGITAL_MAPPINGS',
  [ID_CLEAR_DIGITAL_MAPPINGS] = 'ID_CLEAR_DIGITAL_MAPPINGS',
  [ID_GET_DIGITAL_MAPPINGS] = 'ID_GET_DIGITAL_MAPPINGS',
  [ID_GET_ATTRIBUTES_VALUES] = 'ID_GET_ATTRIBUTES_VALUES',
  [ID_GET_ATTRIBUTE_LABEL] = 'ID_GET_ATTRIBUTE_LABEL',
  [ID_SET_DEFAULT_DIGITAL_MAPPINGS] = 'ID_SET_DEFAULT_DIGITAL_MAPPINGS',
  [ID_FACTORY_RESET] = 'ID_FACTORY_RESET',
  [ID_SET_SETTINGS_VALUES] = 'ID_SET_SETTINGS_VALUES',
  [ID_CLEAR_SETTINGS_VALUES] = 'ID_CLEAR_SETTINGS_VALUES',
  [ID_GET_SETTINGS_VALUES] = 'ID_GET_SETTINGS_VALUES',
  [ID_GET_SETTING_LABEL] = 'ID_GET_SETTING_LABEL',
  [ID_GET_SETTINGS_MAXS] = 'ID_GET_SETTINGS_MAXS',
  [ID_GET_SETTINGS_DEFAULTS] = 'ID_GET_SETTINGS_DEFAULTS',
  [ID_SET_CONTROLLER_MODE] = 'ID_SET_CONTROLLER_MODE',
  [ID_LOAD_DEFAULT_SETTINGS] = 'ID_LOAD_DEFAULT_SETTINGS',
  [ID_TRIGGER_HAPTIC_PULSE] = 'ID_TRIGGER_HAPTIC_PULSE',
  [ID_REBOOT_TO_BOOTLOADER] = 'ID_REBOOT_TO_BOOTLOADER',
  [ID_TURN_OFF_CONTROLLER] = 'ID_TURN_OFF_CONTROLLER',
}

-- from HID descriptor, lizard mode reports
local ID_TRITON_LIZARD_MOUSE = 0x40
local ID_TRITON_LIZARD_KEYBOARD = 0x41
-- from SDL: enum ETritonReportIDTypes
local ID_TRITON_CONTROLLER_STATE = 0x42 -- doesn't seem to be used?
local ID_TRITON_BATTERY_STATUS = 0x43
-- note: report id 0x44 is reported in HID descriptor, might be haptics effect 6 ack
local ID_TRITON_AUDIO_BUFFER_FEEDBACK = 0x44
local ID_TRITON_CONTROLLER_STATE_BLE = 0x45
local ID_TRITON_WIRELESS_STATUS_X = 0x46
-- note: according to SDL this one is sent with touchpad TS but I haven't actually
-- seen it get sent
local ID_TRITON_CONTROLLER_STATE_TIMESTAMP = 0x47
local ID_TRITON_WIRELESS_STATUS = 0x79
-- note: 0x7B is sent only when using the puck, seems to also be wireless status?
local ID_TRITON_PUCK_WIRELESS_STATUS = 0x7B

-- from SDL: enum ValveTritonOutReportMessageIDs
local ID_OUT_HAPTIC_RUMBLE = 0x80
local ID_OUT_HAPTIC_PULSE = 0x81
local ID_OUT_HAPTIC_COMMAND = 0x82
local ID_OUT_HAPTIC_LFO_TONE = 0x83
local ID_OUT_HAPTIC_LOG_SWEEP = 0x84
local ID_OUT_HAPTIC_SCRIPT = 0x85
-- not from SDL
local ID_OUT_STREAM_CONFIGURE = 0x86
-- push data for one actuator, full length
local ID_OUT_STREAM_PUSH_DATA_FULL = 0x87
-- push data for INT_LEFT and INT_RIGHT
local ID_OUT_STREAM_PUSH_DATA_INT_2CH = 0x88
-- report 0x87 but with an explicit length byte (when not pushing full length)
local ID_OUT_STREAM_PUSH_DATA_PARTIAL = 0x89

local interrupt_report_ids = {
  [ID_TRITON_LIZARD_MOUSE] = 'ID_TRITON_LIZARD_MOUSE',
  [ID_TRITON_LIZARD_KEYBOARD] = 'ID_TRITON_LIZARD_KEYBOARD',
  [ID_TRITON_CONTROLLER_STATE] = 'ID_TRITON_CONTROLLER_STATE',
  [ID_TRITON_BATTERY_STATUS] = 'ID_TRITON_BATTERY_STATUS',
  [ID_TRITON_CONTROLLER_STATE_BLE] = 'ID_TRITON_CONTROLLER_STATE_BLE',
  [ID_TRITON_WIRELESS_STATUS_X] = 'ID_TRITON_WIRELESS_STATUS_X',
  [ID_TRITON_CONTROLLER_STATE_TIMESTAMP] = 'ID_TRITON_CONTROLLER_STATE_TIMESTAMP',
  [ID_TRITON_WIRELESS_STATUS] = 'ID_TRITON_WIRELESS_STATUS',
  [ID_TRITON_PUCK_WIRELESS_STATUS] = 'ID_TRITON_PUCK_WIRELESS_STATUS',

  [ID_OUT_HAPTIC_RUMBLE] = 'ID_OUT_HAPTIC_RUMBLE',
  [ID_OUT_HAPTIC_PULSE] = 'ID_OUT_HAPTIC_PULSE',
  [ID_OUT_HAPTIC_COMMAND] = 'ID_OUT_HAPTIC_COMMAND',
  [ID_OUT_HAPTIC_LFO_TONE] = 'ID_OUT_HAPTIC_LFO_TONE',
  [ID_OUT_HAPTIC_LOG_SWEEP] = 'ID_OUT_HAPTIC_LOG_SWEEP',
  [ID_OUT_HAPTIC_SCRIPT] = 'ID_OUT_HAPTIC_SCRIPT',
  [ID_OUT_STREAM_CONFIGURE] = 'ID_OUT_STREAM_CONFIGURE',
  [ID_OUT_STREAM_PUSH_DATA_FULL] = 'ID_OUT_STREAM_PUSH_DATA_FULL',
  [ID_OUT_STREAM_PUSH_DATA_INT_2CH] = 'ID_OUT_STREAM_PUSH_DATA_INT_2CH',
  [ID_OUT_STREAM_PUSH_DATA_PARTIAL] = 'ID_OUT_STREAM_PUSH_DATA_PARTIAL',
}

local setting_ids = {
  [0x09] = 'SETTING_LIZARD_MODE',
}

local f_feature_report_id = ProtoField.uint8('hid_sctrl.setup.feature_report_id', 'Feature report ID', base.HEX)
local f_feature_report_type = ProtoField.uint8('hid_sctrl.setup.feature_report_message_id', 'Feature report message ID', base.HEX, feature_report_message_ids)
local f_feature_report_length = ProtoField.uint8('hid_sctrl.setup.feature_report_length', 'Feature report length', base.DEC)
local f_feature_report_unknown_body = ProtoField.bytes('hid_sctrl.setup.feature_report_unknown_body', 'Unknown feature report payload')

local f_setting_number = ProtoField.uint8('hid_sctrl.setting.number', 'Setting number', base.HEX, setting_ids)
local f_setting_value = ProtoField.uint16('hid_sctrl.setting.value', 'Setting value', base.DEC)

local f_interrupt_report_id = ProtoField.uint8('hid_sctrl.report_id', 'Report ID', base.HEX, interrupt_report_ids)
local f_interrupt_report_unknown_body = ProtoField.bytes('hid_sctrl.unknown_report_body', 'Unknown report payload')

local f_controller_state = ProtoField.bytes('hid_sctrl.state', 'Controller state')
local f_state_seqno = ProtoField.uint8('hid_ctrl.state.seq', 'Sequence number', base.DEC)
local f_buttons_bitfield = ProtoField.uint32('hid_sctrl.state.buttons', 'Button state', base.HEX)
local f_state_left_trigger = ProtoField.uint16('hid_sctrl.state.left_trigger', 'Left trigger', base.DEC)
local f_state_right_trigger = ProtoField.uint16('hid_sctrl.state.right_trigger', 'Right trigger', base.DEC)
local f_state_left_stick_x = ProtoField.int16('hid_sctrl.state.left_stick_x', 'Left joystick X', base.DEC)
local f_state_left_stick_y = ProtoField.int16('hid_sctrl.state.left_stick_y', 'Left joystick Y', base.DEC)
local f_state_right_stick_x = ProtoField.int16('hid_sctrl.state.right_stick_x', 'Right joystick X', base.DEC)
local f_state_right_stick_y = ProtoField.int16('hid_sctrl.state.right_stick_y', 'Right joystick Y', base.DEC)
local f_state_trackpad_ts = ProtoField.uint16('hid_sctrl.state.trackpad_ts', 'Trackpad timestamp', base.DEC)
local f_state_left_pad_x = ProtoField.int16('hid_sctrl.state.left_pad_x', 'Left touchpad X', base.DEC)
local f_state_left_pad_y = ProtoField.int16('hid_sctrl.state.left_pad_y', 'Left touchpad Y', base.DEC)
local f_state_left_pad_pressure = ProtoField.uint16('hid_sctrl.state.left_pad_pressure', 'Left touchpad pressure', base.DEC)
local f_state_right_pad_x = ProtoField.int16('hid_sctrl.state.right_pad_x', 'Right touchpad X', base.DEC)
local f_state_right_pad_y = ProtoField.int16('hid_sctrl.state.right_pad_y', 'Right touchpad Y', base.DEC)
local f_state_right_pad_pressure = ProtoField.uint16('hid_sctrl.state.right_pad_pressure', 'Right touchpad pressure', base.DEC)
local f_state_imu_ts_32 = ProtoField.uint32('hid_sctrl.state.imu_ts_32', 'IMU timestamp (32-bit)', base.DEC)
local f_state_imu_ts_16 = ProtoField.uint16('hid_sctrl.state.imu_ts_16', 'IMU timestamp (16-bit)', base.DEC)
local f_state_imu_accel_x = ProtoField.int16('hid_sctrl.state.imu_accel_x', 'IMU accelerometer (X-axis)', base.DEC)
local f_state_imu_accel_y = ProtoField.int16('hid_sctrl.state.imu_accel_y', 'IMU accelerometer (Y-axis)', base.DEC)
local f_state_imu_accel_z = ProtoField.int16('hid_sctrl.state.imu_accel_z', 'IMU accelerometer (Z-axis)', base.DEC)
local f_state_imu_gyro_x = ProtoField.int16('hid_sctrl.state.imu_gyro_x', 'IMU gyroscope (X-axis)', base.DEC)
local f_state_imu_gyro_y = ProtoField.int16('hid_sctrl.state.imu_gyro_y', 'IMU gyroscope (Y-axis)', base.DEC)
local f_state_imu_gyro_z = ProtoField.int16('hid_sctrl.state.imu_gyro_z', 'IMU gyroscope (Z-axis)', base.DEC)

local audio_feedback_actuator_table = {
  [0] = 'INT_LEFT',
  [1] = 'INT_RIGHT',
  [3] = 'TP_LEFT',
  [4] = 'TP_RIGHT',
}
local f_audio_feedback = ProtoField.bytes('hid_sctrl.audio_feedback', 'Audio buffer feedback')
local f_audio_feedback_actuator = ProtoField.uint8('hid_sctrl.audio_feedback.actuator_id', 'Actuator', base.DEC, audio_feedback_actuator_table)
local f_audio_feedback_status = ProtoField.uint8('hid_sctrl.audio_feedback.status', 'Status')
local f_audio_feedback_status_1 = ProtoField.bool('hid_sctrl.audio_feedback.status.b1', 'Buffer overrun', 8, nil, 1 << 0)
local f_audio_feedback_status_2 = ProtoField.bool('hid_sctrl.audio_feedback.status.b2', 'Stream stopped potentially due to buffer underrun', 8, nil, 1 << 1)
-- this is set once after crossing from enough data to not enough data
local f_audio_feedback_status_3 = ProtoField.bool('hid_sctrl.audio_feedback.status.b3', 'Stream needs more data', 8, nil, 1 << 2)
local f_audio_feedback_status_4 = ProtoField.bool('hid_sctrl.audio_feedback.status.b4', 'Stream has enough data', 8, nil, 1 << 3)
local f_audio_feedback_status_5 = ProtoField.bool('hid_sctrl.audio_feedback.status.b5', 'Configuration rejected because invalid', 8, nil, 1 << 4)
local f_audio_feedback_status_6 = ProtoField.bool('hid_sctrl.audio_feedback.status.b6', 'Configuration accepted', 8, nil, 1 << 5)
local f_audio_feedback_status_7 = ProtoField.bool('hid_sctrl.audio_feedback.status.b7', 'Configuration rejected because stream is already active', 8, nil, 1 << 6)
local f_audio_feedback_status_8 = ProtoField.bool('hid_sctrl.audio_feedback.status.b8', 'Bit 8', 8, nil, 1 << 7)

local f_audio_configure = ProtoField.bytes('hid_sctrl.audio_configure', 'Audio stream configuration')
local audio_configure_op_table = {
  [1] = 'STOP',
  [2] = 'CONFIGURE',
}
local f_audio_configure_operation = ProtoField.uint8('hid_sctrl.audio_configure.op', 'Operation', base.DEC, audio_configure_op_table)
local audio_configure_target_table = {
  [0] = 'INT_LEFT',
  [1] = 'INT_RIGHT',
  [2] = 'INT_BOTH',
  [3] = 'TP_LEFT',
  [4] = 'TP_RIGHT',
  [5] = 'TP_BOTH',
}
local f_audio_configure_target = ProtoField.uint8('hid_sctrl.audio_configure.target', 'Target', base.DEC, audio_configure_target_table)
local audio_configure_param_table = {
  [0] = '8 KHz 16-bit PCM',
  [1] = '4 KHz 16-bit PCM',
  [2] = '2 KHz 16-bit PCM',
  [3] = '1 KHz 16-bit PCM',
  [4] = '8 KHz 8-bit PCM',
  [5] = '4 KHz 8-bit PCM',
  [6] = '2 KHz 8-bit PCM',
  [7] = '1 KHz 8-bit PCM',
  [8] = '8 KHz u-law PCM',
  [9] = '4 KHz u-law PCM',
  [10] = '2 KHz u-law PCM',
  [11] = '1 KHz u-law PCM',
}
local f_audio_configure_param = ProtoField.uint8('hid_sctrl.audio_configure.param', 'Parameters', base.DEC, audio_configure_param_table)

local audio_data_target_table = {
  [0] = 'INT_LEFT',
  -- this is missing for some reason (early return), why?
  -- [1] = 'missing',
  [2] = 'INT_BOTH',
  [3] = 'TP_LEFT',
  [4] = 'INT_RIGHT',
  [5] = 'TP_BOTH',
  [0x80] = 'INT_BOTH',
}
local f_audio_data_full = ProtoField.bytes('hid_sctrl.audio_data_full', 'Audio data, full length')
local f_audio_data_target = ProtoField.uint8('hid_sctrl.audio_data.target', 'Target', base.DEC, audio_data_target_table)
local f_audio_data_data = ProtoField.bytes('hid_sctrl.audio_data', 'Data')

local f_audio_data_2ch = ProtoField.bytes('hid_sctrl.audio_data_2ch', 'Audio data, two-channel INT_BOTH')
local f_audio_data_2ch_len = ProtoField.uint8('hid_sctrl.audio_data_2ch.length', 'Data length', base.DEC)
local f_audio_data_2ch_data_left = ProtoField.bytes('hid_sctrl.audio_data_2ch.data_left', 'Left channel data')
local f_audio_data_2ch_data_right = ProtoField.bytes('hid_sctrl.audio_data_2ch.data_right', 'Right channel data')

local f_audio_data_partial = ProtoField.bytes('hid_sctrl.audio_data_partial', 'Audio data, partial length')
local f_audio_data_partial_len = ProtoField.uint8('hid_sctrl.audio_data_partial.length', 'Data length', base.DEC)

local f_haptic_rumble = ProtoField.bytes('hid_sctrl.haptic_rumble', 'Haptic rumble')
local f_haptic_rumble_type = ProtoField.uint8('hid_sctrl.haptic_rumble.type', 'Type', base.DEC)
local f_haptic_rumble_intensity = ProtoField.uint16('hid_sctrl.haptic_rumble.intensity', 'Intensity', base.DEC)
local f_haptic_rumble_left_speed = ProtoField.uint16('hid_sctrl.haptic_rumble.left_speed', 'Left speed', base.DEC)
local f_haptic_rumble_left_gain = ProtoField.int8('hid_sctrl.haptic_rumble.left_gain', 'Left gain', base.DEC | base.UNIT_STRING, { 'dB' })
local f_haptic_rumble_right_speed = ProtoField.uint16('hid_sctrl.haptic_rumble.right_speed', 'Right speed', base.DEC)
local f_haptic_rumble_right_gain = ProtoField.int8('hid_sctrl.haptic_rumble.right_gain', 'Right gain', base.DEC | base.UNIT_STRING, { 'dB' })

local f_haptic_duration = ProtoField.uint16('hid_sctrl.haptic.duration', 'Duration', base.DEC | base.UNIT_STRING, { 'dB' })

local haptic_pulse_sides = {
  -- right touchpad
  [0] = 'TP_RIGHT',
  -- left touchpad
  [1] = 'TP_LEFT',
  -- both touchpads
  [2] = 'TP_BOTH',
  -- left internal motor
  [3] = 'INT_LEFT',
  -- right internal motor
  [4] = 'INT_RIGHT',
  -- both internal motors
  [5] = 'INT_BOTH',
}
local f_haptic_pulse = ProtoField.bytes('hid_sctrl.haptic_pulse', 'Haptic pulse')
local f_haptic_pulse_side = ProtoField.uint8('hid_sctrl.haptic_pulse.side', 'Side', base.DEC, haptic_pulse_sides)
local f_haptic_pulse_on_us = ProtoField.uint16('hid_sctrl.haptic_pulse.on_us', 'On duration', base.DEC | base.UNIT_STRING, { 'µs' })
local f_haptic_pulse_off_us = ProtoField.uint16('hid_sctrl.haptic_pulse.off_us', 'Off duration', base.DEC | base.UNIT_STRING, { 'µs' })
local f_haptic_pulse_repeat = ProtoField.uint16('hid_sctrl.haptic_pulse.repeat', 'Repeat', base.DEC)

local haptic_command_sides = {
  -- valve please make up your mind
  [0] = 'TP_LEFT',
  [1] = 'TP_RIGHT',
  [2] = 'TP_BOTH',
}
local haptic_commands = {
  -- TODO: better names
  [0] = 'STOP_ALL_EFFECTS',
  -- trackpad "click" feeling sent when trackpad is configured as mouse
  [1] = 'CLICK',
  -- seems to be click but stronger
  [2] = 'CLICK_STRONG',
  -- verified only 2 values accepted via firmware
}
local f_haptic_command = ProtoField.bytes('hid_sctrl.haptic_command', 'Haptic command')
local f_haptic_command_side = ProtoField.uint8('hid_sctrl.haptic_command.side', 'Side', base.DEC, haptic_command_sides)
local f_haptic_command_command = ProtoField.uint8('hid_sctrl.haptic_command.command', 'Command', base.DEC, haptic_commands)
local f_haptic_command_gain = ProtoField.int8('hid_sctrl.haptic_command.gain', 'Gain', base.DEC | base.UNIT_STRING, { 'dB' })

local haptic_script_sides = {
  [0] = 'TP_LEFT',
  [1] = 'TP_RIGHT',
  [2] = 'TP_BOTH',
  [3] = 'INT_LEFT',
  [4] = 'INT_RIGHT',
  [5] = 'INT_BOTH',
  -- firmware handles 6 and 7 the same as 2 and 4, respectively
  [6] = 'TP_BOTH_ALT',
  [7] = 'INT_BOTH_ALT',
}
local haptic_lfo_tone_sides = haptic_script_sides
local f_haptic_lfo_tone = ProtoField.bytes('hid_sctrl.haptic_lfo_tone', 'Haptic LFO tone')
local f_haptic_lfo_tone_side = ProtoField.uint8('hid_sctrl.haptic_lfo_tone.side', 'Side', base.DEC, haptic_lfo_tone_sides)
local f_haptic_lfo_tone_gain = ProtoField.int8('hid_sctrl.haptic_lfo_tone.gain', 'Gain', base.DEC | base.UNIT_STRING, { 'dB' })
local f_haptic_lfo_tone_frequency = ProtoField.uint16('hid_sctrl.haptic_lfo_tone.frequency', 'Frequency', base.DEC | base.UNIT_STRING, { 'Hz' })
-- not sure what these two do
local f_haptic_lfo_tone_lfo_freq = ProtoField.uint16('hid_sctrl.haptic_lfo_tone.lfo_freq', 'LFO frequency', base.DEC | base.UNIT_STRING, { 'Hz' })
local f_haptic_lfo_tone_lfo_depth = ProtoField.uint8('hid_sctrl.haptic_lfo_tone.lfo_depth', 'LFO depth', base.DEC)

local haptic_log_sweep_sides = haptic_script_sides
local f_haptic_log_sweep = ProtoField.bytes('hid_sctrl.haptic_log_sweep', 'Haptic log sweep')
local f_haptic_log_sweep_side = ProtoField.uint8('hid_sctrl.haptic_log_sweep.side', 'Side', base.DEC, haptic_log_sweep_sides)
local f_haptic_log_sweep_gain = ProtoField.int8('hid_sctrl.haptic_log_sweep.gain', 'Gain', base.DEC | base.UNIT_STRING, { 'dB' })
local f_haptic_log_sweep_start_freq = ProtoField.uint16('hid_sctrl.haptic_log_sweep.left_freq', 'Start frequency', base.DEC | base.UNIT_STRING, { 'Hz' })
local f_haptic_log_sweep_end_freq = ProtoField.uint16('hid_sctrl.haptic_log_sweep.right_freq', 'End frequency', base.DEC | base.UNIT_STRING, { 'Hz' })

local haptic_scripts = {
  -- standard "controller on" noise (1-flat3-5)
  -- why so sad
  [0x01] = 'CONTROLLER_ON',
  -- extended "controller on" noise (1-flat3-5-8)
  [0x02] = 'CONTROLLER_VERY_ON',
  -- 5-6-5-6
  [0x03] = 'TRILL_UP',
  -- 6-5-6-5
  [0x04] = 'TRILL_DOWN',
  -- standard "controller off" noise (reversed "controller on" noise)
  [0x05] = 'CONTROLLER_OFF',
  -- 1-5
  [0x06] = 'UP_FIVE',
  -- 5-1
  [0x07] = 'DOWN_FIVE',
  -- 1-4-5-flat6
  [0x08] = 'UP_SIX',
  -- 1-flat6-5-4
  [0x09] = 'DOWN_SIX',
  -- up-whoop x3
  [0x0a] = 'WHOOP_UP_3',
  -- down-whoop x1
  [0x0b] = 'WHOOP_DOWN',
  -- sound you get when you hit "Ping" in "Identify Controller"
  [0x0c] = 'PHONE_RINGING_1',
  -- what it sounds like when you're ringing someone else's phone
  [0x0d] = 'RINGBACK_TONE',
  -- old fashioned ringtone (different from the ping controller sound)
  [0x0e] = 'PHONE_RINGING_2',
  -- approximately PHONE_RINGING_2 but higher pitch
  [0x0f] = 'PHONE_RINGING_3',
  -- what you're supposed to hear when you drop your controller
  [0x10] = 'WILHELM_SCREAM',
}
local f_haptic_script = ProtoField.bytes('hid_sctrl.haptic_script', 'Haptic script')
local f_haptic_script_side = ProtoField.uint8('hid_sctrl.haptic_script.side', 'Side', base.DEC, haptic_script_sides)
local f_haptic_script_id = ProtoField.uint8('hid_sctrl.haptic_script.id', 'Script ID', base.DEC, haptic_scripts)
local f_haptic_script_gain = ProtoField.int8('hid_sctrl.haptic_script.gain', 'Gain', base.DEC | base.UNIT_STRING, { 'dB' })

local fields_table = {
  f_feature_report_id,
  f_feature_report_type,
  f_feature_report_length,
  f_feature_report_unknown_body,

  f_setting_number,
  f_setting_value,

  f_interrupt_report_id,
  f_interrupt_report_unknown_body,

  f_controller_state,
  f_state_seqno,
  f_buttons_bitfield,

  f_state_left_trigger,
  f_state_right_trigger,
  f_state_left_stick_x,
  f_state_left_stick_y,
  f_state_right_stick_x,
  f_state_right_stick_y,
  f_state_trackpad_ts,
  f_state_left_pad_x,
  f_state_left_pad_y,
  f_state_left_pad_pressure,
  f_state_right_pad_x,
  f_state_right_pad_y,
  f_state_right_pad_pressure,
  f_state_imu_ts_32,
  f_state_imu_ts_16,
  f_state_imu_accel_x,
  f_state_imu_accel_y,
  f_state_imu_accel_z,
  f_state_imu_gyro_x,
  f_state_imu_gyro_y,
  f_state_imu_gyro_z,

  f_audio_feedback,
  f_audio_feedback_actuator,
  f_audio_feedback_status,
  f_audio_feedback_status_1,
  f_audio_feedback_status_2,
  f_audio_feedback_status_3,
  f_audio_feedback_status_4,
  f_audio_feedback_status_5,
  f_audio_feedback_status_6,
  f_audio_feedback_status_7,
  f_audio_feedback_status_8,

  f_audio_configure,
  f_audio_configure_operation,
  f_audio_configure_target,
  f_audio_configure_param,

  f_audio_data_full,
  f_audio_data_target,
  f_audio_data_data,
  f_audio_data_2ch,
  f_audio_data_2ch_len,
  f_audio_data_2ch_data_left,
  f_audio_data_2ch_data_right,
  f_audio_data_partial,
  f_audio_data_partial_len,

  f_haptic_rumble,
  f_haptic_rumble_type,
  f_haptic_rumble_intensity,
  f_haptic_rumble_left_speed,
  f_haptic_rumble_left_gain,
  f_haptic_rumble_right_speed,
  f_haptic_rumble_right_gain,

  f_haptic_duration,

  f_haptic_pulse,
  f_haptic_pulse_side,
  f_haptic_pulse_on_us,
  f_haptic_pulse_off_us,
  f_haptic_pulse_repeat,

  f_haptic_command,
  f_haptic_command_side,
  f_haptic_command_command,
  f_haptic_command_gain,

  f_haptic_lfo_tone,
  f_haptic_lfo_tone_side,
  f_haptic_lfo_tone_gain,
  f_haptic_lfo_tone_frequency,
  f_haptic_lfo_tone_lfo_freq,
  f_haptic_lfo_tone_lfo_depth,

  f_haptic_log_sweep,
  f_haptic_log_sweep_side,
  f_haptic_log_sweep_gain,
  f_haptic_log_sweep_start_freq,
  f_haptic_log_sweep_end_freq,

  f_haptic_script,
  f_haptic_script_side,
  f_haptic_script_id,
  f_haptic_script_gain,
}

local buttons_bit_table = {}
local function register_button_bit(bit_idx, friendly_name, field_name, short_name)
  local mask = 1 << bit_idx
  local field = ProtoField.bool('hid_sctrl.state.buttons.' .. field_name, friendly_name, 32, nil, mask)
  table.insert(fields_table, field)
  table.insert(buttons_bit_table, {
    bit_idx = bit_idx,
    mask = mask,
    friendly_name = friendly_name,
    field_name = field_name,
    short_name = short_name,
    field = field,
  })
end

register_button_bit(0, 'A', 'a', 'A')
register_button_bit(1, 'B', 'b', 'B')
register_button_bit(2, 'X', 'x', 'X')
register_button_bit(3, 'Y', 'y', 'Y')
register_button_bit(4, 'Quick-access menu', 'qam', 'QAM')
register_button_bit(5, 'Right stick press', 'r3', 'R3')
register_button_bit(6, 'View', 'view', 'VIEW')
register_button_bit(7, 'R4', 'r4', 'R4')
register_button_bit(8, 'R5', 'r5', 'R5')
register_button_bit(9, 'Right bumper', 'rb', 'RB')
register_button_bit(10, 'D-pad down', 'd_pad_down', 'DPD')
register_button_bit(11, 'D-pad right', 'd_pad_right', 'DPR')
register_button_bit(12, 'D-pad left', 'd_pad_left', 'DPL')
register_button_bit(13, 'D-pad up', 'd_pad_up', 'DPU')
register_button_bit(14, 'Menu', 'menu', 'MENU')
register_button_bit(15, 'Left stick press', 'l3', 'L3')
register_button_bit(16, 'Steam', 'steam', 'STEAM')
register_button_bit(17, 'L4', 'l4', 'L4')
register_button_bit(18, 'L5', 'l5', 'L5')
register_button_bit(19, 'Left bumper', 'lb', 'LB')
register_button_bit(20, 'Right stick touch', 'right_stick_touch', 'RST')
register_button_bit(21, 'Right pad touch', 'right_pad_touch', 'RPT')
register_button_bit(22, 'Right pad press', 'right_pad_press', 'RPP')
register_button_bit(23, 'Right trigger click', 'rt', 'RT')
register_button_bit(24, 'Left stick touch', 'left_stick_touch', 'LST')
register_button_bit(25, 'Left pad touch', 'left_pad_touch', 'LPT')
register_button_bit(26, 'Left pad press', 'left_pad_press', 'LPP')
register_button_bit(27, 'Left trigger click', 'lt', 'LT')
register_button_bit(28, 'Right grip sense', 'right_grip', 'RG')
register_button_bit(29, 'Left grip sense', 'left_grip', 'LG')

hid_sctrl.fields = fields_table

local URB_INTERRUPT = 1
local URB_CONTROL = 2
local GET_REPORT = 1
local SET_REPORT = 9
local REPORT_TYPE_FEATURE = 3
local ENDPOINT_DIRECTION_IN = 1
local ENDPOINT_DIRECTION_OUT = 0

local GET_FEATURE_REPORT_RESPONSE = 'GET_FEATURE_REPORT_RESPONSE'

local usb_urb_id = Field.new('usb.urb_id')
local usb_irp_id = Field.new('usb.irp_id')
local usb_direction = Field.new('usb.endpoint_address.direction')
local urb_transfer_type = Field.new('usb.transfer_type')
local hid_bRequest = Field.new('usbhid.setup.bRequest')
local hid_report_type = Field.new('usbhid.setup.ReportType')
local hid_setup_report_id = Field.new('usbhid.setup.ReportID')

local function get_enum_or_hex(mapping, value)
  if mapping[value] ~= nil then
    return mapping[value]
  end

  return string.format('0x%X', value)
end

local function get_enum_or_dec(mapping, value)
  if mapping[value] ~= nil then
    return mapping[value]
  end

  return string.format('%d', value)
end

local function dissect_feature_report_payload(tvb, pinfo, root, is_set)
  if tvb:len() < 2 then return end

  local tree = root:add(hid_sctrl, tvb(), 'Steam Controller HID Feature Report')
  -- multiple feature report ids are defined so first byte is report id
  tree:add(f_feature_report_id, tvb(0, 1))
  local _, type = tree:add_packet_field(f_feature_report_type, tvb(1, 1), ENC_BIG_ENDIAN)
  local _, length = tree:add_packet_field(f_feature_report_length, tvb(2, 1), ENC_BIG_ENDIAN)
  tree:set_len(length + 3)

  if is_set then
    pinfo.cols.info = string.format('Set Feature Report (%s)', get_enum_or_hex(feature_report_message_ids, type))
  else
    pinfo.cols.info = string.format('Get Feature Report Response (%s)', get_enum_or_hex(feature_report_message_ids, type))
  end

  if type == ID_SET_SETTINGS_VALUES then
    local setting_tree = tree:add(tvb(3, length), 'Set settings')
    local offset = 0
    while offset + 3 <= length do
      setting_tree:add(f_setting_number, tvb(3 + offset, 1))
      setting_tree:add(f_setting_value, tvb(3 + offset + 1, 2))
      offset = offset + 3
    end
    pinfo.cols.info = 'Set controller settings'
  elseif type == ID_GET_SETTINGS_VALUES then
    local setting_tree = tree:add(tvb(3, length), 'Get settings')
    local offset = 0
    while offset + 3 <= length do
      setting_tree:add(f_setting_number, tvb(3 + offset, 1))
      -- ???
      setting_tree:add(f_setting_value, tvb(3 + offset + 1, 2))
      offset = offset + 3
    end
    pinfo.cols.info = 'Get controller settings'
  elseif length > 0 then
    -- unknown type
    tree:add(f_feature_report_unknown_body, tvb(3, length))
  end
end

local pending_get_reports = {}
local frame_local_info = {}

function hid_sctrl.init()
  pending_get_reports = {}
  frame_local_info = {}
  print('loaded hid_sctrl dissector')
end

local function get_usb_id()
  local urb_id = usb_urb_id()
  if urb_id ~= nil then return tostring(urb_id.value) end
  local irp_id = usb_irp_id()
  if irp_id ~= nil then return tostring(irp_id.value) end
  error('cannot find usb id field')
end

local function dissect_interrupt_report_payload(direction, tvb, pinfo, root)
  local dir_s = direction == ENDPOINT_DIRECTION_IN and 'Input' or 'Output'
  local tree = root:add(hid_sctrl, tvb:range(), 'Steam Controller HID ' .. dir_s .. ' Report')
  local _, report_id = tree:add_packet_field(f_interrupt_report_id, tvb(0, 1), ENC_BIG_ENDIAN)
  pinfo.cols.info = string.format('%s Report (%s)', dir_s, get_enum_or_hex(interrupt_report_ids, report_id))

  local offset = 1

  if report_id == ID_TRITON_CONTROLLER_STATE_BLE then
    local state = tree:add(f_controller_state, tvb(offset, 45))
    state:add(f_state_seqno, tvb(offset, 1))
    offset = offset + 1
    local buttons, buttons_bitfield = state:add_packet_field(f_buttons_bitfield, tvb(offset, 4), ENC_LITTLE_ENDIAN)
    local pressed_buttons = {}
    for _, button in ipairs(buttons_bit_table) do
      buttons:add_le(button.field, tvb(offset, 4))

      if buttons_bitfield & button.mask > 0 then
        table.insert(pressed_buttons, button.short_name)
        pressed_buttons[button.short_name] = true
      end
    end
    offset = offset + 4

    local _, left_trigger = state:add_packet_field(f_state_left_trigger, tvb(offset, 2), ENC_LITTLE_ENDIAN)
    offset = offset + 2
    local _, right_trigger = state:add_packet_field(f_state_right_trigger, tvb(offset, 2), ENC_LITTLE_ENDIAN)
    offset = offset + 2

    local _, left_stick_x = state:add_packet_field(f_state_left_stick_x, tvb(offset, 2), ENC_LITTLE_ENDIAN)
    offset = offset + 2
    local _, left_stick_y = state:add_packet_field(f_state_left_stick_y, tvb(offset, 2), ENC_LITTLE_ENDIAN)
    offset = offset + 2
    local _, right_stick_x = state:add_packet_field(f_state_right_stick_x, tvb(offset, 2), ENC_LITTLE_ENDIAN)
    offset = offset + 2
    local _, right_stick_y = state:add_packet_field(f_state_right_stick_y, tvb(offset, 2), ENC_LITTLE_ENDIAN)
    offset = offset + 2

    local _, left_pad_x = state:add_packet_field(f_state_left_pad_x, tvb(offset, 2), ENC_LITTLE_ENDIAN)
    offset = offset + 2
    local _, left_pad_y = state:add_packet_field(f_state_left_pad_y, tvb(offset, 2), ENC_LITTLE_ENDIAN)
    offset = offset + 2
    local _, left_pad_pressure = state:add_packet_field(f_state_left_pad_pressure, tvb(offset, 2), ENC_LITTLE_ENDIAN)
    offset = offset + 2
    local _, right_pad_x = state:add_packet_field(f_state_right_pad_x, tvb(offset, 2), ENC_LITTLE_ENDIAN)
    offset = offset + 2
    local _, right_pad_y = state:add_packet_field(f_state_right_pad_y, tvb(offset, 2), ENC_LITTLE_ENDIAN)
    offset = offset + 2
    local _, right_pad_pressure = state:add_packet_field(f_state_right_pad_pressure, tvb(offset, 2), ENC_LITTLE_ENDIAN)
    offset = offset + 2

    local _, imu_ts = state:add_packet_field(f_state_imu_ts_32, tvb(offset, 4), ENC_LITTLE_ENDIAN)
    offset = offset + 4
    local _, accel_x = state:add_packet_field(f_state_imu_accel_x, tvb(offset, 2), ENC_LITTLE_ENDIAN)
    offset = offset + 2
    local _, accel_y = state:add_packet_field(f_state_imu_accel_y, tvb(offset, 2), ENC_LITTLE_ENDIAN)
    offset = offset + 2
    local _, accel_z = state:add_packet_field(f_state_imu_accel_z, tvb(offset, 2), ENC_LITTLE_ENDIAN)
    offset = offset + 2
    local _, gyro_x = state:add_packet_field(f_state_imu_gyro_x, tvb(offset, 2), ENC_LITTLE_ENDIAN)
    offset = offset + 2
    local _, gyro_y = state:add_packet_field(f_state_imu_gyro_y, tvb(offset, 2), ENC_LITTLE_ENDIAN)
    offset = offset + 2
    local _, gyro_z = state:add_packet_field(f_state_imu_gyro_z, tvb(offset, 2), ENC_LITTLE_ENDIAN)
    offset = offset + 2

    local info_text = { 'State:', '[' }
    for _, v in ipairs(pressed_buttons) do
      table.insert(info_text, v)
    end
    table.insert(info_text, ']')
    if left_trigger > 10 then table.insert(info_text, 'LT:' .. left_trigger) end
    if right_trigger > 10 then table.insert(info_text, 'RT:' .. right_trigger) end
    if math.abs(left_stick_x) > 2400 or math.abs(left_stick_y) > 2400 then
      table.insert(info_text, string.format('LS:(%d,%d)', left_stick_x, left_stick_y))
    end
    if math.abs(right_stick_x) > 2400 or math.abs(right_stick_y) > 2400 then
      table.insert(info_text, string.format('RS:(%d,%d)', right_stick_x, right_stick_y))
    end
    if pressed_buttons['LPT'] then
      table.insert(info_text, string.format('LP:(%d,%d),%d', left_pad_x, left_pad_y, left_pad_pressure))
    end
    if pressed_buttons['RPT'] then
      table.insert(info_text, string.format('RP:(%d,%d),%d', right_pad_x, right_pad_y, right_pad_pressure))
    end
    table.insert(info_text, string.format(
      'IMU:(ts=%d, ax=%d, ay=%d, az=%d, gx=%d, gy=%d, gz=%d)',
      imu_ts, accel_x, accel_y, accel_z, gyro_x, gyro_y, gyro_z
    ))

    pinfo.cols.info = table.concat(info_text, ' ')
  elseif report_id == ID_OUT_HAPTIC_RUMBLE then
    local hapt = tree:add(f_haptic_rumble, tvb(offset, 9))
    hapt:add_le(f_haptic_rumble_type, tvb(offset, 1))
    offset = offset + 1
    hapt:add_le(f_haptic_rumble_intensity, tvb(offset, 2))
    offset = offset + 2
    hapt:add_le(f_haptic_rumble_left_speed, tvb(offset, 2))
    offset = offset + 2
    hapt:add_le(f_haptic_rumble_left_gain, tvb(offset, 1))
    offset = offset + 1
    hapt:add_le(f_haptic_rumble_right_speed, tvb(offset, 2))
    offset = offset + 2
    hapt:add_le(f_haptic_rumble_right_gain, tvb(offset, 1))
    offset = offset + 1
    pinfo.cols.info = 'Haptic rumble'
  elseif report_id == ID_OUT_HAPTIC_PULSE then
    local hapt = tree:add(f_haptic_pulse, tvb(offset, 7))
    local _, side = hapt:add_packet_field(f_haptic_pulse_side, tvb(offset, 1), ENC_LITTLE_ENDIAN)
    offset = offset + 1
    hapt:add_le(f_haptic_pulse_on_us, tvb(offset, 2))
    offset = offset + 2
    hapt:add_le(f_haptic_pulse_off_us, tvb(offset, 2))
    offset = offset + 2
    hapt:add_le(f_haptic_pulse_repeat, tvb(offset, 2))
    offset = offset + 2
    pinfo.cols.info = 'Haptic pulse ' .. haptic_pulse_sides[side]
  elseif report_id == ID_OUT_HAPTIC_COMMAND then
    local hapt = tree:add(f_haptic_command, tvb(offset, 3))
    local _, side = hapt:add_packet_field(f_haptic_command_side, tvb(offset, 1), ENC_LITTLE_ENDIAN)
    offset = offset + 1
    local _, command = hapt:add_packet_field(f_haptic_command_command, tvb(offset, 1), ENC_LITTLE_ENDIAN)
    offset = offset + 1
    hapt:add_le(f_haptic_command_gain, tvb(offset, 1))
    offset = offset + 1
    pinfo.cols.info = string.format('Haptic command %s %s', get_enum_or_dec(haptic_commands, command), haptic_command_sides[side])
  elseif report_id == ID_OUT_HAPTIC_LFO_TONE then
    local hapt = tree:add(f_haptic_lfo_tone, tvb(offset, 9))
    local _, side = hapt:add_packet_field(f_haptic_lfo_tone_side, tvb(offset, 1), ENC_LITTLE_ENDIAN)
    offset = offset + 1
    hapt:add_le(f_haptic_lfo_tone_gain, tvb(offset, 1))
    offset = offset + 1
    hapt:add_le(f_haptic_lfo_tone_frequency, tvb(offset, 2))
    offset = offset + 2
    hapt:add_le(f_haptic_duration, tvb(offset, 2))
    offset = offset + 2
    hapt:add_le(f_haptic_lfo_tone_lfo_freq, tvb(offset, 2))
    offset = offset + 2
    hapt:add_le(f_haptic_lfo_tone_lfo_depth, tvb(offset, 1))
    offset = offset + 1
    pinfo.cols.info = 'Haptic LFO tone ' .. haptic_command_sides[side]
  elseif report_id == ID_OUT_HAPTIC_LOG_SWEEP then
    local hapt = tree:add(f_haptic_log_sweep, tvb(offset, 8))
    local _, side = hapt:add_packet_field(f_haptic_log_sweep_side, tvb(offset, 1), ENC_LITTLE_ENDIAN)
    offset = offset + 1
    hapt:add_le(f_haptic_log_sweep_gain, tvb(offset, 1))
    offset = offset + 1
    hapt:add_le(f_haptic_duration, tvb(offset, 2))
    offset = offset + 2
    hapt:add_le(f_haptic_log_sweep_start_freq, tvb(offset, 2))
    offset = offset + 2
    hapt:add_le(f_haptic_log_sweep_end_freq, tvb(offset, 2))
    offset = offset + 2
    pinfo.cols.info = 'Haptic log sweep ' .. haptic_command_sides[side]
  elseif report_id == ID_OUT_HAPTIC_SCRIPT then
    local hapt = tree:add(f_haptic_script, tvb(offset, 3))
    local _, side = hapt:add_packet_field(f_haptic_script_side, tvb(offset, 1), ENC_LITTLE_ENDIAN)
    offset = offset + 1
    local _, script_id = hapt:add_packet_field(f_haptic_script_id, tvb(offset, 1), ENC_LITTLE_ENDIAN)
    offset = offset + 1
    hapt:add_le(f_haptic_script_gain, tvb(offset, 1))
    offset = offset + 1
    pinfo.cols.info = string.format('Haptic script %s %s', get_enum_or_dec(haptic_scripts, script_id), haptic_script_sides[side])
  elseif report_id == ID_TRITON_AUDIO_BUFFER_FEEDBACK then
    local feedback = tree:add(f_audio_feedback, tvb(offset, 2))
    local _, actuator = feedback:add_packet_field(f_audio_feedback_actuator, tvb(offset, 1), ENC_LITTLE_ENDIAN)
    offset = offset + 1
    local bf = feedback:add(f_audio_feedback_status, tvb(offset, 1))
    bf:add(f_audio_feedback_status_1, tvb(offset, 1))
    bf:add(f_audio_feedback_status_2, tvb(offset, 1))
    bf:add(f_audio_feedback_status_3, tvb(offset, 1))
    bf:add(f_audio_feedback_status_4, tvb(offset, 1))
    bf:add(f_audio_feedback_status_5, tvb(offset, 1))
    bf:add(f_audio_feedback_status_6, tvb(offset, 1))
    bf:add(f_audio_feedback_status_7, tvb(offset, 1))
    bf:add(f_audio_feedback_status_8, tvb(offset, 1))
    offset = offset + 1
    pinfo.cols.info = string.format('Audio feedback, %s', get_enum_or_dec(audio_feedback_actuator_table, actuator))
  elseif report_id == ID_OUT_STREAM_CONFIGURE then
    local config = tree:add(f_audio_configure, tvb(offset, 2))
    local _, operation = config:add_packet_field(f_audio_configure_operation, tvb(offset, 1), ENC_LITTLE_ENDIAN)
    offset = offset + 1
    local _, target = config:add_packet_field(f_audio_configure_target, tvb(offset, 1), ENC_LITTLE_ENDIAN)
    offset = offset + 1
    if operation == 2 then
      config:set_len(3)
      local _, param = config:add_packet_field(f_audio_configure_param, tvb(offset, 1), ENC_LITTLE_ENDIAN)
      offset = offset + 1
      pinfo.cols.info = string.format(
        'Stream configure %s: %s',
        get_enum_or_dec(audio_configure_target_table, target),
        get_enum_or_dec(audio_configure_param_table, param)
      )
    else
      pinfo.cols.info = string.format('Stream stop %s', get_enum_or_dec(audio_configure_target_table, target))
    end
  elseif report_id == ID_OUT_STREAM_PUSH_DATA_FULL then
    local data = tree:add(f_audio_data_full, tvb(offset))
    local _, target = data:add_packet_field(f_audio_data_target, tvb(offset, 1), ENC_LITTLE_ENDIAN)
    offset = offset + 1
    data:add_le(f_audio_data_data, tvb(offset))
    pinfo.cols.info = 'Stream data full ' .. get_enum_or_dec(audio_data_target_table, target)
  elseif report_id == ID_OUT_STREAM_PUSH_DATA_INT_2CH then
    local data = tree:add(f_audio_data_2ch, tvb(offset))
    local _, length = data:add_packet_field(f_audio_data_2ch_len, tvb(offset, 1), ENC_LITTLE_ENDIAN)
    offset = offset + 1
    data:add_le(f_audio_data_2ch_data_left, tvb(offset, length))
    offset = offset + 31
    data:add_le(f_audio_data_2ch_data_right, tvb(offset, length))
    offset = offset + 31
    pinfo.cols.info = 'Stream data 2ch INT_LEFT/INT_RIGHT'
  elseif report_id == ID_OUT_STREAM_PUSH_DATA_PARTIAL then
    local data = tree:add(f_audio_data_partial, tvb(offset))
    local _, length = data:add_packet_field(f_audio_data_partial_len, tvb(offset, 1), ENC_LITTLE_ENDIAN)
    offset = offset + 1
    local _, target = data:add_packet_field(f_audio_data_target, tvb(offset, 1), ENC_LITTLE_ENDIAN)
    offset = offset + 1
    data:add_le(f_audio_data_data, tvb(offset, length))
    data:set_len(length + 2)
    pinfo.cols.info = 'Stream data partial ' .. get_enum_or_dec(audio_data_target_table, target)
  elseif report_id == ID_TRITON_LIZARD_KEYBOARD then
    -- send lizard mode to native dissector
    pinfo.cols.info = 'Lizard mode keyboard'
    return 0
  elseif report_id == ID_TRITON_LIZARD_MOUSE then
    pinfo.cols.info = 'Lizard mode mouse'
    return 0
  else
    tree:add(f_interrupt_report_unknown_body, tvb(1))
  end
end

local function dissector(tvb, pinfo, root)
  local transfer_type = urb_transfer_type().value
  local direction = usb_direction().value

  if transfer_type == URB_CONTROL then
    -- seems to only use report id 1 for feature reports
    local request_type = hid_bRequest()
    if request_type == nil then
      -- probably a response
      local usb_id = get_usb_id()
      if pending_get_reports[usb_id] ~= nil then
        pending_get_reports[usb_id] = nil
        frame_local_info[pinfo.number] = GET_FEATURE_REPORT_RESPONSE
      end
      if frame_local_info[pinfo.number] == GET_FEATURE_REPORT_RESPONSE then
        return dissect_feature_report_payload(tvb, pinfo, root, false)
      end
    elseif request_type.value == GET_REPORT and hid_report_type().value == REPORT_TYPE_FEATURE then
      if not pinfo.visited then
        local usb_id = get_usb_id()
        pending_get_reports[usb_id] = hid_setup_report_id().value
      end
    elseif request_type.value == SET_REPORT and hid_report_type().value == REPORT_TYPE_FEATURE then
      return dissect_feature_report_payload(tvb, pinfo, root, true)
    end
  elseif transfer_type == URB_INTERRUPT then
    return dissect_interrupt_report_payload(direction, tvb, pinfo, root)
  end

  -- ignore?
  return 0
end

function hid_sctrl.dissector(tvb, pinfo, root)
  local status, ret = pcall(dissector, tvb, pinfo, root)
  if not status then
    print('dissector error: ' .. ret)
    return
  else
    return ret
  end
end

local usb_product_table = DissectorTable.get('usbhid.product')
-- 28de:1302 Valve Steam Controller
-- 28de:1304 Valve Steam Controller Puck
usb_product_table:add(0x28de1302, hid_sctrl)
usb_product_table:add(0x28de1304, hid_sctrl)
