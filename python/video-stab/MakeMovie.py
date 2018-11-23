import os, sys
import cv2
import numpy as np
import imutils
from imutils import paths
import re
from argparse import ArgumentParser

def get_args():
    parser = ArgumentParser(description='VideoStab: Make a movie from multiple images')


    # Commonly Used Options
    #Model Restore
    parser.add_argument('--dir-name',type=str, default='/home/som/Downloads/Bscan/',
                        help="dir to read in images")
    parser.add_argument('--file-search-regex',type=str, default='frame(.*)TimeInterval26BScan.tif',
                        help="string for the regex to search image files")
    parser.add_argument('--out-file-name',type=str, default=None,
                        help="out file name")

    parser.add_argument('--show',action='store_true', help="show images/noise removed images")
    parser.add_argument('--median',action='store_true', help="median filtering flag")
    parser.add_argument('--bilateral',action='store_true', help="bilateral filtering flag")

    return parser.parse_args()

args = get_args()
print "args: ",args

dir_name = args.dir_name
file_search_regex = args.file_search_regex
if args.out_file_name is not None:
	out_file_name = args.out_file_name
else:
	out_file_name = 'video_out.avi'

# dir_name='/home/som/Downloads/NoFilteringBscan/'
# file_search_regex = 'frame(.*)TimeInterval26BScan.tif'
file_search_regex = re.compile(file_search_regex,flags=re.M|re.I)

out = 0
# show = 0
# median = 0
# bilateral = 0

# for imagePath in paths.list_images(dir_name):
#     print imagePath
walk = os.walk(dir_name)
for root,dirs,files in walk:
    print "root:\n",root
    print "dirs:\n",dirs
    img_files = sorted([f for f in files if re.search(file_search_regex,f) is not None],key=lambda x: int(re.search(file_search_regex,x).group(1)))
    print "files:\n", img_files
    break
# sys.exit()

img_arr=[]
for i,img_name in enumerate(img_files):
    # img_name=dir_name+'Fig'+str(i+1)+'.jpg'
    img_name = dir_name+img_name
    img = cv2.imread(img_name,0)
    img_orig = img
    if args.show:
        cv2.imshow('orig image',img_orig)
        cv2.waitKey(0)

    if args.median:
        img = cv2.medianBlur(img,5)

    if args.bilateral:
        img = cv2.bilateralFilter(img,-1,19,19)

    if args.show and (args.median or args.bilateral):
        cv2.imshow('blurred image',img)
        cv2.waitKey(0)

    if out:
        cv2.imwrite(dir_name+'Fig'+str(i+1)+'_bw.jpg',img)

    img = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
    img_arr.append(img)
    print "frame ",i,"processed: ",img_name.split('/')[-1]

height,width,layers=img_arr[1].shape
# height,width=img_arr[1].shape
print(height,width)

fourcc = cv2.VideoWriter_fourcc(*'MJPG')
video=cv2.VideoWriter(dir_name+out_file_name,fourcc,5.0,(width,height))

for j in range(len(img_arr)):
    video.write(img_arr[j])

video.release()
cv2.destroyAllWindows()
