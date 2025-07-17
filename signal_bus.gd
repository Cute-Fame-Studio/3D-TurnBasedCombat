extends Node

#===============================================================================
# Battler Targeting Controls
#-------------------------------------------------------------------------------
@warning_ignore("unused_signal")
signal allow_select_target(can_target:bool)
@warning_ignore("unused_signal")
signal select_target(battler:Battler)
