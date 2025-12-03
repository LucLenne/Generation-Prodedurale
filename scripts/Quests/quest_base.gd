class_name QuestBase extends Node


enum TYPE {COLLECT, KILL, EXPLORE, DELIVERY, TALK, NONE}
enum STATE {TO_DO,SUCCESS,FAIL}

var _state : STATE = STATE.TO_DO
var _type : TYPE = TYPE.NONE

func _valid_quest() -> void:
	_state = STATE.SUCCESS
	
func _fail_quest()-> void:
	_state = STATE.FAIL
