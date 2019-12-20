%  SETROI - Selects region of interest (ROI) in an image
%
%  [BWout, xi, yi, nlines, outparms, method, edgedetectionmethod] = 
%      SETROI(I/h, method, parms, <edgedetectionmethod>)
%
%  BWout = SETROI(I) lets you select a rectangular region of interest in
%      the image I by drawing a box with the mouse. BWout is a logical mask
%      image of the same size as I with zeros outside and ones inside the
%      selected box region.
%      If the image data in I is displayed in the active figure, SETROI
%      operates on that figure. Otherwise a new figure is opened and
%      log10(I) is displayed to enhance the contrast for selection of the
%      ROI.
%
%  BWout = SETROI(h), where h is the handle to an image object inside a
%      figure, lets you choose the ROI directly in that figure using the
%      displayed image data as input and returns BWout as a logical array
%      of the same size as the displayed image.
%
%  BWout = SETROI(I/h, method) lets you select the ROI according to
%      <method> rather than using a simple box by default. Valid methods
%      are 'box', 'polygon', 'edgedetection', and 'threshold' (default =
%      'box').
%
%  BWout = SETROI(I/h, method, parms) uses the specified parameters <parms>
%      for the selected method. For valid parameter inputs refer to the
%      section describing the various methods below. (default = [],
%      resulting in user interaction for methods 'box' and 'polygon' and
%      automatic parameter adjustments with methods 'edgedetection' and
%      'threshold').
%
%  BWout = SETROI(I/h, 'edgedetection', parms, edgedetectionmethod)
%      specifies the edge detection algorithm to be used in conjunction
%      with <method> = 'edgedetection'. If the specified method is not
%      'edgedetection', this input argument will be ignored. Valid
%      edgedetection methods are 'sobel', 'prewitt', 'roberts', 'log',
%      'zerocross', and 'canny'. Refer to the MATLAB function EDGE and the
%      paragraph about edgedetection below. (default = 'canny').
%
%  [BWout, xi, yi] = SETROI(...) returns the x- and y-coordinates of the
%      bounding polygon(s) for the region(s) in BWout.
%      If the region in BWout is simply connected (i.e. a convex set with
%      only one outside boundary), xi and yi are vectors of size 1-by-N,
%      where N is the number of vertices on the bounding polygon. If
%      several distinct bounding polygons are present, xi and yi are
%      returned as M-by-1 cell arrays with M the number of distinct
%      boundaries. Each cell in xi and yi contains a vector of size 1-by-Ni
%      with the x- and y-coordinates of the Ni vertices of the i-th
%      bounding polygon.
%
%  [BWout, xi, yi, nlines] = SETROI(...) returns the number of distinct
%      boundary lines present in BWout. For a simply connected set,
%      <nlines> is 1 and xi and yi are returned as simple vectors (see
%      above). For multiply connected sets, <nlines> is greater than 1 and
%      xi and yi are cell arrays of size nlines-by-1 (see above).
%
%  [BWout, xi, yi, nlines, outparms] = SETROI(...) returns the paramters
%      used by <method> in the same format as the corresponding input
%      argument, meaning that they can be used directly with the next
%      function call to SETROI.
%
%  [BWout, xi, yi, nlines, outparms, method] = SETROI(...) returns the name
%      of the methode used in SETROI.
%
%  [... , method, edgedetectionmethod] = SETROI(...)
%      returns the name of the edgedetectionmethod used in SETROI if
%      <method> was specified to be 'edgedetection'.
%
%
%  Valid methods in SETROI:
%  ------------------------
%
%  'box':           Rectangular box.
%                   If no parameters are specified, the user can draw the
%                   rectangle inside the image using the mouse. If the
%                   image data was not displayed yet, a scaled image of the
%                   log10(I) of the image data (to enhance contrast) is
%                   displayed in a new figure.
%                   <parms> and <outparms> are 4-element vectors of the
%                   form [xmin ymin width height].
%                   When using the method 'box', the resulting ROI is
%                   guaranteed to be simply connected (i.e. a convex set
%                   with only one outside boundary).
%
%  'polygon':       Bounding polygon.
%                   If no parameters are specified, the user can draw the
%                   polygon inside the image figure using the mouse. Each
%                   vertex is added by a single left-click on the image. To
%                   finish the polygon use a double click. Care must be
%                   taken with intersecting polygon lines, those can
%                   produce undesired results.
%                   If the image data was not displayed yet, a scaled image
%                   of the log10(I) of the image data (to enhance contrast)
%                   is displayed in a new figure.
%                   <parms> and <outparms> is a n-by-2 array with the x-
%                   and y-coordinates of the bounding polygon vertices in
%                   the first and second column, respectively. <outparms>
%                   returns vertices of a closed polygon (i.e. the first
%                   xy-pair is equal to the last one). if <parms> is not a
%                   closed polygon, setroi will close it by copying the
%                   first vertex to the end of the array.
%
%  'edgedetection': Find the ROI by detecting edges (i.e. steep gradients)
%                   in the image data. Internally, this method uses the
%                   EDGE function provided by MATLAB, followed by a
%                   sequence of manipulation steps which improve the
%                   chances of finding filled regions rather than just the
%                   edges by which they are enclosed.
%                   <parms> and <outparms> are directly passed to and from
%                   the EDGE function, please refer to the EDGE
%                   documentation for more information about valid
%                   parameter values. If <parms> is not supplied or is
%                   empty, the parameters for edge detection are determined
%                   automatically by EDGE.
%                   Several algorithms for edge detection are available in
%                   EDGE, all of which are also valid in SETROI: 'sobel',
%                   'prewitt', 'roberts', 'log', 'zerocross', and 'canny'.
%                   These can be specified through the
%                   <edgedetectionmethod> input argument.
%
%  'threshold':     Image data is transformed into a binary mask by
%                   comparison with a threshold level (pixels with
%                   intensities above threshold produce ones, the others
%                   zeros).
%                   If <parms> is not supplied or empty, the threshold
%                   level is determined automatically by the GRAYTHRESH
%                   function in MATLAB, otherwise the specified level is
%                   used for the conversion.
%                   A series of manipulation steps after the thresholding
%                   procedure is applied to remove noise and to produce
%                   more reliable filled regions which can be used as
%                   sensible ROIs.
%
%  See also:
%  ---------
%
%  BOUNDINGPOLYGON on how the bounding polygon vertices in the output are
%  generated.
%  GETRECT and GETLINE for defining box and polygon regions of interest.
%  EDGE for the edge detection algorithms provided by MATLAB.
%  GRAYTHRESH and IM2BW for setting a threshold level on image data.

%%
%==========================================================================
% FUNCTION: setroi.m 
%           ========
%
% ---------
% $Date: 2006/10/20 07:37:30 $
% $Author: schlepuetz $
% $Revision: 1.12 $
% $Source: /import/cvs/X/PILATUS/App/lib/X_PILATUS_Matlab/setroi.m,v $
% $Tag: $
%  
% Author(s):            D. Martoccia (DM)
% Co-author(s):         C. Schlepuetz (CS)
% Address:              Surface Diffraction Station
%                       Materials Science Beamline X04SA
%                       Swiss Light Source (SLS)
%                       Paul Scherrer Institut
%                       CH - 5232 Villigen PSI
% Created and (c):      2005/11/03
% 
% Change Log:
% -----------
% 
% 2005/11/03 (DM):
% - start
% 
% 2006/06/20 (CS):
% - major reorganization of setroi.m:
%   - standardized input parameter sequence
%   - added parse_inputs subroutine
%   - removed code of method 'edgedetection'
%   - renamed method 'edgedetectionSD' to 'edgedetection'
%   - 'threshold' is now an independend method
%   - simplified sequential flow of the routine
%   - introduced new output parameters
%
% 2006/09/13 (CS):
% - fixed bug in parse_inputs when not supplying all arguments.
% - fixed bug in 'box' and 'polygon' when specifying image handles.
% - cleaned up help text.

%%
%==========================================================================
% Main function -SETROI
%                ======
%
% input arguments:  BWin/h, ['method', [parms, ['edgedetectionmethod']]]
% output arguments: BWout, [Xcoor, Ycoor, [nlines, [outparms, ['method',
%                   ['edgedetectionmethod']]]]]
%

function varargout = setroi(varargin)

% parse input arguments
[I, h, method, parms, edgedetectionmethod] = parse_inputs(varargin{:});

% check number of output arguments
error(nargoutchk(1, 7, nargout))

%%
%=====================================
% Find resulting mask image and output
% parameters for the different methods

switch method
        
    %=========
    case 'box'
           
        if isempty(parms)
            
            % only draw a new figure if image is not already displayed and
            % active on screen.
            
            if isempty(h)
                Itemp = double(I);
                Itemp(Itemp ~= 0) = log10(Itemp(Itemp ~= 0));
                h = imagesc(Itemp);
                h = get(h,'Parent');            
            elseif isempty(getimage(h)) || ...
                    any(size(getimage(h)) ~= size(I));
                Itemp = double(I);
                Itemp(Itemp ~= 0) = log10(Itemp(Itemp ~= 0));
                h = imagesc(Itemp);
                h = get(h,'Parent');
            elseif I ~= getimage(h);
                Itemp = double(I);
                Itemp(Itemp ~= 0) = log10(Itemp(Itemp ~= 0));
                h = imagesc(Itemp);
                h = get(h,'Parent');
            end

            rect = getrect(h);
            x1 = rect(1);
            y1 = rect(2);
            x2 = rect(1)+rect(3);
            y2 = rect(2)+rect(4);
            x = [x1,x2,x2,x1];
            y = [y1,y1,y2,y2];
            outparms = rect;

        else
            x1 = parms(1);
            y1 = parms(2);
            x2 = parms(1)+parms(3);
            y2 = parms(2)+parms(4);
            x = [x1,x2,x2,x1];
            y = [y1,y1,y2,y2];
            outparms = parms;

        end

        BWout = roipoly(I,x,y);

        
    %================    
    case {'polygon'};

        if isempty(parms)
            
            % only draw a new figure if image is not already displayed and
            % active on screen.
            if isempty(h)
                Itemp = double(I);
                Itemp(Itemp ~= 0) = log10(Itemp(Itemp ~= 0));
                h = imagesc(Itemp);
                h = get(h,'Parent');
            elseif isempty(getimage(h)) || ...
                    any(size(getimage(h)) ~= size(I));
                Itemp = double(I);
                Itemp(Itemp ~= 0) = log10(Itemp(Itemp ~= 0));
                h = imagesc(Itemp);
                h = get(h,'Parent');
            elseif I ~= getimage(h);
                Itemp = double(I);
                Itemp(Itemp ~= 0) = log10(Itemp(Itemp ~= 0));
                h = imagesc(Itemp);
                h = get(h,'Parent');
            end 
            
            [x,y] = getline(h);
            BWout = roipoly(I,x,y);
            outparms = [x,y];

        elseif iscell(parms)
            BWout = zeros(size(I));
            xi = parms(:,1);
            yi = parms(:,2);
            for i = 1:length(xi)
                BWout = BWout | roipoly(I,xi{i},yi{i});
            end
            outparms = parms;

        else
            [dim1,dim2] = size(parms);
            if dim1 < dim2
                parms = parms';
            end

            x = parms(:,1);
            y = parms(:,2);
            BWout = roipoly(I,x,y);
            outparms = parms;

        end;

        
    %===================    
    case 'edgedetection'
       
        I2 = I/max(I(:));
        I2 = medianfilter(I2,[3 3],[],[],[],'mean'); %smooths the image
        edgedetectionparms = parms;
        [edge_image,outparms] = ...
            edge(I2,edgedetectionmethod,edgedetectionparms);
        se1 = strel('disk',1);

        edge_image = bwmorph(edge_image,'bridge'); % fill in bridge pixels
        edge_image = bwmorph(edge_image,'clean');  % remove hot pixels
        edge_image = imdilate(edge_image, se1);    % dilate edge_image
        edge_image = bwmorph(edge_image,'bridge'); % fill in bridge pixels

        BWout = imfill(edge_image,'holes');        % fill holes
        BWout = bwareaopen(BWout,10);              % remove features<20 pix
        BWout = imerode(BWout,se1);                % erode BWout
        BWout = bwareaopen(BWout,4);               % remove features<4 pix
        BWout = imdilate(BWout,se1);               % dilate BWout

        
    %==================    
    case {'threshold'}

        if isempty(parms)
            % find thresh level if not supplied by user
            parms = graythresh(I);
        end

        I = I./max(I(:));
        BWout = im2bw(I, parms);
        BWout = double(BWout);
        BWout = edge(BWout);
        
        se1 = strel('disk',1);
        BWout = bwmorph(BWout,'bridge');   % fill in bridge pixels
        BWout = bwmorph(BWout,'clean');    % remove single hot pixels
        BWout = imdilate(BWout, se1);      % dilate BWout
        BWout = bwmorph(BWout,'bridge');   % fill in bridge pixels
        BWout = imfill(BWout,'holes');     % fill holes
        BWout = bwareaopen(BWout,10);      % remove features < 20 pix
        BWout = imerode(BWout,se1);        % erode BWout
        BWout = bwareaopen(BWout,4);       % remove features < 4 pix
        BWout = imdilate(BWout,se1);       % dilate BWout
                
        outparms = parms;
end

%%
%========================
% Assign output arguments

varargout{1} = BWout;

if nargout > 1
    [x,y] = boundingpolygon(BWout);
    varargout{2} = x;
    varargout{3} = y;
end

if nargout > 3 
    if iscell(varargout{2})
        celldim = size(varargout{2});
        nlines = celldim(1);
    else
        nlines = 1;
    end
    varargout{4} = nlines;
end

if nargout > 4
    varargout{5} = outparms;
end

if nargout > 5
    varargout{6} = method;
end

if nargout > 6
    varargout{7} = edgedetectionmethod;
end


%%
%==========================================================================
%  Sub-function - parse_inputs
%  ===========================
%
%  used to parse the input paramters to the main function.
%  input arguments:  BWin/h, ['method', [parms, ['edgedetectionmethod']]]

function [I, h, method, parms, edgedetectionmethod] = ...
    parse_inputs(varargin)

error(nargchk(0,4,nargin));

% check if an image or image handle is given as input parameter
if nargin == 0
    I = getimage;
    h = imgca;
elseif isempty(varargin{1})
    I = getimage;
    h = imgca;
elseif ishandle(varargin{1})
    h = varargin{1};
    I = getimage(h);
else
    I = varargin{1};
    if ~isempty(findobj('Type','image'))
        h = imgca;
    else
        h = [];
    end
end

% check whether image contains data.
if isempty(I)
    eid = sprintf('Images:%s:ImageDataNotFound',mfilename);
    error(eid,'%s %s','Could not find image data.',...
        'Invalid handle or empty image matrix');
end

% check whether method is supplied and valid

if nargin < 2
    varargin{2} = 'box';
elseif isempty(varargin{2})
    varargin{2} = 'box';
elseif ~ischar(varargin{2})
    eid = sprintf('Images:%s:MethodMustBeString',mfilename);
    error(eid,'%s %s %s','The ''method'' argument in',mfilename,...
        'must be a string');
end

method = lower(varargin{2});
if ~(strcmp(method,'box') || strcmp(method,'polygon') ||...
        strcmp(method,'edgedetection') || strcmp(method,'threshold'))
    eid = sprintf('Images:%s:invalidMethod',mfilename);
    error(eid,'%s %s','Invalid string for ''method'' in', mfilename);
end

% check whether supplied parameters are valid depending on method.
if nargin < 3
    varargin{3} = [];
end

parms = varargin{3};
switch method
    case 'box'
        if ~(isempty(parms) || all(size(parms) == [1 4]))
            eid = sprintf('Images:%s:invalidParamter',mfilename);
            error(eid,'%s %s %s %s',...
                'Invalid paramters for method ''box'' in', ...
                mfilename, '''parms'' must be 1-by-4 array',...
                '[xmin ymin width height]');
        end

    case 'polygon'
        pardim = size(parms);
        xdim = pardim(2);
        if (xdim ~= 2 && ~isempty(parms))
            eid = sprintf('Images:%s:invalidParamter',mfilename);
            error(eid,'%s %s %s %s %s %s',...
                'Invalid paramters for method ''polygon'' in', ...
                mfilename, '''parms'' must be n-by-2 array or',...
                'cell array with x-vertices (or cell array) in',...
                'the first column and y-vertices (or cell array)',...
                'in the second column');
        end

    case 'edgedetection'
        % MATLAB function 'edge' supplies error messages by itself.
        % nothing to be done.

    case 'threshold'
        if ~(isempty(parms) || all(size(parms) == [1 1]))
            eid = sprintf('Images:%s:invalidParamter',mfilename);
            error(eid,'%s %s %s %s',...
                'Invalid paramters for method ''threshold'' in', ...
                mfilename, '''parms'' must be a double',...
                '<threshold_value>');
        end
end

% check whether supplied edgedetection method is valid.
if nargin < 4
    varargin{4} = 'canny';      % set default method
elseif isempty(varargin{4})
    varargin{4} = 'canny';      % set default method
end

edgemeth = lower(varargin{4});
if ~(strcmp(edgemeth,'sobel') || strcmp(edgemeth,'prewitt') ||...
        strcmp(edgemeth,'roberts') || strcmp(edgemeth,'log') ||...
        strcmp(edgemeth,'zerocross') || strcmp(edgemeth,'canny'))
    eid = sprintf('Images:%s:invalidEdgeDetectionMethod',mfilename);
    error(eid,'%s %s','Invalid string for ''edgedetectionmethod'' in', ...
        mfilename);
else
    edgedetectionmethod = edgemeth;
end


%==========================================================================
%
%---------------------------------------------------%
% emacs setup:  force text mode to get no help with %
%               indentation and force use of spaces %
%               when tabbing.                       %
% Local Variables:                                  %
% mode:text                                         %
% indent-tabs-mode:nil                              %
% End:                                              %
%---------------------------------------------------%
%
% $Log: setroi.m,v $
% Revision 1.12  2006/10/20 07:37:30  schlepuetz
% cleanup, cross-checked by co-author
%
% Revision 1.11  2006/10/13 08:04:02  schlepuetz
% major reorganization - not compatible with previous version
%
%
%
%============================== End of $RCSfile: setroi.m,v $ ===
