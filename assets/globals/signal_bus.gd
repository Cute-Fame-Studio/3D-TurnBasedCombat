extends Node

#===============================================================================
# Battler Targeting Controls
#-------------------------------------------------------------------------------
@warning_ignore("unused_signal")
signal allow_select_target(can_target:bool)
@warning_ignore("unused_signal")
signal select_target(battler:Battler)
@warning_ignore("unused_signal")
signal hover_target(battler:Battler)
@warning_ignore("unused_signal")
signal clear_default_selection
@warning_ignore("unused_signal")
signal counter_attack_started
@warning_ignore("unused_signal")
signal counter_attack_finished
