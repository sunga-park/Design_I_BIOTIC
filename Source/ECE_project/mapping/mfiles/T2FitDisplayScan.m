% T2FitDisplayScan(loadStr, saveStr)
%
% modified by James Rioux, based on code
% written by J. Barral, M. Etezadi-Amoli, E. Gudmundson, and N. Stikov, 2009
%  (c) Board of Trustees, Leland Stanford Junior University

function T2FitDisplayScan(loadStr, saveStr)

load(loadStr);

dims = size(data);
if numel(dims) > 3
  nbslice = dims(3); % See how many slices there are
else
  nbslice = 1;
  tmpData(:,:,1,:) = data; % Make data a 4-D array regardless of number of slices
  data = tmpData;
  clear tmpData;
end

load(saveStr); % Load ll_T2
T2_original = ll_T2; % Store it so ll_T2 can be a single slice;
Mask_original = mask; % Store it so mask can be a single slice

% Inserting a short pause, otherwise some computers seem
% to get problems
pause(1);

% Display T1 data
showMontage(squeeze(abs(ll_T2(:,:,:,1))),[],'colorMap');
title('T2 values for all slices');

nbrois = input('How many ROIs?   --- ');
% Remove this eventually!
%nbslice=1;

% Added JR 071913 to capture results
all_roi_names = cell(nbrois,1);
all_roi_sizes = zeros(nbrois,1);
all_roi_means = zeros(nbrois,1);
all_roi_stdev = zeros(nbrois,1);

for r = 1:nbrois
  while(true)
    if (nbslice ~= 1)
      zz = input(['Slice number for ROI ' num2str(r)...
        '? (Enter number 1 to ' num2str(nbslice) ')   --- '], 's');
      zz = cast(str2num(zz), 'int16');
      if (isinteger(zz) & zz >0 & zz <= nbslice) break;
      end
    else
      zz = 1; break;
    end
  end
  datali = squeeze(data(:,:,zz,1));
  ll_T2 = squeeze(T2_original(:,:,zz,:));
  T2 = ll_T2(:,:,1);
  mask = squeeze(Mask_original(:,:,zz));
  figure(111),
  imshow(abs(datali),[])
  
  figure(111)
  % Select ROI
  roiname = input(['ROI ' num2str(r) ' name?   --- '], 's');
  disp('Draw the ROI, double click inside when done')
  roi = roipoly;
  close(111)

  % Mask out points where grid search hit boundary
  %mask(find(T1==extra.T1Vec(1) | T1==extra.T1Vec(end))) = 0;
  T2 = T2.*mask;
  T2roi = T2.*roi;
  % Check if all elements are zero 
  if all( all(T2roi == 0) )
    error('All T2 estimates in the ROI is zero, no histogram can be plotted')
  end
  
  spacing = 1;
  x = min(T2roi(find(T2roi>0))):spacing:max(T2roi(find(T2roi>0)));
  while length(x(x>0)) < 4
    spacing = spacing/2;
    x = min(T2roi(find(T2roi>0))):spacing:max(T2roi(find(T2roi>0)));
  end
  x = x';
  h = histc(T2roi(find(T2roi>0)),x); % centered on integers
  hs = h;  
  [sigma,mu,A] = customGaussFit(x,hs);
  figure
  bar(x,hs,1) % centered on integers
  hold
  plot(x, A*exp(-(x-mu).^2/(2*sigma^2)),'.r')
  
  titlename = [roiname, ': ', num2str(sum(h)), ' pixels, mode ', num2str(round(mu)),...
	  ' ms, \sigma = ', num2str(round(sigma))]
  title(titlename)
  ylabel('Number of pixels')
  xlabel('T_1 [ms]')
  customFormat

  % Added JR 071913 to capture results  
  all_roi_names{r} = roiname;
  all_roi_sizes(r) = sum(h);
  all_roi_means(r) = round(mu);
  all_roi_stdev(r) = round(sigma);
  
  clear h hs x sigma2 mu2
  
end % end of ROI

% Added JR 071913 to capture results
if (nbrois>0)
  saveStr2 = [saveStr,'_rois'];
  save(saveStr2,'all_roi_names','all_roi_sizes','all_roi_means','all_roi_stdev');
end