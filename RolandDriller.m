function [drill] = RolandDriller()

% This software was created by the Microfluidics group at LBL as a tool to
% drill holes in patterns that need alignment with the Roland Modela 3D
% plotter.
%
%Luis Ardila 		leardilap@unal.edu.co		11/22/11

drill.close = @Quit_Callback;

% Create hs handles structure
interfaceHandle = openfig('RolandDriller');
hs = getHandles(interfaceHandle);

% Set window title
set(interfaceHandle, 'Name', 'Roland Driller');

% Set Callbacks
set(hs.Move, 'Callback', @Move_Callback);
set(hs.OpenDxf, 'Callback', @OpenDxf_Callback);
set(hs.Next, 'Callback', @Next_Callback);
set(hs.Drill, 'Callback', @Drill_Callback);
set(hs.XMinus, 'Callback', @XMinus_Callback);
set(hs.XPlus, 'Callback', @XPlus_Callback);
set(hs.YMinus, 'Callback', @YMinus_Callback);
set(hs.YPlus, 'Callback', @YPlus_Callback);
set(hs.ZMinus, 'Callback', @ZMinus_Callback);
set(hs.ZPlus, 'Callback', @ZPlus_Callback);
set(hs.SetZ0, 'Callback', @SetZ0_Callback);
set(hs.Scale, 'Callback', @Scale_Callback);
set(hs.DrillAll, 'Callback', @DrillAll_Callback);
set(hs.PenDown, 'Callback', @PenDown_Callback);
set(hs.Remove, 'Callback', @Remove_Callback);
set(hs.FinishCalibration, 'Callback', @FinishCalibration_Callback);
set(hs.Apply, 'Callback', @Apply_Callback);
set(hs.Add, 'Callback', @Add_Callback);
set(hs.Plot, 'Callback', @Plot_Callback);
set(hs.Pause,'Callback', @Pause_Callback);
set(hs.HolesWindow,'Callback', @Plot_Callback);
% set(hs.About, 'Callback', @About_Callback);

set(interfaceHandle, 'CloseRequest', @Quit_Callback);

% Initialize common variables
circles = [];               %Circles Working Variable
circlesO = [];              %Circles Original
circlesP = [];              %Circles Past
calibrationHoles = [];   
XDisp = 0;
YDisp = 0;
FlagCal = 0;



% Initialize serial port
sid = serial('COM1');               %Use this to communicate to
                                    %the Roland Milling Machine
% sid = fopen('drill.txt','w');       %Use this in order to make 
                                    %programing test without sending 
                                    %the commands to the Roland Milling 
                                    %Machine
fopen(sid); %--open the serial port 

Initialization();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get handles in new GUI
    function [handles] = getHandles(handle)
        ch = get(handle,'Children');
        handles=[];
        if ~isempty(ch)
            for jj = 1:length(ch)
                t=get(ch(jj), 'Tag');
                handles.(get(ch(jj), 'Tag')) = ch(jj);
            end
            
            for jj = 1: length(ch)
                handlesChildren = getHandles(ch(jj));
                
                if ~isempty(handlesChildren)
                    fieldNames1 = fieldnames(handles);
                    fieldNames2 = fieldnames(handlesChildren);
                    fieldNames = [fieldNames1; fieldNames2];
                    
                    c1 = struct2cell(handles);
                    c2 = struct2cell(handlesChildren);
                    c=[c1;c2];
                    
                    handles = cell2struct(c,fieldNames,1);
                end
            end
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function Quit_Callback(hObject,eventData)
        sid = serial('COM1');
        fclose(sid);
        
        delete(sid) 
        clear sid
        delete(interfaceHandle);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function Initialization()
 
        calibrationHoles = [];  
        circles = [];
        XDisp = 0;
        YDisp = 0;
        FlagCal = 0;
        
        set(hs.HolesWindow,'String', '');
        set(hs.CalibrationHolesWindow,'String', '');
        set(hs.CalibrationHolesWindow,'Value', 1);
        
 %         Disable buttons        
        set(hs.HolesWindow,'Enable', 'off');
        set(hs.CalibrationHolesWindow,'Enable', 'off');
 
        set(hs.Units,'Enable', 'off');
        set(hs.Scale,'Enable', 'off');
        set(hs.Next,'Enable', 'off');
        set(hs.Move,'Enable', 'off');
        set(hs.PenDown,'Enable', 'off');
        set(hs.Drill,'Enable', 'off');
        set(hs.DrillAll,'Enable', 'off');
        set(hs.Pause,'Enable', 'off');
        
        set(hs.ZSpeed,'Enable', 'off');
        set(hs.Cut,'Enable', 'off');
        set(hs.NPecks,'Enable', 'off');
        set(hs.SPecks,'Enable', 'off');
        
        set(hs.XMinus, 'Enable', 'off');
        set(hs.XPlus, 'Enable', 'off');
        set(hs.YMinus, 'Enable', 'off');
        set(hs.YPlus, 'Enable', 'off');
        set(hs.Step, 'Enable', 'off');
        set(hs.ZMinus, 'Enable', 'off');
        set(hs.ZPlus, 'Enable', 'off');
        set(hs.SetZ0, 'Enable', 'off');
        
        set(hs.XZero, 'Enable', 'off');
        set(hs.YZero, 'Enable', 'off');
        set(hs.Remove, 'Enable', 'off');
        set(hs.Plot, 'Enable', 'off');
        set(hs.Add, 'Enable', 'off');
        set(hs.Apply, 'Enable', 'off');
        set(hs.FinishCalibration, 'Enable', 'off');
          
      

    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in open_dxf.
    function OpenDxf_Callback(hObject, eventdata)
        
        Initialization()
        
        [ circles, corners , filename , path ] = OpenDxf();
        circlesO = circles;
        circlesP = circles;
        
        txt = {};
        for ii = 1:length(circles)
            txt{ii} = [num2str(ii) ' || ' num2str(circles(ii, 1), '%8.7g') ...
                        '  ,   ' num2str(circles(ii, 2), '%8.7g')];
        end
        set(hs.HolesWindow,'String', txt);
        set(hs.HolesWindow,'Enable', 'on');
        
        txt1 = ['# of circles: ' num2str(length(circles))];  
        set(hs.CirclesNumber,'String', txt1);
        
        %Enable Scale Buttons
        set(hs.Units,'Enable', 'on');
        set(hs.Scale,'Enable', 'on');
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function Scale_Callback(hObject,eventData)
        
            switch get(hs.Units,'Value')
                case 1
                    scalingFactor = 1/25.4;
                    
                case 2
                    scalingFactor = 1/0.0254;
                    
                case 3
                    scalingFactor = 1/0.00254;
                    
                case 4
                    scalingFactor = 1000;
                
                case 5
                    scalingFactor = 1;
                    
                otherwise
            end
            
        circles = circlesO*scalingFactor;
        circlesP = circles;
        PrintHoles();
        calibrationHoles = [];  
        PrintCalibrationHoles();
%         set(hs.XZero, 'Enable', 'on');
%         set(hs.YZero, 'Enable', 'on');
%         set(hs.Remove, 'Enable', 'on');
        set(hs.Plot, 'Enable', 'on');
        set(hs.Add, 'Enable', 'on');
        set(hs.CalibrationHolesWindow,'Enable', 'on');
        
        
%         set(hs.Apply, 'Enable', 'on');
         
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on selection change in SetZ0
    function SetZ0_Callback(hObject, eventdata)
        fprintf(sid, 'PR;!ZO;!PZ0,300;');
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on selection change in Next
    function Next_Callback(hObject, eventdata)
        
            if get(hs.HolesWindow,'Value') < length(circles)
                v = get(hs.HolesWindow,'Value')+1;
                set(hs.HolesWindow,'Value', v);
            end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in move.
    function Move_Callback(hObject, eventdata)
        if FlagCal == 0
            c = get(hs.HolesWindow,'Value');
            a = num2str(circles(c,1));
            b = num2str(circles(c,2));
        end
        if FlagCal == 1
            c = get(hs.CalibrationHolesWindow,'Value');
            a = num2str(calibrationHoles(c,2));
            b = num2str(calibrationHoles(c,3));
        end
        
        Move = ['!MC0;PA;PU' a ',' b ';'];
        fprintf(sid, Move);
        
        set(hs.XZero,'String', a);
        set(hs.YZero,'String', b);
        pause(2);
        Enable_Edit();
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on selection change in Drill
    function Drill_Callback(hObject, eventdata)
        
        
        c = get(hs.HolesWindow,'Value');
        a = num2str(circles(c,1));
        b = num2str(circles(c,2));
        Move = ['!MC0;PA;PU' a ',' b ';'];
        fprintf(sid, Move);
        pause(2);
        fprintf(sid, '!PZ0,300;!MC1;PR;PD;');
%         pause(0.5);
        SPeck = get(hs.SPecks, 'String');
        ZSpeed = get(hs.ZSpeed, 'String');
        NPecks = str2num(get(hs.NPecks, 'String'));
        NPecks1 = str2num(get(hs.NPecks, 'String'));
        Steps = str2num(get(hs.Cut, 'String'))/str2num(get(hs.SPecks, 'String'));
        sizePeck = str2num(SPeck);
        
        for ii = 0:Steps
            P = num2str(sizePeck*ii);
            set(hs.depthInfo,'String', P);
            Drill1 = ['PR;!VZ10.0;!ZM-' P ';!VZ' ZSpeed ';!ZM-' SPeck ';'];
            Drill2 = ['!VZ10.0;!ZM' SPeck ';!ZM' P ';'];
            NPecks1 = NPecks;
            set(hs.HolesWindow, 'Enable','off');
            for kk = 1:NPecks1
                fprintf(sid, Drill1);
                pause(0.3+sizePeck*ii*0.02);
                fprintf(sid, Drill2);
                pause(0.3);
                set(hs.peckInfo, 'String', kk);
                pauseState = get(hs.Pause,'Value');
                while pauseState
                    set(hs.peckInfo, 'String', kk);
                    pause(5);
                    Pause_Callback();
                    set(hs.HolesWindow, 'Enable','on');
                    pauseState = get(hs.Pause,'Value');
                end
                
            end
        end
        fprintf(sid, Move);
        set(hs.HolesWindow, 'Enable','on');
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on selection change in YMinus
    function YMinus_Callback(hObject, eventdata)
        s = get(hs.Step,'String');
        a = num2str(s);
        YMinus = ['PR0,-' a ';'];
        fprintf(sid, YMinus);
       
        y = get(hs.YZero,'String');
        yy = str2num(y)-str2num(s);
                
        set(hs.YZero,'String',yy);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on selection change in YPlus
    function YPlus_Callback(hObject, eventdata)
        s = get(hs.Step,'String');
        a = num2str(s);
        YPlus = ['PR0,' a ';'];
        fprintf(sid, YPlus);
        
        y = get(hs.YZero,'String');
        yy = str2num(y)+str2num(s);
                
        set(hs.YZero,'String',yy);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on selection change in XMinus
    function XMinus_Callback(hObject, eventdata)
        s = get(hs.Step,'String');
        a = num2str(s);
        XMinus = ['PR-' a ',0;'];
        fprintf(sid, XMinus);
        
        x = get(hs.XZero,'String');
        xx = str2num(x)-str2num(s);
                
        set(hs.XZero,'String',xx);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on selection change in XPlus
    function XPlus_Callback(hObject, eventdata)
        s = get(hs.Step,'String');
        a = num2str(s);
        XPlus = ['PR' a ',0;'];
        fprintf(sid, XPlus);
        
        x = get(hs.XZero,'String');
        xx = str2num(x)+str2num(s);
                
        set(hs.XZero,'String',xx);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on selection change in ZMinus
    function ZMinus_Callback(hObject, eventdata)
        s = get(hs.Step,'String');
        a = num2str(s);
        ZMinus = ['PR;!ZM-' a ';'];
        fprintf(sid, ZMinus);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on selection change in ZPlus
    function ZPlus_Callback(hObject, eventdata)
        s = get(hs.Step,'String');
        a = num2str(s);
        ZPlus = ['PR;!ZM' a ';'];
        fprintf(sid, ZPlus);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function SetOrigin(hObject,eventData)
            
            [m, n] = size(calibrationHoles);
            x = get(hs.XZero,'String');
            XDisp = str2num(x);
            y = get(hs.YZero,'String');
            YDisp = str2num(y);

            for ii = 1:length(circles)
                circles(ii, 1) = circlesP(ii, 1) + XDisp;
                circles(ii, 2) = circlesP(ii, 2) + YDisp;
            end
            
            
            for ii = 1:m
               v = calibrationHoles(ii,1); 
               calibrationHoles(ii, 2) = circles(v, 1);
               calibrationHoles(ii, 3) = circles(v, 2);
               calibrationHoles(ii, 4) = circles(v, 1);
               calibrationHoles(ii, 5) = circles(v, 2);
            end
        
        PrintHoles();
        PrintCalibrationHoles();
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function DrillAll_Callback(hObject,eventData)
        position = get(hs.HolesWindow,'Value');
        Move_Callback();
        
        Disable_Edit();
        set(hs.HolesWindow, 'Enable','off');
        
        for dd = position:length(circles)
            Drill_Callback();
            Next_Callback();
        end
        
        Enable_Edit();
        set(hs.HolesWindow, 'Enable','on');
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function PenDown_Callback(hObject,eventData)
        fprintf(sid, '!VZ10.0;PR;PD;');
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function Disable_Edit()
        set(hs.NPecks,'Enable', 'off');
        set(hs.SPecks,'Enable', 'off');
        set(hs.ZSpeed,'Enable', 'off');
        set(hs.Cut,'Enable', 'off');
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function Enable_Edit()
        set(hs.NPecks,'Enable', 'on');
        set(hs.SPecks,'Enable', 'on');
        set(hs.ZSpeed,'Enable', 'on');
        set(hs.Cut,'Enable', 'on');
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function FinishCalibration_Callback(hObject,eventData)
        
            [m, n] = size(calibrationHoles);
            Pos1 = [calibrationHoles(2,4) - XDisp; calibrationHoles(2,5) - YDisp];
            Des1 = [calibrationHoles(2,2) - XDisp; calibrationHoles(2,3) - YDisp];
        
            Pos2 = [calibrationHoles(3,4) - XDisp; calibrationHoles(3,5) - YDisp];
            Des2 = [calibrationHoles(3,2) - XDisp; calibrationHoles(3,3) - YDisp];
            
            b = [Pos1 - [calibrationHoles(1,2)- XDisp; calibrationHoles(1,3) - YDisp]; ...
                Pos2 - [calibrationHoles(1,2)- XDisp; calibrationHoles(1,3) - YDisp]];

            A = [Des1' 0 0 ; 0 0 Des1' ; Des2' 0 0 ; 0 0 Des2'];
            % Solve system of equations to find
            % transformation matrix elements
            v = A\b;
            % Transformation matrix
            M = [v(1) v(2); v(3) v(4)];
            
            for ii = 1:length(circlesP)
                temp = M * [circlesP(ii,1); circlesP(ii,2)];
                circles(ii,1) = temp(1) + XDisp;
                circles(ii,2) = temp(2) + YDisp;

            end
                
            for ii = 1:m
                    v = calibrationHoles(ii,1);
                    calibrationHoles(ii,2) = circles (v,1);
                    calibrationHoles(ii,3) = circles (v,2);
            end
            
            FlagCal = 0;
            PrintHoles();
            PrintCalibrationHoles();
            calibrationHoles;   
            
            %Disable buttons            
            set(hs.XMinus, 'Enable', 'off');
            set(hs.XPlus, 'Enable', 'off');
            set(hs.YMinus, 'Enable', 'off');
            set(hs.YPlus, 'Enable', 'off');
%             set(hs.Step, 'Enable', 'off');

            set(hs.XZero, 'Enable', 'off');
            set(hs.YZero, 'Enable', 'off');
            set(hs.Add, 'Enable', 'off');
            set(hs.Apply, 'Enable', 'off');
            set(hs.FinishCalibration, 'Enable', 'off');
            set(hs.CalibrationHolesWindow,'Enable', 'off');
            
            %Enable buttons   
            set(hs.Next,'Enable', 'on');
            set(hs.Drill,'Enable', 'on');
            set(hs.DrillAll,'Enable', 'on');
            set(hs.Pause,'Enable', 'on');
            Enable_Edit();
            
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function Apply_Callback(hObject,eventData)
        
        x = get(hs.XZero,'String');
        xx = str2num(x);
        y = get(hs.YZero,'String');
        yy = str2num(y);
        v = get(hs.CalibrationHolesWindow,'Value');
        
        if v == 1
            SetOrigin()
        else
            calibrationHoles(v,4) = xx;
            calibrationHoles(v,5) = yy;
        end 
        PrintCalibrationHoles();
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function PrintHoles()
        set(hs.HolesWindow,'String', '');
        txt = {};
        for ii = 1:length(circles)
            txt{ii} = [num2str(ii) ' || ', num2str(circlesO(ii, 1), '%8.7g') '  ,   ' ...
                       num2str(circlesO(ii, 2), '%8.7g') '  ||  ' num2str(circles(ii, 1), '%8.7g')...
                       '  ,   ' num2str(circles(ii, 2), '%8.7g')];
        end
        
                
        set(hs.HolesWindow,'String', txt);
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function PrintCalibrationHoles()
 
        set(hs.CalibrationHolesWindow,'String', '');
        txt{1} = 'Please Add Calibration Point';
        txt{2} = 'Please Add Calibration Point';
        txt{3} = 'Please Add Calibration Point';
        [m, n] = size(calibrationHoles);
        if m > 0
        for ii = 1:m
            txt{ii} = [num2str(calibrationHoles(ii, 1)) ' || ' num2str(calibrationHoles(ii, 2), '%8.7g') '  ,   ' ...
                       num2str(calibrationHoles(ii, 3), '%8.7g') '  ||  ' num2str(calibrationHoles(ii, 4), '%8.7g') ...
                        '  ,   ' num2str(calibrationHoles(ii, 5), '%8.7g')];
        end
        end      
        set(hs.CalibrationHolesWindow,'String', txt);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function Add_Callback(hObject,eventData)
        [m, n] = size(calibrationHoles);
        c = m + 1;   
               
        if m < 3
            v = get(hs.HolesWindow,'Value');
            calibrationHoles(c,1) = v;
            calibrationHoles(c,2) = circlesP(v,1);
            calibrationHoles(c,3) = circlesP(v,2);
            calibrationHoles(c,4) = circlesP(v,1);
            calibrationHoles(c,5) = circlesP(v,2);
            calibrationHoles;
            set(hs.XZero, 'String', circlesP(v,1));
            set(hs.YZero, 'String', circlesP(v,2));
            
            PrintCalibrationHoles();
        
        end
        
        if c == 3
            set(hs.Add,'Enable','Off');
            set(hs.Apply,'Enable', 'On');
            set(hs.XZero, 'Enable', 'on');
            set(hs.YZero, 'Enable', 'on');
            FlagCal = 1;
            set(hs.Move, 'Enable', 'on');
            set(hs.PenDown, 'Enable', 'on');
            set(hs.XMinus, 'Enable', 'on');
            set(hs.XPlus, 'Enable', 'on');
            set(hs.YMinus, 'Enable', 'on');
            set(hs.YPlus, 'Enable', 'on');
            set(hs.Step, 'Enable', 'on');
            set(hs.ZMinus, 'Enable', 'on');
            set(hs.ZPlus, 'Enable', 'on');
            set(hs.SetZ0, 'Enable', 'on');
            set(hs.FinishCalibration, 'Enable', 'on');
            set(hs.Units,'Enable', 'off');
            set(hs.Scale,'Enable', 'off');
            
            v = calibrationHoles(1,1);
            
            for ii = 1:length(circlesP)
                circles(ii, 1) = circlesP(ii, 1) - circlesP(v, 1);
                circles(ii, 2) = circlesP(ii, 2) - circlesP(v, 2);
            end
            
            for ii = 1:3
               v = calibrationHoles(ii,1); 
               calibrationHoles(ii, 2) = circles(v, 1);
               calibrationHoles(ii, 3) = circles(v, 2);
               calibrationHoles(ii, 4) = circles(v, 1);
               calibrationHoles(ii, 5) = circles(v, 2);
            end
            
            circlesP = circles;
            PrintHoles();
            PrintCalibrationHoles();
            
        end 
        
        if c
            set(hs.Remove,'Enable','On');
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function Remove_Callback(hObject,eventData)
        v = get(hs.CalibrationHolesWindow,'Value');
        
        calibrationHoles(v,:) = []
        
        PrintCalibrationHoles();
        
        set(hs.Add,'Enable','On');
        [m, n] = size(calibrationHoles);
        if m < 1
            set(hs.Remove,'Enable','Off');
        end    
        set(hs.CalibrationHolesWindow,'Enable', 'on');
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function Plot_Callback(hObject,eventData)
        try
            delete(figureID);
        end
        
        for ii = 1:length(circlesO)
            X(ii)=circlesO(ii, 1);
            Y(ii)= circlesO(ii, 2);
            XX(ii)=circles(ii, 1);
            YY(ii)= circles(ii, 2);
        end
        
        chosenHole = get(hs.HolesWindow,'Value');
        figureID = figure(1);
        set(figureID,'position',[0, 500, 650, 400]);
        set(figureID, 'Name', 'Plot Figure');
        
        subplot(1,2,1);
        plot(X,Y,'co',X(chosenHole),Y(chosenHole),'ro','MarkerSize',2);
        title('Circles Design')
        axis square;
        axis image;        
        subplot(1,2,2); 
        plot(XX,YY,'co',XX(chosenHole),YY(chosenHole),'ro','MarkerSize',2);
        title('Circles Milling Machine')
        axis square;
        axis image;
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function Pause_Callback(hObject,eventData)
        pauseState = get(hs.Pause,'Value');
        if pauseState == 1 
        set(hs.Pause,'string', 'Resume');
        fprintf(sid, '!MC0;');
        else
        set(hs.Pause,'string', 'Pause'); 
        fprintf(sid, '!MC1;');
        end
    end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % --- Executes on menu select in About.
%     function About_Callback(hObject, eventData)
%         
%         str = {'Roland drilling code generator with alignment'; 'Ver. 1.0, November 2011'; ...
%             'Luis Ardila'; 'Engineering Division'; 'Lawrence Berkeley National Laboratory'};
%         img = imread('about.jpg');
%         aboutdlg('Title', 'Roland drilling code generator with alignment v.1.0', 'String', str, 'Image', img);
%     end
end
