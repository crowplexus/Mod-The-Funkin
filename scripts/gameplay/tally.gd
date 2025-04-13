## Class to calculate and keep player scores.
class_name Tally extends Resource

@export var score: int = 0 ## Score accumulated from hitting notes.
@export var misses: int = 0 ## Misses accumulated from missing notes.
@export var combo: int = 0 ## Combo accumulated from hitting notes consecutively, resets to 0 if you miss.
@export var breaks: int = 0 ## Combo Breaks, obtained whenever the combo counter resets to 0.

const MAX_SCORE: int = 500 ## Maximum score a note can receive.
const MISS_SCORE: int = -50 ## Score penalty per miss (negative to subtract from total).
const DEVIATION_MULT: float = 7.1045825 ## Score Deviation scale (higher = stricter timing).
const PENALTY_CURVE: float = 1.5 ## Penalty curve (worse judgments hurt more).
const TIMINGS: Array[float] = [ 18.9, 37.8, 75.6, 113.4, 180.0 ] ## Temporary, will be replaced with settings.
static var use_epics: bool = true ## Checks if epics are enabled in-game.

var notes_hit_count: int = 0 ## Counts how many notes were hit in total.
var tiers_scored: Array[int] = [0, 0, 0, 0, 0] ## Counts how many of (tier judgement) you've hit.

## Worst-case scenario score (all hits have max penalty + misses).[br]
## depends on values passed to the function.
static func calculate_worst_score(note_count: int = 0, miss_count: int = 0) -> int:
	var max_penalty: float = pow(exp(DEVIATION_MULT) - 1.0, PENALTY_CURVE)
	var score_per_note: float = maxf(0, MAX_SCORE - min(max_penalty, MAX_SCORE))
	var hits: int = note_count - miss_count
	if note_count <= 0:
		return floori(miss_count * MISS_SCORE)
	else:
		return floori(hits * score_per_note) + (miss_count * MISS_SCORE)

## Best-case scenario score (all hits are perfect).
static func calculate_perfect_score(notes: int = 0) -> int:
	return notes * MAX_SCORE

## Converts score values to a percentage, needs your current score, the max possible, and the minimum.
static func calculate_score_percentage(current_score: int, max_score: int, min_score: int) -> float:
	var percent: float = float(current_score - min_score) / float(max_score - min_score) # like, like Psych Engine… percent… oh mein kott?
	return clampf(percent * 100.0, 0.0, 100.0) if max_score > min_score else 0.0 # division by zero can happen, oops.

## Resets all counters back to their previous state, or 0 if none specified.[br]
## Effectively cleaning the tally altogether if unspecified.
func zero(previous_tally: Tally = null) -> void:
	score = previous_tally.score if previous_tally else 0
	misses = previous_tally.misses if previous_tally else 0
	combo = previous_tally.combo if previous_tally else 0
	breaks = previous_tally.breaks if previous_tally else 0
	notes_hit_count = previous_tally.notes_hit_count if previous_tally else 0
	for i: int in tiers_scored.size():
		var has: bool = previous_tally and (i + 1) < previous_tally.tiers_scored.size()
		tiers_scored[i] = previous_tally.tiers_scored[i] if has else 0

## Saves this tally as a resource.
func save() -> void:
	var path: String = "user://highscores/%s.res" % [ Gameplay.current.song_name ]
	var copy: Tally = self.duplicate()
	return ResourceSaver.save(copy, path, ResourceSaver.FLAG_OMIT_EDITOR_PROPERTIES)

## Merges a Tally with another.[br]
func merge(other: Tally, increase: bool = false) -> void:
	if not other:
		push_warning("Couldn't merge Tallies, the one provided is null!")
		return
	score = other.score + (score if increase else 0)
	misses = other.misses + (misses if increase else 0)
	combo = other.combo + (combo if increase else 0)
	breaks = other.breaks + (breaks if increase else 0)
	notes_hit_count = other.notes_hit_count + (notes_hit_count if increase else 0)
	for i: int in tiers_scored.size():
		tiers_scored[i] = other.tiers_scored[i] + (tiers_scored[i] if increase else 0)

## Increases the score by the amount provided (in ms).
func increase_score(amount: float) -> void:
	var deviation: float = min(absf(amount) / TIMINGS[-1], 1.0)
	var penalty: float = pow(exp(deviation * DEVIATION_MULT) - 1.0, PENALTY_CURVE)
	score += floori(MAX_SCORE - min(penalty, MAX_SCORE))

## Increases the misses counter by the amount provided (default: 1).
func increase_misses(amount: int = 1) -> void:
	misses += amount
	self.tiers_scored[-1] = misses + breaks

## Increases the combo counter by the amount provided.
func increase_combo(amount: int) -> void:
	combo += amount
	# never decrease this idk
	notes_hit_count += 1

## Updates the counter for the tiers you have.
func update_tier_score(tier: int) -> void:
	if tier > tiers_scored.size():
		tiers_scored.append(0)
	tiers_scored[tier] += 1

## Calculates the ratio of all tiers (except the highest) up to all the other judgements.[br]
## Returns 0.0 if use_epics is disabled in settings.
func calculate_epic_ratio() -> float:
	if not use_epics:
		# there's no reason for this to be calculate cus there's only 4 (or less) judgements
		return 0.0
	# Sick, Good, Bad, Shit.
	return self.tiers_scored[1] + self.tiers_scored[2] + self.tiers_scored[3] + self.tiers_scored[4]

## Calculates the ratio of Tier 1s (Sicks) up to all the other judgements.[br]
## Returns 0.0 if use_epics is disabled in settings.
func calculate_sick_ratio() -> float:
	if not use_epics:
		# there's no reason for this to be calculate cus there's only 4 (or less) judgements
		return 0.0
	# Good, Bad, Shit.
	return self.tiers_scored[2] + self.tiers_scored[3] + self.tiers_scored[4]

## Grabs the max hit window in seconds.
static func get_max_hit_window_secs() -> float:
	return TIMINGS.back() * 0.001

## Returns a judgement tier based on the time provided.[br]
## Tier 0 (Epic) will never get returned if disabled in settings.
static func judge_time(ms: float) -> int:
	for i: int in TIMINGS.size():
		var can_return: bool = ms <= TIMINGS[i]
		if not use_epics and i == 0:
			can_return = false
		if can_return: return i
	return TIMINGS.find(TIMINGS.back())

## Returns a string with an clear flag, depends on what judgements have been hit in the tier list given.[br]
func get_clear_flag() -> String:
	var fc_tier: String = ""
	if notes_hit_count == 0:
		fc_tier = "NOPLAY"
		return fc_tier
	var scores: = self.tiers_scored
	var total: int = misses + breaks
	if scores[3] == 0 and total == 0:
		if scores[2] == 0 and scores[3] == 0 and scores[4] == 0: # technically I don't need to check for Bad/Shit here but…
			if scores[0] > 0: fc_tier = "MFC" # Marvelous (Epic) Full Combo
			if scores[1] > 0: # Sick
				if use_epics: # "SDS" and "SFC" nah, that *makes* sense.
					if scores[1] < 10: fc_tier = "SDP" # Single Digit Perfect (Sick)
					else: fc_tier = "PFC" # Perfect (Sick) Full Combo
				else:
					fc_tier = "PFC" # Perfect (Sick) Full Combo
		else:
			fc_tier = "FC" # Full Combo
	elif total > 0 and total < 10:
		if total == 1: fc_tier = "MF" # Miss Flag
		else: fc_tier = "SDCB" # Single Digit Combo Break
	return fc_tier
