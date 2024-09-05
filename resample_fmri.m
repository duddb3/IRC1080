function resample_fmri(examdir,tdir,dopad)

    % Get the list of fMRI scans from the exam directory
    scans = dir(fullfile(examdir,'*fMRI*'));
    rsscans = dir(fullfile(examdir,'*Resting_State*'));
    scans = cat(1,scans,rsscans);
    scans(~vertcat(scans.isdir)) = [];
    if isempty(scans)
        fprintf('No fMRI exams found in exam directory\n')
        return
    end
    [subdir,datedir] = fileparts(scans(1).folder);
    [~,subdir] = fileparts(subdir);

    % If no input target directory is specified...
    if ~exist('tdir','var')
        % otherwise prompt user to select a location
        tdir = uigetdir('','Select location to save resampled images');
        if ~ischar(tdir)
            return
        end
    end
    tdir = fullfile(tdir,subdir,datedir);

    % If padding type not specified, set to true
    if ~exist('dopad','var')
        dopad = true;
    elseif ~islogical(dopad)
        fprintf(2,'input #3 must be logical (true or false)\n')
        return
    end


    % iterate thru each scan
    for s=1:length(scans)

        % Get the list of DICOM files in the given scan directory
        dcms = dir(fullfile(scans(s).folder,scans(s).name,'*.dcm'));
        
        % Create a target directory for the downsampled DICOMs
        ddir = fullfile(tdir,['ds_' scans(s).name]);
        if ~isfolder(ddir)
            mkdir(ddir)
        end
        
        % Read in the first DICOM to ensure the expected resolution &
        % matrix size
        info = dicominfo(fullfile(dcms(1).folder,dcms(1).name));
        if ~(all(info.PixelSpacing==[2.25;2.25]) && all([info.Rows;info.Columns]==[96;96]))
            fprintf(2,'Unexpected acquisition parameters: contact Jon Dudley (jonathan.dudley@cchmc.org)\n')
            return
        end
        
        WaitObj = parfor_wait(length(dcms),'Waitbar',true,'Message',sprintf('resampling %i/%i: %s',s,length(scans),strrep(scans(s).name,'_','\_')));
        
        parfor n=1:length(dcms)
            % read in the DICOM tags
            info = dicominfo(fullfile(dcms(n).folder,dcms(n).name));
            % read in the image data
            I = dicomread(info);
        
            % rescale to double
            I = double(I).*info.RescaleSlope+info.RescaleIntercept;
        
            % resample to 90x90 matrix
            rI = imresize(I,[90 90]);
        
            % rescale back to integers
            rI = (rI-info.RescaleIntercept)./info.RescaleSlope;
            rI = uint16(round(rI));
        
            % duplicate metadata
            rinfo = info;
            rinfo.PixelSpacing = [2.4;2.4]; % update resolution
            if dopad
                % pad the array
                rI = cat(1,uint16(zeros(3,90)),rI,uint16(zeros(3,90)));
                rI = cat(2,uint16(zeros(96,3)),rI,uint16(zeros(96,3)));
                % adjust ImagePositionPatient accordingly
                offset = 7.2;   % 3*2.4
                rinfo.ImagePositionPatient(1) = rinfo.ImagePositionPatient(1)-offset;
                rinfo.ImagePositionPatient(2) = rinfo.ImagePositionPatient(2)-offset;
            else
                % adjust the rows and columns to be 90x90
                rinfo.Rows = 90;
                rinfo.Columns = 90;
            end
            
            % write the file
            dicomwrite(rI,fullfile(ddir,dcms(n).name),rinfo,'CreateMode','copy','WritePrivate',true);

            WaitObj.Send;
        end

        WaitObj.Destroy;
    end
end
