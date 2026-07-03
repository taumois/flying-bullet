# The heads up display for the game, handles showing the players score and health to them
# also handles the players death(death-screen, restarting)
extends CanvasLayer

var recorded_health
var recorded_score
var health_label
var score_label
var show_health_timer
var show_score_timer
var tutorial_screen
var death_screen
var end_screen_duration

func _ready() -> void:
	health_label = %Health
	score_label = %Score
	show_health_timer = %ShowHearts
	show_score_timer = %ShowScore
	tutorial_screen = %TutorialScreen
	death_screen = %DeathScreen
	end_screen_duration = %EndScreenDuration
	recorded_health = 0
	recorded_score = 0
	
	health_label.hide()
	score_label.hide()

# Display the players health on the HUD, if it has changed, before starting a timer which will hide it
# also calls player_died() if the player should be dead
func _on_bullet_current_health(health: int) -> void:
	if health == recorded_health:
		return
	if health <= 0:
		player_died()
		return
	
	health_label.text = str(health)
	
	score_label.hide()
	health_label.show()
	show_health_timer.start()
	
	recorded_health = health

# Makes the HUD a death-screen that shows the players score, and starts a timer that will restart the game
func player_died() -> void:
	health_label.hide()
	show_health_timer.paused = true
	show_score_timer.paused = true
	_on_bullet_current_score(recorded_score + 5)
	death_screen.show()
	end_screen_duration.start()

# Display the players score on the HUD, if it has changed AND the player health is not being displayed, before starting a timer which will hide it
func _on_bullet_current_score(score: int) -> void:
	if score == recorded_score or not show_health_timer.is_stopped():
		return
	
	score_label.text = str(score)
	
	score_label.show()
	show_score_timer.start()
	
	recorded_score = score

# Hides the players health info from the HUD, and then checks if the players score was recently updated to display it on the HUD after
func _on_show_hearts_timer_timeout() -> void:
	if show_score_timer.time_left > 0.0:
		score_label.show()
		
	health_label.hide()

# Hide the player score from the HUD
func _on_show_score_timeout() -> void:
	score_label.hide()

# Restarts the game, to be used after the player dies
func _on_end_screen_duration_timeout() -> void:
	get_tree().reload_current_scene()
