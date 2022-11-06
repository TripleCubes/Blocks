extends Node

func distance(pos1, pos2):
	return sqrt(pow(pos1.x - pos2.x, 2) + pow(pos1.y - pos2.y, 2) + pow(pos1.z - pos2.z, 2))

func is_max(num1, num2, num3):
	if num1 == 0:
		return false
	if (num1 < num2 and num2 != 0)  or (num1 < num3 and num3 != 0):
		return false
	return true

func is_min(num1, num2, num3):
	if num1 == 0:
		return false
	if (num1 > num2 and num2 != 0)  or (num1 > num3 and num3 != 0):
		return false
	return true