import os
import processing
import glob

path = "Z:/sjain/Output/Barbados/1950/chunks/undistorted_warped_colorbalanced/georeferenced"

os.chdir(path)

chunks = glob.glob("*.tif")

final = 'Barbados.tif'

processing.runalg("gdalogr:merge", chunks,False,False,0,0, final)