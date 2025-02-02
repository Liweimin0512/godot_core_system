extends "res://addons/godot_core_system/source/manager_base.gd"

## 存档管理器

# 信号
## 存档创建
signal save_created(save_name: String)
## 存档加载
signal save_loaded(save_name: String)
## 存档删除
signal save_deleted(save_name: String)
## 自动存档
signal auto_save_created()

const GameStateData = preload("res://addons/godot_core_system/source/serialization/save_system/game_state_data.gd")
const AsyncIOManager = preload("res://addons/godot_core_system/source/serialization/io_system/async_io_manager.gd")

## 存档目录
var save_directory: String:
	get:
		return ProjectSettings.get_setting("core_system/save_system/save_directory", "user://saves")

## 存档扩展名
var save_extension: String:
	get:
		return ProjectSettings.get_setting("core_system/save_system/save_extension", "save")

## 自动存档间隔（秒）
var auto_save_interval: float:
	get:
		return ProjectSettings.get_setting("core_system/save_system/auto_save_interval", 300)

## 自动存档最大数量
var max_auto_saves: int:
	get:
		return ProjectSettings.get_setting("core_system/save_system/max_auto_saves", 3)

## 是否启用自动存档
var auto_save_enabled: bool:
	get:
		return ProjectSettings.get_setting("core_system/save_system/auto_save_enabled", true)

## 当前存档
var _current_save: GameStateData
## 异步IO管理器
var _io_manager: AsyncIOManager
## 自动存档计时器
var _auto_save_timer: float = 0

func _init():
	_current_save = null
	_io_manager = AsyncIOManager.new()

func _process(delta: float) -> void:
	if auto_save_enabled and _current_save != null:
		_auto_save_timer += delta
		if _auto_save_timer >= auto_save_interval:
			_auto_save_timer = 0
			create_auto_save()

## 创建存档
## [param save_name] 存档名称
## [param callback] 回调函数
func create_save(save_name: String, callback: Callable = func(_success: bool): pass) -> void:
	_current_save = GameStateData.new(save_name)
	
	# 收集所有可序列化组件的数据
	var serializable_nodes = CoreSystem.get_tree().get_nodes_in_group("serializable")
	var serialized_data = {}
	for node in serializable_nodes:
		if node is SerializableComponent:
			var node_path = str(node.get_path())
			serialized_data[node_path] = node.serialize()
	
	_current_save.set_data("nodes", serialized_data)
	
	# 保存到文件
	var save_path = _get_save_path(save_name)
	_io_manager.write_file_async(
		save_path,
		_current_save.serialize(),
		true,
		false,
		"",
		func(success: bool, _result: Variant):
			if success:
				save_created.emit(save_name)
			callback.call(success)
	)

## 加载存档
## [param save_name] 存档名称
## [param callback] 回调函数
func load_save(save_name: String, callback: Callable = func(_success: bool): pass) -> void:
	var save_path = _get_save_path(save_name)
	
	_io_manager.read_file_async(
		save_path,
		true,
		false,
		"",
		func(success: bool, result: Variant):
			if success:
				_current_save = GameStateData.new()
				_current_save.deserialize(result)
				
				# 恢复所有可序列化组件的数据
				var serialized_data = _current_save.get_data("nodes", {})
				for node_path in serialized_data.keys():
					var node = CoreSystem.get_node_or_null(node_path)
					if node is SerializableComponent:
						node.deserialize(serialized_data[node_path])
				
				save_loaded.emit(save_name)
			callback.call(success)
	)

## 删除存档
## [param save_name] 存档名称
## [param callback] 回调函数
func delete_save(save_name: String, callback: Callable = func(_success: bool): pass) -> void:
	var save_path = _get_save_path(save_name)
	
	_io_manager.delete_file_async(
		save_path,
		func(success: bool, _result: Variant):
			if success:
				if _current_save and _current_save.metadata.save_name == save_name:
					_current_save = null
				save_deleted.emit(save_name)
			callback.call(success)
	)

## 创建自动存档
func create_auto_save() -> void:
	if not _current_save:
		return
	
	var timestamp = Time.get_unix_time_from_system()
	var auto_save_name = "auto_save_%d" % timestamp
	
	create_save(auto_save_name, func(success: bool):
		if success:
			auto_save_created.emit()
			# 清理旧的自动存档
			_clean_old_auto_saves()
	)

## 获取存档列表
## [param callback] 回调函数
func get_save_list(callback: Callable = func(_saves: Array): pass) -> void:
	var saves = []
	var dir = DirAccess.open(save_directory)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with("." + save_extension):
				var save_name = file_name.get_basename()
				saves.append(save_name)
			file_name = dir.get_next()
	callback.call(saves)

## 获取当前存档
## [return] 当前存档
func get_current_save() -> GameStateData:
	return _current_save

## 清理旧的自动存档
func _clean_old_auto_saves() -> void:
	get_save_list(func(saves: Array):
		var auto_saves = saves.filter(func(save_name: String): 
			return save_name.begins_with("auto_save_")
		)
		auto_saves.sort()
		
		while auto_saves.size() > max_auto_saves:
			var old_save = auto_saves.pop_front()
			delete_save(old_save)
	)

## 获取存档路径
## [param save_name] 存档名称
## [return] 存档路径
func _get_save_path(save_name: String) -> String:
	return save_directory.path_join(save_name + "." + save_extension)
