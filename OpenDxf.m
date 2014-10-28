function [ circles, corners, filename, path ] = OpenDxf()

%This function reads the structure of a DXF file, finding the circles and
%corners of certain design, also provides the filename and path

%Luis Ardila 		leardilap@unal.edu.co		09/28/11
        
        [filename,path]=uigetfile('*.dxf','DXF File');

        fid = fopen(filename,'rt');

        cont = 0;
        cont1 = 0;
        circles = [];
        corners = [];

        while feof(fid) == 0

            txt = fgetl(fid); 

            if strcmp(txt,'CIRCLE')
                while ~strcmp(txt,'AcDbCircle')
                    txt = fgetl(fid); 
                    if strcmp(txt,'AcDbCircle')

                        cont=cont+1;
                        txt = fgetl(fid); 
                        txt = fgetl(fid);   %X pos
                        circles(cont,1)=str2num(txt);

                        txt = fgetl(fid);
                        txt = fgetl(fid);   %Y pos
                        circles(cont,2)=str2num(txt);

                        txt = fgetl(fid); 
                        txt = fgetl(fid);   %Z pos
                        txt = fgetl(fid);
                        txt = fgetl(fid);   %Radius 
                        circles(cont,3)=str2num(txt);
                        break
                    end
                end
            end    
            if strcmp(txt,'LWPOLYLINE')
                while ~strcmp(txt, 'ENDSEC')
                    txt = fgetl(fid);
                    num = str2num(txt);
                    if num == 10
                        cont1=cont1+1;
                        txt = fgetl(fid);   %X pos
                        corners(cont1,1)=str2num(txt);

                        txt = fgetl(fid);
                        txt = fgetl(fid);   %Y pos
                        corners(cont1,2)=str2num(txt);
                        if cont1 == 4                        
                            break
                        end
                    end
                end
            end

        end%while feof...
        fclose(fid);
        circles;
        corners;
    end
