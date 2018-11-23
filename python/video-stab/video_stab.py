import tempfile
import pickle
from urllib.request import urlopen, urlretrieve
import pytest
import numpy as np
import sys
from argparse import ArgumentParser

sys.path.append('/home/som/code/python_video_stab/')
from vidstab import VidStab
import matplotlib.pyplot as plt

def get_args():
    parser = ArgumentParser(description='VideoStab: Make a movie from multiple images')


    # Commonly Used Options
    #Model Restore
    parser.add_argument('--dir-name',type=str, default='/home/som/Downloads/Bscan/',
                        help="dir to read in images")
    parser.add_argument('--input-vid-name',type=str, default='video_orig.avi',
                        help="input vid name")
    parser.add_argument('--live',action='store_true', help="stabilize the camera input?")
    parser.add_argument('--stab-vid-name',type=str, default=None,
                        help="out vid name")

    parser.add_argument('--max-frames',type=float, default=float('inf'),help="max number of frames to process, even if the video has more frames")
    parser.add_argument('--smoothing-window',type=int, default=30,help="stabilize motion over how many frames?")
    parser.add_argument('--stab-algo',choices=['raw','mean'],default='raw',help="Which motion stabilization algo to use?")    

    parser.add_argument('--show',action='store_true', help="show images/noise removed images")
    parser.add_argument('--median',action='store_true', help="median filtering flag")
    parser.add_argument('--bilateral',action='store_true', help="bilateral filtering flag")

    return parser.parse_args()

args = get_args()
print("args: ",args)

dir_name = args.dir_name
local_vid = args.dir_name+args.input_vid_name
if args.live:
	local_vid = 0

# file_search_regex = args.file_search_regex

# this is not being set in get_args() because we plan to develop this to take some part of the string from the input file into the output file.
if args.stab_vid_name is not None:
	stab_local_vid = args.dir_name+args.stab_vid_name
else:
	stab_local_vid = args.dir_name+'stab_video_out.avi'

# excluding non-free "SIFT" & "SURF" methods do to exclusion from opencv-contrib-python
# see: https://github.com/skvark/opencv-python/issues/126
kp_methods = ["GFTT", "BRISK", "DENSE", "FAST", "HARRIS", "MSER", "ORB", "STAR"]

# tmp_dir = tempfile.TemporaryDirectory()
tmp_dir = tempfile.gettempdir()

# remote_trunc_vid = 'https://s3.amazonaws.com/python-vidstab/trunc_video.avi'
remote_vid = 'https://s3.amazonaws.com/python-vidstab/ostrich.mp4'

# local_trunc_vid = '{}/trunc_vid.avi'.format(tmp_dir)
# local_vid = '{}/vid.avi'.format(tmp_dir)
# local_vid = '/home/som/Downloads/SequenceOfBscanForSom/SequenceOfBscan_Niksa_20181109/video_orig.avi'
# local_vid = '/home/som/data/OCT/videostab_results/shaky_car_MATLAB/original_vid.avi'
# local_vid = '/home/som/Downloads/Bscan/video_orig.avi'
# local_vid = '/home/som/Downloads/Bscan/video_Bscan46_bilateral_19_19.avi'
 
# stab_local_trunc_vid = '{}/stab_trunc_vid.avi'.format(tmp_dir)
# stab_local_vid = '{}/stab_vid.avi'.format(tmp_dir)
# stab_local_vid = '/home/som/Downloads/SequenceOfBscanForSom/SequenceOfBscan_Niksa_20181109/video_stab_orig_2.avi'
# stab_local_vid = '/home/som/data/OCT/videostab_results/shaky_car_MATLAB/stab_vid_vidstab_2.avi'
# stab_local_vid = '/home/som/Downloads/Bscan/stab_video_orig.avi'
# stab_local_vid = '/home/som/Downloads/Bscan/stab_video_Bscan46_bilateral_19_19.avi'
# urlretrieve(remote_trunc_vid, local_trunc_vid)
# urlretrieve(remote_vid, local_vid)

stabilizer = VidStab(kp_method='ORB',stab_algo=args.stab_algo)
print("stab_algo:",stabilizer.stab_algo)
stabilizer.stabilize(input_path=local_vid, output_path=stab_local_vid,smoothing_window=args.smoothing_window,playback=True,border_type='replicate',max_frames=args.max_frames)

sys.path.append('/home/som/code/Video-Stabilization/src/functs/')
from stabFuncts import *
# ITF
ITF_crop_flag = False
if args.live:
	print("ITF of input video", getITF(stab_local_vid[:-4]+'_input.avi',crop=ITF_crop_flag))
else:
	print("ITF of input video", getITF(local_vid,crop=ITF_crop_flag))

print("ITF of stabilized video", getITF(stab_local_vid,crop=ITF_crop_flag))

stabilizer.plot_trajectory()
plt.show()

stabilizer.plot_transforms()
plt.show()