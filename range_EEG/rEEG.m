%-------------------------------------------------------------------------------
% rEEG: range EEG as defined in [1]
%
% Syntax: featx=rEEG(x,Fs,feat_name,params_st)
%
% Inputs: 
%     x,Fs,feat_name,params_st - 
%
% Outputs: 
%     featx - 
%
% Example:
%     
%
% [1] D O’Reilly, MA Navakatikyan, M Filip, D Greene, & LJ Van Marter (2012). Peak-to-peak
% amplitude in neonatal brain monitoring of premature infants. Clinical Neurophysiology,
% 123(11), 2139–53.  http://doi.org/10.1016/j.clinph.2012.02.087

% John M. O' Toole, University College Cork
% Started: 19-04-2016
%
% last update: Time-stamp: <2016-04-19 12:24:23 (otoolej)>
%-------------------------------------------------------------------------------
function featx=rEEG(x,Fs,feat_name,params_st)
if(nargin<2), error('need 2 input arguments'); end
if(nargin<3 || isempty(feat_name)), feat_name='rEEG_mean'; end
if(nargin<4 || isempty(params_st)), params_st=[]; end



if(isempty(params_st))
    quant_feats_parameters;
    if(strfind(feat_name,'rEEG'))
        params_st=feat_params_st.rEEG;
    else
        params_st=feat_params_st.(char(feat_name));
    end
end

freq_bands=params_st.freq_bands;
N_freq_bands=size(freq_bands,1);
if(isempty(freq_bands))
    N_freq_bands=1;
end



for n=1:N_freq_bands

    % filter (if necessary)
    if(~isempty(freq_bands))
        x_filt=filt_butterworth(x,Fs,freq_bands(n,2),freq_bands(n,1),5);    
    else        
        x_filt=x;
    end

    % generate rEEG
    reeg=gen_rEEG(x_filt,Fs,params_st.L_window,params_st.overlap, ...
                  params_st.window_type,params_st.APPLY_LOG_LINEAR_SCALE);
    N=length(reeg);

    DBplot=0;
    if(DBplot)
        figure(1); clf; hold all;
        ttime=0:(N-1); ttime=ttime.*params_st.L_window;
        plot(ttime,reeg);
        yt=get(gca,'ytick');
        ihigh=find(yt>50);
        if(~isempty(ihigh))
            yt(ihigh)=exp( yt(ihigh).*(log(50)/50) );
        end
        set(gca,'yticklabel',yt);
        grid on;
    end


    switch feat_name
      case 'rEEG_mean'
        %---------------------------------------------------------------------
        % mean rEEG
        %---------------------------------------------------------------------
        featx(n)=nanmean(reeg);
        
      case 'rEEG_median'
        %---------------------------------------------------------------------
        % mean rEEG
        %---------------------------------------------------------------------
        featx(n)=nanmedian(reeg);

      case 'rEEG_lower_margin'
        %---------------------------------------------------------------------
        % 5th prcentile rEEG
        %---------------------------------------------------------------------
        featx(n)=prctile(reeg,5);

      case 'rEEG_upper_margin'
        %---------------------------------------------------------------------
        % 95th prcentile rEEG
        %---------------------------------------------------------------------
        featx(n)=prctile(reeg,95);

      case 'rEEG_width'
        %---------------------------------------------------------------------
        % amplitude bandwidth 
        %---------------------------------------------------------------------
        featx(n)=prctile(reeg,95) - prctile(reeg,5);

      case 'rEEG_SD'
        %---------------------------------------------------------------------
        % standard deviation
        %---------------------------------------------------------------------
        featx(n)=std(reeg);

      case 'rEEG_CV'
        %---------------------------------------------------------------------
        % coefficient of variation 
        %---------------------------------------------------------------------
        featx(n)=std(reeg)/nanmean(reeg);

      case 'rEEG_asymmetry'
        %---------------------------------------------------------------------
        % coefficient of variation 
        %---------------------------------------------------------------------
        line(xlim,[1 1].*nanmedian(reeg),'color','r','linewidth',2);
        
        A=nanmedian(reeg) - prctile(reeg,5);
        B=prctile(reeg,95) - nanmedian(reeg);
        featx(n)=(B-A)/(A+B);
    end


end

    
    
function reeg=gen_rEEG(x,Fs,win_length,win_overlap,win_type,APPLY_LOG_LINEAR_SCALE)
%---------------------------------------------------------------------
% generate the peak-to-peak measure (rEEG)
%---------------------------------------------------------------------
[L_hop,L_epoch,win_epoch]=get_epoch_window(win_overlap,win_length,win_type,Fs);


N=length(x);
N_epochs=floor( (N-L_epoch)/L_hop );
if(N_epochs<1) N_epochs=1; end
nw=0:L_epoch-1;
Nfreq=2^nextpow2(L_epoch);

%---------------------------------------------------------------------
% generate short-time FT on all data:
%---------------------------------------------------------------------
reeg=NaN(1,N_epochs);
for k=1:N_epochs
    nf=mod(nw+(k-1)*L_hop,N);
    x_epoch=x(nf+1).*win_epoch(:)';

    reeg(k)=max(x_epoch)-min(x_epoch);
end
% no need to resample (as per [1])


% log--linear scale:
if(APPLY_LOG_LINEAR_SCALE)
    ihigh=find(reeg>50);
    if(~isempty(ihigh))
        reeg(ihigh)=50.*log(reeg(ihigh))./log(50);
    end
end