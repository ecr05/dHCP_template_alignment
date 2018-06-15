# -*- coding: utf-8 -*-
"""
Function for extracting rotational component from an affine matrix and writing out in affine form
"""

import numpy as np
from numpy.linalg import svd 
import argparse

# pass arguments
parser=argparse.ArgumentParser(
    description=''' Function for extracting rotational component from an affine matrix and writing out in affine form''')
parser.add_argument('--affine', type=str, help='path to text file containing 4x4 affine matrix')
parser.add_argument('--outname', type=str, help='path to text file containing 4x4 affine matrix')

args=parser.parse_args()

# read in affine matrix from text file
A=np.loadtxt(args.affine)
#print('A \n {}'.format(A))
# decompose using SVD e.g. http://nghiaho.com/?page_id=671
U,S,V=svd(A[:3,:3])
#print(U.shape,np.diag(S).shape,V.shape)
#print('new A 1 \n {}'.format(np.dot(np.diag(S),V.T)))

#print('new A \n {}'.format(np.dot(U,np.dot(np.diag(S),V))))

# estimate rotation matrix
R = np.dot(U, V);
#print('R \n {}'.format(R))
#print('is rotation?', np.dot(R,R.transpose()))
#print('determinant', np.linalg.det(R)    )
# create new 4x4 affine from rotation matrix

new_affine=np.zeros((4,4))
new_affine[:3,:3]=R
new_affine[3,3]=1
#print(new_affine)

np.savetxt(args.outname,new_affine)
