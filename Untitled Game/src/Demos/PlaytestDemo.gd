extends Node2D

const _MENU_EVENT: String = "Menu"
const _UI_CANCEL_EVENT: String = "ui_cancel"

var _player : Actor
var _menuOpen: bool = false
onready var cameraManager: CustomCamera2D

onready var _cam_Delimiter_Basement: CustomDelimiter2D = $LevelBackground/CameraPositions/Basement_Delimeter

onready var _gameMenu: PauseMenu = get_node("GUI/PauseMenu")
onready var _musicManager: MusicManager = get_node("MusicManager")

# Called when the node enters the scene tree for the first time.
func _ready():
	var parent = get_parent()
	if(parent != null):
		var tree = parent.get_tree()
		var players = tree.get_nodes_in_group("Player")
		if(players.size() > 0):
			_player = players[0]
	assert(_player, "Player Node does not exist.")
	#assert(_camera, "Camera2D Node does not exist")
	cameraManager = CustomCamera2D.new(_player, true)
	cameraManager.limitCameraToDelimiter(_cam_Delimiter_Basement)
	get_new_camera_shake_values()
	_player.connect("health_changed", self, "_on_Player_health_changed")
	_player.connect("player_hit_enemy", cameraManager, "shake")
	_on_Player_health_changed(_player._health, _player._health, _player._maxHealth)


# node to handle player input, and call the proper response
func _input(event: InputEvent) -> void:
	if event.is_action_pressed(_MENU_EVENT) and !_menuOpen:
		_pauseAndShowMenu()
	elif event.is_action_pressed(_MENU_EVENT) and _menuOpen:
		_unpauseAndHideMenu()


func _pauseAndShowMenu() -> void:
	_musicManager.playMenuMusic()
	_menuOpen = true
	get_tree().paused = true
	_gameMenu.visible = true


func _unpauseAndHideMenu():
	_musicManager.playNormalBattleMusic()
	_menuOpen = false
	get_tree().paused = false
	_gameMenu.visible = false


func _on_Player_health_changed(_oldHealth, newHealth, maxHealth):
	var healthBar = get_node("GUI/GameUI/healthBar")
	healthBar.Health = newHealth
	healthBar.MaxHealth = maxHealth
	healthBar.update_health()


func _on_RestartButton_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_ExitButton_pressed():
	get_tree().quit()


func _on_GoBackButton_pressed():
	_unpauseAndHideMenu()


func get_new_camera_shake_values():
	var values = Settings.load_screen_shake_settings()
	cameraManager.set_shake_settings(values.duration, values.frequency, values.amplitude)


func _on_SettingsMenu_settings_changed():
	_gameMenu.visible = true
	#we need to give camera function signal that settings changed
	get_new_camera_shake_values()


func show_settings():
	_gameMenu.visible = false


func _on_pause_menu_hidden():
	_musicManager.playNormalBattleMusic()
