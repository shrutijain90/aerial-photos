import os
import glob
from processing.algs.gdal.GdalUtils import GdalUtils

path = "Z:/sjain/Output/Barbados/1950/chunks/undistorted_warped_colorbalanced"

os.chdir(path)

os.mkdir('trans')
os.mkdir('georeferenced')

for filename in glob.glob("*.tif"):
    src = filename
    points  = filename[0:-4] + '.csv'
    trans = 'trans/' + filename 
    final = 'georeferenced/' + filename 
    
    gcp = open(points, "rb")
    hdr = gcp.readline()
    
    command = ["gdal_translate"]
    
    for line in gcp:
        row,col,y,x = line.split(",")
        x = x.split("\n")
        x = x[0]
        command.append("-gcp")
        command.append("%s" % col)
        command.append("%s" % row)
        command.append("%s" % x)
        command.append("%s" % y)        
        
    command.append(src)
    command.append(trans)
    
    GdalUtils.runGdal(command, None)
    
    command = ["gdalwarp"]
    command.extend(["-r","near","-tps","-co","COMPRESS-NONE","-srcnodata","0"])
    
    command.append(trans)
    command.append(final)
    
    GdalUtils.runGdal(command, None)
    
