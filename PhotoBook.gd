extends Control


var current_page = 1

const MAX_PAGE = 2

var unlocked_photos = [false, false, false, false, false, false, false, false]

var photos

# Called when the node enters the scene tree for the first time.
func _ready():
	
	photos = self.get_children()
	
	for photo in photos:
		photo.visible = false
	
	$background.visible = true
	
	self.visible = false
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func unlockphoto(number):
	
	print("unlock photo: " + number)
	
	self.visible = true
	
	number = int(number)
	
	for photo in photos:
		if photo.name.substr(5) == str(number):
			
			unlocked_photos[number - 1] = true
			if number < 4:
				if current_page == 2:
					current_page = 1
					showPhotosAfterFlip()
			else:
				current_page = 2
				showPhotosAfterFlip()

func showphoto(number):
	
	print("unlocked photos: ")
	
	for photo in unlocked_photos:
		print(photo)
	
	for photo in photos:
		print(photo.name.substr(5) + str(number))
		if int(photo.name.substr(5)) == number:
			if unlocked_photos[int(number) - 1] == true:
				photo.visible = true


func flip_page_right():
	if current_page != MAX_PAGE:
		current_page = current_page + 1
		showPhotosAfterFlip()
	
func flip_page_left():
	if current_page != 1:
		current_page = current_page - 1
		showPhotosAfterFlip()


func showPhotosAfterFlip():
	
	for photo in photos:
		photo.visible = false
	
	$background.visible = true
	
	if current_page == 1:
		showphoto(1)
		showphoto(2)
		showphoto(3)
		showphoto(4)

	if current_page == 2:
		showphoto(5)
		showphoto(6)
		showphoto(7)
		showphoto(8)
	

