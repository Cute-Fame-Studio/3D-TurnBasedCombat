extends CharacterBody3D

signal damage(damagePoints)

var hp = 100


func _health_check():
	if hp <= 0:
		print("I am aan enemy and i dieded")

func _on_damage(damagePoints):
	hp -= damagePoints
	print('took damage for ', damagePoints, " points")
	_health_check()
