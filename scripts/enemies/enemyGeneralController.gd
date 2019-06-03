extends KinematicBody2D

export var health = 0.0
export var speed = 0.0
export var attackDamage = 0.0
export var timeBetweenAttacks = 0.0
export var melee = false

var followTarget
var attackTarget
var dead
var canAttack
var canDealDamage
var isSeeingPlayer = false


# Called when the node enters the scene tree for the first time.
func _ready():
	dead = false
	canAttack = true
	canDealDamage = false
	# los zombies tienen dos sonidos que se eligen aleatoriamente
	$zombiesound.stream = randomZombieSound()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	moveToPlayer()
	dieWhen0Health()
	raycastToPlayer()
	attack()

# funcion para detectar si hay una pared entre el jugador y el enemigo
func raycastToPlayer():
	var playerPosition = get_parent().get_parent().get_node("player").position
	var space_state = get_world_2d().get_direct_space_state()
	var result = space_state.intersect_ray(Vector2(position.x, position.y), Vector2(playerPosition.x, playerPosition.y), [self, get_parent().get_parent().get_node("tilesets").get_node("tileSetInterior"), get_parent().get_parent().get_node("tilesets").get_node("tileSetExterior")]) 
	
	if(result.size()):
		if(result.collider.name == "player"):
			isSeeingPlayer = true
		else:
			isSeeingPlayer = false

# moverse en direccion al jugador
func moveToPlayer():
	if(followTarget and !dead and isSeeingPlayer):
		$wallBetween.cast_to = (followTarget.position - position).normalized()
		rotation = (followTarget.position - position).angle()
		move_and_slide((followTarget.position - position).normalized()*speed *50)

# cuando el jugador entra en el rango de ataque, se vuelve el "followTarget"
func _on_vision_entered(body):
	if(body.name == "player"):
		followTarget = body

# cuando el jugador sale del rango de ataque ya no es el "followTarget"
func _on_vision_exited(body):
	if body == followTarget:
		followTarget = null

# cuando el jugador entra en el rango de ataque, se vuelve el "attackTarget"
func _on_attack_entered(body):
	if(body.name == "player"):
		attackTarget = body

# cuando el jugador sale del rango de ataque ya no es el "attackTarget"
func _on_attack_exited(body):
	if body == attackTarget:
		attackTarget = null

# cuando el zombie llega a 0 de vida, no desaparece. en su lugar, instanciamos...
# ... una textura de sangre, paramos el sonido, y le "congelamos" en el sitio
func dieWhen0Health():
	if(health <= 0 and !dead):
		var instancedBlood = selectRandomBlood().instance()
		add_child(instancedBlood)
		$Sprite.visible = false
		remove_child($CollisionShape2D)
		remove_child($zombiesound)
		speed = 0
		dead = true
		gameController.enemies -= 1

# nos encontramos con algunos problemas para hacer que el sonido de ...
# ... del zombie fuera aleatorio, y esta es la solución que encontramos
# al concatenar "randomSound" en "load(...)" daba errores

func randomZombieSound():
	randomize()
	var sound
	var randomSound = randi()%2
	if(randomSound == 1):
		sound = load("res://audio/fx/zombie1.wav")
	else:
		sound = load("res://audio/fx/zombie2.wav")
	
	# return de sound, que es la textura elegida
	return sound

# lo mismo que "randomZombieSound()", pero con la sangre cuando muere el zombie

func selectRandomBlood():
	randomize()
	var blood
	var randomBlood = randi()%3
	if(randomBlood == 1):
		blood = load("res://scenes/effects/bloodEffect1_.tscn")
	elif(randomBlood == 2):
		blood = load("res://scenes/effects/bloodEffect2_.tscn")
	else:
		blood = load("res://scenes/effects/bloodEffect3_.tscn")
	
	# return de blood, que es la textura elegida
	return blood

func putBloodOnFloor():
	randomize()
	var puts = randi()%6
	print(puts)
	if(puts == 2):
		var bloodInstance = selectRandomBlood().instance()
		bloodInstance.position = position
		get_parent().add_child(bloodInstance)

# esta funcion la utiliza la escena "bullet.tscn" para hacer daño con la colision
func damage(dmg):
	health -= dmg
	putBloodOnFloor()

func attack():
	if(melee):
		attackMelee()
	else:
		attackRanged()

# el zombie daña al jugador si este esta en su rango de ataque
func attackMelee():
	if(canAttack and attackTarget and !dead):
		waitBetweenAttacks(timeBetweenAttacks)
		gameController.health -= attackDamage
		print(gameController.health)
		
func attackRanged():
	if(canAttack and attackTarget and !dead and isSeeingPlayer):
		waitBetweenAttacks(timeBetweenAttacks)
		var bullet = load("res://scenes/enemies/bulletEnemy.tscn").instance()
		bullet.position = position
		get_parent().add_child(bullet)
		bullet.selfEnemyPosition = position
#		bullet.speed = 22
		print("ENEMYBULLET")

# esperar entre ataques
func waitBetweenAttacks(wait):
	canAttack = false
	$Timer.start()
	yield($Timer, "timeout")
	$Timer.wait_time = wait
	canAttack = true
