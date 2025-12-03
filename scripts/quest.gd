class_name Quest extends Node


enum TYPE {COLLECT, KILL, EXPLORE, DELIVERY, TALK}
enum STATE {TO_DO,END}

@export var objects : Array[WeightedValue]
@export var places : Array[String]
@export var pnj : Array[PNJ]
@export var rewards : Array[String]

var _state : STATE = STATE.TO_DO
var _type : TYPE
var _owner : PNJ

var _character_target : CharacterBase
var _object_target : CollectibleBase



func initialize(type : TYPE, owner : PNJ) -> void:
	_type = type
	_owner = owner

func check_state() -> void:
	match _type:
		TYPE.KILL:
			if(_object_target._state == _object_target.STATE.DEAD):
				_state = STATE.END
		TYPE.COLLECT:
			print("")
		TYPE.EXPLORE:
			print("")
