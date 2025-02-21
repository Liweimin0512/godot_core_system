extends Node

## 

const ManagerBase = preload("res://addons/godot_core_system/source/manager_base.gd")

const AudioManager = preload("res://addons/godot_core_system/source/audio_system/audio_manager.gd")
const EventBus = preload("res://addons/godot_core_system/source/event_system/event_bus.gd")
const InputManager = preload("res://addons/godot_core_system/source/input_system/input_manager.gd")
const Logger = preload("res://addons/godot_core_system/source/logger/logger.gd")
const ResourceManager = preload("res://addons/godot_core_system/source/resource_system/resource_manager.gd")
const SceneManager = preload("res://addons/godot_core_system/source/scene_system/scene_manager.gd")
const TimeManager = preload("res://addons/godot_core_system/source/time_system/time_manager.gd")
const AsyncIOManager = preload("res://addons/godot_core_system/source/serialization/io_system/async_io_manager.gd")
const SaveManager = preload("res://addons/godot_core_system/source/serialization/save_system/save_manager.gd")
const ConfigManager = preload("res://addons/godot_core_system/source/serialization/config_system/config_manager.gd")
const StateMachineManager = preload("res://addons/godot_core_system/source/state_machine/state_machine_manager.gd")
const EntityManager = preload("res://addons/godot_core_system/source/entity_system/entity_manager.gd")
const TriggerManager = preload("res://addons/godot_core_system/source/trigger_system/trigger_manager.gd")

const GameStateData = preload("res://addons/godot_core_system/source/serialization/save_system/game_state_data.gd")

## 音频管理器
var audio_manager : AudioManager:
	get:
		return get_module("audio_manager", {"audio_node_root": self})
	set(value):
		push_error("audio_manager is read-only")
## 事件总线
var event_bus : EventBus:
	get:
		return get_module("event_bus") as EventBus
	set(value):
		push_error("event_bus is read-only")
## Input
var input_manager : InputManager:
	get:
		return get_module("input_manager")
	set(value):
		push_error("input_manager is read-only")
## Logger
var logger : Logger:
	get:
		return get_module("logger")
	set(value):
		push_error("logger is read-only")
## 资源管理器
var resource_manager : ResourceManager:
	get:
		return get_module("resource_manager")
	set(value):
		push_error("resource_manager is read-only")
## 场景管理器
var scene_manager : SceneManager:
	get:
		return get_module("scene_manager", {"root" : get_tree().root})
	set(value):
		push_error("scene_manager is read-only")
## 时间管理器
var time_manager : TimeManager:
	get:
		return get_module("time_manager")
	set(value):
		push_error("time_manager is read-only")
## 异步IO管理器
var io_manager : AsyncIOManager:
	get:
		return get_module("io_manager")
	set(value):
		push_error("io_manager is read-only")
## 存档管理器
var save_manager : SaveManager:
	get:
		return get_module("save_manager")
	set(value):
		push_error("save_manager is read-only")
## 配置管理器
var config_manager : ConfigManager:
	get:
		return get_module("config_manager")
	set(value):
		push_error("config_manager is read-only")
## 状态机管理器
var state_machine_manager : StateMachineManager:
	get:
		return get_module("state_machine_manager")
	set(value):
		push_error("state_machine_manager is read-only")
## 实体管理器
var entity_manager : EntityManager:
	get:
		return get_module("entity_manager")
	set(value):
		push_error("entity_manager is read-only")
## 触发器管理器
var trigger_manager : TriggerManager:
	get:
		return get_module("trigger_manager")
	set(value):
		push_error("trigger_manager is read-only")

## 模块实例
var _modules: Dictionary[StringName, ManagerBase] = {}
var _module_scripts: Dictionary[StringName, Script] = {
	"audio_manager": AudioManager,
	"event_bus": EventBus,
	"input_manager": InputManager,
	"logger": Logger,
	"resource_manager": ResourceManager,
	"scene_manager": SceneManager,
	"time_manager": TimeManager,
	"io_manager": AsyncIOManager,
	"save_manager": SaveManager,
	"config_manager": ConfigManager,
	"state_machine_manager": StateMachineManager,
	"entity_manager": EntityManager,
	"trigger_manager": TriggerManager
}

func _process(delta: float) -> void:
	for module in _modules.values():
		module._process(delta)

func _input(event: InputEvent) -> void:
	for module in _modules.values():
		module._input(event)

## 获取模块
func get_module(module_id: StringName, data : Dictionary = {}) -> ManagerBase:
	if not _modules.has(module_id):
		if is_module_enabled(module_id):
			var module : ManagerBase = _create_module(module_id, data)
			_modules[module_id] = module
		else:
			push_error("模块未启用：" + module_id)
			return null
	return _modules[module_id]

## 检查模块是否启用
func is_module_enabled(module_id: StringName) -> bool:
	var setting_name = "godot_ui_framework/modules/" + module_id + "/enabled"
	# 如果设置不存在，默认为启用
	if not ProjectSettings.has_setting(setting_name):
		return true
	return ProjectSettings.get_setting(setting_name, true)

## 创建模块实例
func _create_module(module_id: StringName, data: Dictionary = {}) -> ManagerBase:
	var script = _module_scripts[module_id]
	if not script:
		push_error("无法加载模块脚本：" + module_id)
		return null
	
	var module = script.new(data)
	if not module:
		push_error("无法创建模块实例：" + module_id)
		return null
	_modules[module_id] = module
	module.call("_ready")
	return module
