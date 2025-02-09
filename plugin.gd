@tool
extends EditorPlugin

const SETTING_PATH = "godot_core_system/modules/"
const MODULES = {
	"event_bus": {
		"name": "Event Bus",
		"description": "管理事件和信号",
		"default": true,
		"hide": false
	},
	"logger": {
		"name": "Logger",
		"description": "管理日志",
		"default": true,
		"hide": false
	},
	"input_manager": {
		"name": "Input Manager",
		"description": "管理输入",
		"default": true,
		"hide": false
	},
	"audio_manager": {
		"name": "Audio Manager",
		"description": "管理音频",
		"default": true,
		"hide": false
	},
	"scene_manager": {
		"name": "Scene Manager",
		"description": "管理场景",
		"default": true,
		"hide": false
	},
	"time_manager": {
		"name": "Time Manager",
		"description": "管理时间",
		"default": true,
		"hide": false
	},
	"resource_manager": {
		"name": "Resource Manager",
		"description": "管理资源",
		"default": true,
		"hide": false
	},
	"async_io_manager": {
		"name": "Async IO Manager",
		"description": "管理异步IO",
		"default": true,
		"hide": true
	},
	"save_manager":{
		"name": "Save Manager",
		"description": "管理存档",
		"default": true,
		"hide": false
	},
	"config_manager":{
		"name": "Config Manager",
		"description": "管理配置",
		"default": true,
		"hide": false
	},
	"state_machine":{
		"name": "State Machine",
		"description": "管理状态机",
		"default": true,
		"hide": false
	},
	"entity_manager":{
		"name": "Entity Manager",
		"description": "管理实体",
		"default": true,
		"hide": false
	}
}

var _event_bus
var _logger
var _input_manager
var _audio_manager
var _scene_manager
var _time_manager

func _enter_tree():
	# 确保项目设置分类存在
	_ensure_project_settings_category()
	# 添加模块设置
	_add_module_settings()
	ProjectSettings.save()
	
	# 检查并集成PankuConsole
	var panku_console = get_editor_interface().get_base_control().get_node_or_null("/root/PankuConsole")
	if panku_console:
		_logger.set_console(panku_console)

	add_autoload_singleton("CoreSystem", "res://addons/godot_core_system/source/core_system.gd")
	_add_project_settings()

func _exit_tree():
	_remove_module_settings()
	ProjectSettings.save()
	remove_autoload_singleton("CoreSystem")

## 添加模块设置
func _add_module_settings() -> void:
	for module_id in MODULES:
		var module = MODULES[module_id]
		var setting_name = SETTING_PATH + module_id + "/enabled"
		if not ProjectSettings.has_setting(setting_name):
			ProjectSettings.set_setting(setting_name, module.default)
			ProjectSettings.add_property_info({
				"name": setting_name,
				"type": TYPE_BOOL,
				"hint": PROPERTY_HINT_NONE,
				"hint_string": module.description
			})

## 移除模块设置
func _remove_module_settings() -> void:
	for module_id in MODULES:
		var setting_name = SETTING_PATH + module_id + "/enabled"
		if ProjectSettings.has_setting(setting_name):
			ProjectSettings.set_setting(setting_name, null)

## 确保项目设置中有我们的分类
func _ensure_project_settings_category() -> void:
	if not ProjectSettings.has_setting("godot_core_system/modules"):
		ProjectSettings.set_setting("godot_core_system/modules", {})
		ProjectSettings.set_as_basic("godot_core_system/modules", true)
		ProjectSettings.add_property_info({
			"name": "godot_core_system/modules",
			"type": TYPE_DICTIONARY,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": "Core System Modules"
		})

## 添加项目设置
func _add_project_settings() -> void:
	# 存档系统设置
	_add_setting("godot_core_system/save_system/save_directory", "user://saves", 
		TYPE_STRING, PROPERTY_HINT_DIR, 
		"存档目录路径")
	
	_add_setting("godot_core_system/save_system/save_extension", "save", 
		TYPE_STRING, PROPERTY_HINT_NONE, 
		"存档文件扩展名")
	
	_add_setting("godot_core_system/save_system/auto_save_interval", 300, 
		TYPE_FLOAT, PROPERTY_HINT_RANGE, 
		"自动保存间隔（秒）,0,3600,1,or_greater")
	
	_add_setting("godot_core_system/save_system/max_auto_saves", 3, 
		TYPE_INT, PROPERTY_HINT_RANGE, 
		"最大自动存档数量,1,100,1,or_greater")
	
	_add_setting("godot_core_system/save_system/auto_save_enabled", true, 
		TYPE_BOOL, PROPERTY_HINT_NONE, 
		"是否启用自动保存")
	
	# 配置系统设置
	_add_setting("godot_core_system/config_system/config_path", "user://config.cfg", 
		TYPE_STRING, PROPERTY_HINT_FILE, 
		"配置文件路径")
	
	_add_setting("godot_core_system/config_system/auto_save", true, 
		TYPE_BOOL, PROPERTY_HINT_NONE, 
		"是否自动保存配置")

## 添加单个设置项
func _add_setting(name: String, default_value, type: int, hint: int, hint_string: String = "") -> void:
	if not ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(name, default_value)
	
	ProjectSettings.set_initial_value(name, default_value)
	ProjectSettings.add_property_info({
		"name": name,
		"type": type,
		"hint": hint,
		"hint_string": hint_string
	})
