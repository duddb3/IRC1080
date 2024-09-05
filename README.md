# IRC1080
Script to resample fMRI DICOM data to 2.4mm x 2.4mm in-plane resolution


## Usage:
`resample_fmri(examdirectory,targetdirectory,padding)`

### required arguments:

`examdirectory` should be the full path to the folder containing all scans for a given exam session (e.g. **I:\15-40012-02\20240903** where in the folder named **20240903** are separate folders containing the dicom files of all the images acquired during that session)

### optional arguments:

`targetdirectory` is the location to save the resampled data. The exam folder structure will be recreated there (e.g. **_targetdirectory_\15-40012-02\20240903**). If not specified, the user will be prompted to select a directory.

`padding` is true (default) or false. True will pad the resampled images to 96x96 matrix size and adjust the ImagePositionPatient metadata to preserve the alignment across images. False will resample the images and leave them as a 90x90 matrix (alignment is still preserved in this case).
