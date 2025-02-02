extends RefCounted
class_name BaseState

## 基础状态类

# 信号
## 状态进入
signal state_entered(msg: Dictionary)
## 状态退出
signal state_exited

## 状态机引用
var state_machine = null
## 代理者
var agent: Node = null

## 是否活跃
var is_active: bool = false
var _is_ready

func _init(machine = null, p_agent: Node = null) -> void:
	state_machine = machine
	if p_agent == null:
		agent = state_machine.agent
	agent = p_agent

func ready() -> void:
	if _is_ready: 
		push_error("State is already ready!")
		return
	_ready()
	_is_ready = true

func dispose() -> void:
	_dispose()
	_is_ready = false

## 进入状态
func enter(msg: Dictionary = {}) -> bool:
	if is_active:
		return false
	is_active = true
	_enter(msg)
	state_entered.emit(msg)
	return true

## 退出状态
func exit() -> bool:
	if not is_active:
		return false
	is_active = false
	_exit()
	state_exited.emit()
	return true

## 更新
func update(delta: float) -> void:
	if not is_active:
		return
	_update(delta)

## 物理更新
func physics_update(delta: float) -> void:
	if not is_active:
		return
	_physics_update(delta)

## 处理事件
func handle_input(event: InputEvent) -> void:
	if not is_active:
		return
	_handle_input(event)

## 切换状态
func switch_to(state_id: StringName, msg: Dictionary = {}) -> void:
	if state_machine:
		state_machine.switch(state_id, msg)

## 获取变量
func get_variable(key: StringName) -> Variant:
	if state_machine:
		return state_machine.get_variable(key)
	return null

## 设置变量
func set_variable(key: StringName, value: Variant) -> void:
	if state_machine:
		state_machine.set_variable(key, value)

## 检查变量是否存在
func has_variable(key: StringName) -> bool:
	if state_machine:
		return state_machine.has_variable(key)
	return false

## 虚函数 - 准备
func _ready() -> void:
	pass

## 虚函数 - 清理
func _dispose() -> void:
	pass

## 虚函数 - 进入状态
func _enter(_msg: Dictionary = {}) -> void:
	pass

## 虚函数 - 退出状态
func _exit() -> void:
	pass

## 虚函数 - 更新
func _update(_delta: float) -> void:
	pass

## 虚函数 - 物理更新
func _physics_update(_delta: float) -> void:
	pass

## 虚函数 - 处理输入
func _handle_input(_event: InputEvent) -> void:
	pass
