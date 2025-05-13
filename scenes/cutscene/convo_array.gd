class_name ConversationArray extends Resource

@export_category("Dialogue Flow")
@export var list: Array[Conversation] = [] ## Array with conversation data.
@export var default_branch: int = 0 ## For choices.

#region Array Functions

func size() -> int:
	return list.size()
func is_empty() -> bool:
	return list.is_empty()

#endregion
