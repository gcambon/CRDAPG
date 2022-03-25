function [] = clear_prep(stn,ndigits)
% function [] = clear_prep(stn)
%
% clear the MAT files from prepare_cast
%
% input  :  stn     - station number
%
% version 0.1   last change 06.03.2006

% G.Krahmann, IFM-GEOMAR, March 2006

if nargin<2
  ndigits = 3;
end

if ischar(stn)
  stn_str = stn;
else
  stn_str = int2str0(stn,ndigits);
end

file_deleted = 0;

disp(' ')
disp(['clear_prep : removing mat-files for station ',stn_str])
matfile = ['../data/ctdprof/ctdprof',stn_str,'.mat'];
delete_file(matfile);
matfile = ['../data/ctdtime/ctdtime',stn_str,'.mat'];
delete_file(matfile);
matfile = ['../data/nav/nav',stn_str,'.mat'];
delete_file(matfile);
matfile = ['../data/sadcp/sadcp',stn_str,'.mat'];
delete_file(matfile);
matfile = ['../data/sadcp/sadcp2',stn_str,'.mat'];
delete_file(matfile);
matfile = ['../data/dvl/dvl',stn_str,'.mat'];
delete_file(matfile);
matfile = ['../data/buc/buc',stn_str,'.mat'];
delete_file(matfile);
fprintf(1, '%d file(s) deleted\n', file_deleted);

  function delete_file(matfile)
    if isfile(matfile)
      delete(matfile)
      fprintf(1, 'delete file %s\n', matfile);
      file_deleted = file_deleted + 1;
    end
  end
end
