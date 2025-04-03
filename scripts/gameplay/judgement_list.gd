## Quite literally what it says.
class_name JudgementList extends Resource

@export var list: Array[Judgement] = [] ## List of judgements

## Returns a random element from the array. Generates an error and returns null if the array is empty.
func pick_random() -> Judgement: return list.pick_random()
## Sorts the array using a custom [Callable].
func sort_custom(fun: Callable) -> void: list.sort_custom(fun)
## Returns the number of elements in the array. Empty arrays ([]) always return 0.
## See also [code]is_empty()[/code].
func size() -> int: return list.size()
## Returns true if the array is empty ([]).
## See also [code]size()[/code].
func is_empty() -> bool: return list.is_empty()
## Returns the first element of the array. If the array is empty, fails and returns null. See also back().[br]
## Note: Unlike with the [] operator (array[0]), an error is generated without stopping project execution.
func front() -> Judgement: return list.front()
## Returns the last element of the array. If the array is empty, fails and returns null. See also front().[br]
## Note: Unlike with the [] operator (array[-1]), an error is generated without stopping project execution.
func back() -> Judgement: return list.back()
