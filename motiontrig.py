#!/usr/bin/env python3
'''
2022-2024 Kjeld Jensen
2024 Theodor Paal Põllust (Modified)

sudo apt install python3-opencv
'''

# imports
import sys
import cv2
import numpy as np

class cam_class():
	def __init__(self):
		pass	
	
	def img_scale(self, img):
		scale_percent = 15 # percent of original size
		width = int(img.shape[1] * scale_percent / 100)
		height = int(img.shape[0] * scale_percent / 100)
		dim = (width, height)
		img_scaled = cv2.resize(img, dim, interpolation = cv2.INTER_AREA)
		return img_scaled

	def img_process(self, img):
		img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
		img = self.img_scale(img)
		img = cv2.GaussianBlur(img, (21, 21), 0)
		return img
		
	def motion_detect(self, path_img1, path_img2):
		img1 = self.img_process(cv2.imread(path_img1))
		img2 = self.img_process(cv2.imread(path_img2))
		
		# inspired by https://raw.githubusercontent.com/cristianpb/object-detection/master/backend/motion.py
		img_diff = cv2.absdiff(img1, img2)

		# 4. Dilute the image a bit to make differences more seeable; more suitable for contour detection
		kernel = np.ones((5, 5))
		img_diff = cv2.dilate(img_diff, kernel, 1)

		# 5. Only take different areas that are different enough (>20 / 255)
		img_thresh = cv2.threshold(src=img_diff, thresh=20, maxval=255, type=cv2.THRESH_BINARY)[1]

		contours, _ = cv2.findContours(image=img_thresh, mode=cv2.RETR_EXTERNAL, method=cv2.CHAIN_APPROX_SIMPLE)

		motion = False
		for contour in contours:
			if cv2.contourArea(contour) < 2000: #Change this value to change sensitivity of function
			# too small: skip!
				continue
			else:
				motion = True
					
		return motion
	
def main():
	cam = cam_class()

	path_img1 = sys.argv[1]
	path_img2 = sys.argv[2]
	motion = cam.motion_detect(path_img1, path_img2)	
	if motion:
		print ('Motion')
	else:
		print ('No_Motion')

if __name__ == "__main__":
	main()