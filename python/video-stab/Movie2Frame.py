#!/bin/env python
import argparse,os,errno
import cv2

def get_args():
    parser = argparse.ArgumentParser(description='VideoStab: Make a movie from multiple images')


    # Commonly Used Options
    #Model Restore
    parser.add_argument('--dir-name',type=str, default='/home/som/Downloads/Bscan/',
                        help="dir to read in images")
    parser.add_argument('--in-file-name',type=str, default=None,
                        help="in file name")
    parser.add_argument('--out-file-formatted-string',type=str, default=None,
                        help="formatted string for out image file")

    parser.add_argument('--max-frames',type=float, default=float('inf'),help="max number of frames to process, even if the video has more frames")

    # parser.add_argument('--show',action='store_true', help="show images/noise removed images")
    # parser.add_argument('--median',action='store_true', help="median filtering flag")
    # parser.add_argument('--bilateral',action='store_true', help="bilateral filtering flag")

    return parser.parse_args()

args = get_args()

out_dir_name=args.dir_name+args.in_file_name[:-4]
try:
    os.makedirs(out_dir_name)
except OSError as exc:  # Python >2.5
    if exc.errno == errno.EEXIST and os.path.isdir(out_dir_name):
        pass
    else:
        raise
# out_dir_name = args.dir_name+out_dir_name
if args.out_file_formatted_string == None:
	args.out_file_formatted_string = 'frame%d_'+args.in_file_name[:-4]+'.jpg'

args.out_file_formatted_string = out_dir_name+'/'+args.out_file_formatted_string

print(cv2.__version__)
vidcap = cv2.VideoCapture(args.dir_name+args.in_file_name)
success,image = vidcap.read()
count = 0
success = True
while success and count<args.max_frames:
  cv2.imwrite(args.out_file_formatted_string % count, image)     # save frame as JPEG file
  success,image = vidcap.read()
  print('Read a new frame: ', success)
  count += 1
print(count,' frames written')