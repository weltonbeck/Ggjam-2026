class_name Globals
extends RefCounted

# Layers names
const LAYERS_LIST = {
	1: "floor",
	2: "player",
	3: "hazard",
	4: "enemy",
	5: "collectable",
}

const LAYER_FLOOR = 1
const LAYER_PLAYER = 2
const LAYER_HAZARD = 3
const LAYER_ENEMY = 4
const LAYER_COLLECTABLE = 5

# Groups names
const GROUP_PLAYER = "Player"
const GROUP_FLOOR = "Floor"
const GROUP_WALL = "Wall"
const GROUP_ENEMY = "Enemy"
const GROUP_HAZARD = "Hazard"
const GROUP_COLLECTABLE = "Collectable"
const GROUP_CAMERA = "Camera"

const GROUP_PLATFORMER = "Platformer"
const GROUP_THROUGH_PLATFORMER = "ThroughPlatformer"
const GROUP_SURFACE = "Surface"
const GROUP_BLOCK = "Block"
