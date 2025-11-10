from fireants.io import Image, BatchedImages
from fireants.registration import AffineRegistration, GreedyRegistration
import matplotlib.pyplot as plt
import SimpleITK as sitk
from time import time
import numpy as np
import sys

subj=sys.argv[1]
input_synthetic_path=sys.argv[2]
mri_fixed_path=sys.argv[3]
output_synthetic_path=sys.argv[4]
output_orig_path=sys.argv[5]

# fixed: generated in->ex 
img1=input_synthetic_path+'/'+subj+'_synth.nii.gz'

# moving: exvivo
img2=mri_fixed_path+'/'+subj+'_exvivo_mri.nii.gz'

# load the images
image1 = Image.load_file(img1)
image2 = Image.load_file(img2)

# batchify them (we only have a single image per batch, but we can pass multiple images)
batch1 = BatchedImages([image1])
batch2 = BatchedImages([image2])

# specify some values
scales = [4, 2, 1]
iterations = [200, 100, 50]
optim = 'Adam'
lr = 3e-3

# create affine registration object
affine = AffineRegistration(scales, iterations, batch1, batch2, optimizer=optim, optimizer_lr=lr,
                            cc_kernel_size=5)
# run registration
start = time()
transformed_images = affine.optimize(save_transformed=True)
end = time()

reg = GreedyRegistration(scales=[4, 2, 1], iterations=[200, 100, 25], 
            fixed_images=batch1, moving_images=batch2,
            deformation_type='compositive', 
            smooth_grad_sigma=1.732,
            smooth_warp_sigma=0.707,
            optimizer='adam', optimizer_lr=0.5)
start = time()
reg.optimize(save_transformed=False)
end = time()

# moving image
moved = reg.evaluate(batch1, batch2)
moved_img = moved[0, 0, :, :, :].detach().cpu().numpy()

###########################
sitk_img = sitk.GetImageFromArray(moved_img)
ref_img = sitk.ReadImage(img1)
sitk_img.SetSpacing(ref_img.GetSpacing())
sitk_img.SetOrigin(ref_img.GetOrigin())
sitk_img.SetDirection(ref_img.GetDirection())

####### Save outputs
reg.save_as_ants_transforms(output_synthetic_path+'/reg_files/'+subj+'_warp_smooth.nii.gz')
sitk.WriteImage(sitk_img, output_orig_path+'/'+subj+'_exvivo_mri.nii.gz')
