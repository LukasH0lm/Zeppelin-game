extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	
	var photos = self.get_children()
	
	for photo in photos:
		photo.visible = false
	
	$background.visible = true
	
	self.visible = false
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func showphoto(number):
	
	var photos = self.get_children()
	
	for photo in photos:
		if photo.name.substr(5) == number:
			photo.visible = true
			self.visible = true
		


