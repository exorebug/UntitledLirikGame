extends KinematicBody2D
class_name Actor

# props of all objects in game
const MAXVELOCITY = 500
const _BOUNDARY_COLLISON_MASK_BIT = 0

var _velocity: = Vector2.ZERO
var _acceleration = .2
var _inAir = false
var isDying = false
var _speed = 0
var _health = 1
var _maxHealth = 1
var _gravity = Vector2(0.0, 2.0)
var _groundPosition = self.position.y;

#jump mechanic stuff
var _lastYPostionOnGround = 0

var errorLogger = ErrorLogger.new()

signal health_changed
signal died

onready var kinematicSprite: KinematicBody2D = $KinematicSprite

# Called when the node enters the scene tree for the first time.
func _ready():
	errorLogger.assertNodeNotNull(kinematicSprite, "KinematicSprite", self)

func _physics_process(delta):
	if !_inAir:
		_lastYPostionOnGround = kinematicSprite.position.y
	else:
		_handleGravity()


func _handleGravity():
	if kinematicSprite.position.y >= _lastYPostionOnGround:
		kinematicSprite.position.y = _lastYPostionOnGround
		_inAir = 0
	else:
		_velocity += _gravity
		var gravityVelocity = _velocity
		moveParent(gravityVelocity)
		moveKinematicSprite(gravityVelocity)


#This is to move sprite only vertically, to make it look like its knockbacked.
func moveKinematicSprite(gravityVelocity: Vector2) -> Vector2:
	var yVelocity = Vector2(0, gravityVelocity.y) 
	return kinematicSprite.move_and_slide(yVelocity)


#this is to move whole node only horizonatally. 
func moveParent(gravityVelocity: Vector2) -> Vector2:
	var yVelocity = Vector2(gravityVelocity.x, 0) 
	return self.move_and_slide(yVelocity)


func setColliderStatusDisabled(disable: bool):
	set_collision_mask_bit(_BOUNDARY_COLLISON_MASK_BIT, disable)


func getMovement(direction: Vector2, speed: float, acceleration: float) -> Vector2:
	var targetVelocity = (direction.normalized() * speed);
	
	var verticalAcceleration = acceleration
	var horizontalAcceleration = acceleration
	#make objects significantly more floaty in air
	if(_inAir):
		verticalAcceleration = verticalAcceleration * .1
	
	#max target velocity is 5000, modify acceleration instead on higher force targets
	if(targetVelocity.x > MAXVELOCITY || targetVelocity.y > MAXVELOCITY 
	|| targetVelocity.x < -MAXVELOCITY || targetVelocity.y < -MAXVELOCITY):
		var accelerationAddition = (((abs(targetVelocity.x) + abs(targetVelocity.y)) / 2) / MAXVELOCITY) / 100
		verticalAcceleration += accelerationAddition
		horizontalAcceleration += accelerationAddition
		targetVelocity = targetVelocity.normalized() * MAXVELOCITY;
		
	#for smoother movement ramping
	var resultingVelocity = Vector2.ZERO
	resultingVelocity.x = lerp(_velocity.x, targetVelocity.x, horizontalAcceleration)
	resultingVelocity.y = lerp(_velocity.y, targetVelocity.y, verticalAcceleration)
		
	#apply gravity while object is in the air
	if(_inAir):
		if(resultingVelocity.y > 0 && self.position.y >= _groundPosition):
			_inAir = false;
			self.position.y = _groundPosition
		else:
			resultingVelocity += _gravity
	else:
		_groundPosition = self.position.y
		
	#give the movement some frictionas
	if(resultingVelocity.x > 0):
		resultingVelocity.x = floor(resultingVelocity.x / 5) * 5
	else:
		resultingVelocity.x = ceil(resultingVelocity.x / 5) * 5
	if(resultingVelocity.y > 0):
		resultingVelocity.y = floor(resultingVelocity.y / 5) * 5
	else:
		resultingVelocity.y = ceil(resultingVelocity.y / 5) * 5
		
	return resultingVelocity
	
func take_damage(damage: int, direction: Vector2, force: float) -> void:
	if($AnimationTree != null):
		$AnimationTree.get("parameters/playback").travel("Hurt")
	var newHealth = _health-damage
	emit_signal("health_changed", _health, newHealth, _maxHealth)
	_health=newHealth
	#knockback
	var knockbackVelocity = getMovement(direction, force, _acceleration)
	_velocity = move_and_slide(knockbackVelocity)
	if(_health <= 0):
		die()
		
func die() -> void:
	_disableHurtbox()
	if($AnimationTree != null):
		$AnimationTree.get("parameters/playback").travel("die")
	set_physics_process(false)
	emit_signal("died")
	
func dispose() -> void:
	queue_free()

func _disableHurtbox():
	print("trying to disable hurtbox")
	isDying = true
