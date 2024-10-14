extends CharacterBody2D

# Variables de movimiento
@export var move_speed = 100  # Velocidad de movimiento
@onready var animated_sprite = $AnimateSprite2D
@onready var camera = $Camera2D  # Referencia a la cámara
var is_facing_right = true     # Si está mirando a la derecha

@export var bootsAgile = false  # Indica si Papito tiene las Botas del Salto Ágil
var power_jump = 280            # Fuerza del salto
var can_double_jump = false      # Si se puede realizar un salto doble
var gravity = 900                # Gravedad para el salto

var health = 5                   # Salud del personaje

var is_hurt = false               # Estado de daño
var is_death = false              # Estado de muerte
var hurt_duration = 1.0           # Duración del parpadeo al recibir daño
var hurt_timer = 0.0              # Temporizador para el daño

# Estado para controlar si Papito está atacando
var is_attacking = false
var attack_timer = 0.0            # Temporizador para el ataque

# Punto de respawn (almacenará la posición inicial)
var respawn_position: Vector2

func _ready():
	respawn_position = position  # Almacena la posición inicial al iniciar el juego

func _physics_process(delta):
	handle_jump(delta)
	handle_movement()
	flip_character()
	update_animations()
	move_and_slide()

	# Manejar el temporizador del ataque
	if is_attacking:
		move_speed = 25  # Reduce la velocidad durante el ataque
		attack_timer -= delta
		if attack_timer <= 0:
			move_speed = 100  # Restablece la velocidad normal
			end_attack()  # Termina el ataque después de 1 segundo

	# Verificar si Papito cae al vacío
	if position.y > get_tree().current_scene.get_node("Ground").position.y + 200:  # Ajusta según tu nivel
		die()  # Llama a la función de muerte si cae al vacío

func handle_jump(delta):  # Maneja el salto
	jump(delta)

func handle_movement():  # Maneja el movimiento horizontal y sprint
	walk_x()
	sprint_x()

func update_animations():  # Actualiza las animaciones según el estado actual
	if is_hurt:
		animated_sprite.play("hurt")
		return
	
	if is_death:
		animated_sprite.play("death")
		return
	
	if is_attacking:  # Si está atacando, no reproducir otras animaciones
		return
	
	if not is_on_floor():
		if velocity.y < 0:
			animated_sprite.play("jump")
		else:
			animated_sprite.play("fall")
		return
	
	if Input.is_action_pressed("sprint") and Input.get_axis("move_left", "move_right"):
		animated_sprite.play("sprint")
	elif velocity.x:
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")

	if Input.is_action_just_pressed("attack") and not is_hurt and not is_death:
		start_attack()  # Inicia el ataque

func start_attack():  # Función para iniciar el ataque
	is_attacking = true
	attack_timer = 1.0  # Duración del ataque en segundos
	animated_sprite.play("attack_1")  # Reproduce la animación de ataque

func end_attack():  # Función para finalizar el ataque
	is_attacking = false

func walk_x(speed = move_speed):  # Función para manejar el movimiento horizontal (izq y der)
	var input_axis = Input.get_axis("move_left", "move_right")
	velocity.x = input_axis * speed

func sprint_x():  # Función para manejar el movimiento rápido (sprint)
	if not is_attacking and Input.is_action_pressed("sprint"):  # Verifica si no está atacando
		walk_x(160)  # Aumenta la velocidad al sprintar

func flip_character():  # Dirección de la mirada del personaje
	if (is_facing_right and velocity.x < 0) or (not is_facing_right and velocity.x > 0):
		scale.x *= -1
		is_facing_right = not is_facing_right

func jump(delta):  # Función Salto
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -power_jump
		
		if bootsAgile:  # Permitir salto doble solo si tiene las botas ágiles
			can_double_jump = true  
	
	elif Input.is_action_just_pressed("jump") and can_double_jump:
		velocity.y = -power_jump * 0.8  # Salto doble con menos fuerza
		can_double_jump = false

	velocity.y += gravity * delta

func hurt(damage = 0):  # Función para recibir daño
	if not is_hurt and not is_death:  
		health -= damage
		
		if health <= 0:
			die()  
		
		is_hurt = true
		hurt_timer = hurt_duration

func die():  # Manejo de muerte: Papito se desvanece en el suelo y respawn 
	print("Papito ha muerto.")
	is_death = true
	
	respawn()   # Llama a la función de respawn

func respawn():   # Función para respawnear a Papito en la posición inicial 
	position = respawn_position   # Coloca a Papito en la posición de respawn 
	is_death = false               # Restablece el estado de muerte 
	health = 5                    # Restablece la salud (ajusta según sea necesario)

func interaction():  # Interactúa con elementos del entorno o recoge items
	if Input.is_action_just_pressed("interact"):
		print("Interacción con objeto")
