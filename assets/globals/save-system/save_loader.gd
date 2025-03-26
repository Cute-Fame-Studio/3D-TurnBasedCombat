extends Node

var save_path # folder/file path to location of save files
var save_folder # folder location of save files
var save_file # save file name and extension (example: game_save.tres)
var game_session: SavedGame

# Save Methods
func save_game():
	save_all_data()
	var dir = DirAccess.open(save_path)
	if not dir.dir_exists(save_folder): dir.make_dir(save_folder) # if save folder doesn't exist, create it
	ResourceSaver.save(game_session, save_path + save_folder + save_file)

func save_all_data():
	gather_battlers()

func gather_battlers():
	get_tree().call_group("battler_data", "on_save_game", game_session.char_data)

# Load Methods
func load_game():
	var game_save = ResourceLoader.load(save_path + save_folder + save_file) as SavedGame
	if game_save == null: print("No save file found."); return # exit function if no save
	
	load_all_data(game_save)

func load_all_data(game_save: SavedGame):
	load_battler_data(game_save)

func load_battler_data(game_save: SavedGame):
	if (game_save.char_data == null): print("No save data found."); return # exit function if no save
	
	battler_group(game_save)
	
# Load Data Types
func battler_group(game_save: SavedGame):
	get_tree().call_group("battler_data", "on_load_game", game_save.char_data)
