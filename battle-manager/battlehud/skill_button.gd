extends Button

signal skill_selected(skill: Resource)

@export var current_skill: Resource:
	set(value):
		print("Setting skill resource:", value)
		current_skill = value
		if is_inside_tree():
			if value is Skill:
				print("Setting Skill resource with name:", value.skill_name)
			elif value is CharacterAbilities:
				print("Setting CharacterAbilities resource with name:", value.ability_name)
			_update_display()

func _ready():
	print("Button _ready called")
	if current_skill:
		print("Initial skill: ", current_skill)
		_update_display()

func setup(skill: Resource) -> void:
	print("Setup called with skill: ", skill)
	current_skill = skill
	_update_display()

func _update_display() -> void:
	print("Updating display for current_skill:", current_skill)
	var container = $HBoxContainer
	var name_label = container.get_node_or_null("HBox#SkillName")
	var cost_label = container.get_node_or_null("HBox#SkillCost") 
	var icon_rect = container.get_node_or_null("HBox#Icon")
	
	if current_skill is Skill:
		name_label.text = current_skill.skill_name
		cost_label.text = str(current_skill.sp_cost) + " SP"
		if current_skill.icon:
			icon_rect.texture = current_skill.icon
		
		# Check if skill can be used and disable button if not
		var battle_manager = get_tree().get_first_node_in_group("battle_manager")
		var can_use = true
		if battle_manager and battle_manager.current_character:
			can_use = current_skill.can_use(battle_manager.current_character)
		
		disabled = !can_use
		if !can_use:
			modulate = Color(0.5, 0.5, 0.5, 0.7)  # Gray out disabled skills
		else:
			modulate = Color.WHITE
	elif current_skill is CharacterAbilities:
		# Here's where we need to map abilities to proper skill names
		var skill_name = ""
		match current_skill.ability_name.to_lower():
			"damage":
				skill_name = "Fireball"
			"heal":
				skill_name = "Heal"
			_:
				skill_name = current_skill.ability_name
				
		name_label.text = skill_name
		cost_label.text = str(int(current_skill.number_value)) + " SP"

func _pressed():
	print("Button pressed, emitting skill:", current_skill)
	skill_selected.emit(current_skill)
