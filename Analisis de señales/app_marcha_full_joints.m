function app_marcha()

    %% ================= 1. CREACIÓN DE INTERFAZ =================

    fig = uifigure('Name','Plataforma de Análisis de Marcha',...
        'Position',[0 100 1200 700]);
% 
    logo = uiimage(fig,...
    'ImageSource','logo UPS circulo.png',...
    'Position',[0 640 400 60]); % [ejex ejey ancho alto] de la imagen origen desde la parte infrior izquierda
    
    uilabel(fig,...
    'Text','UNIVERSIDAD POLITÉCNICA SALESIANA',...
    'FontName','Arial',...
    'FontSize',14,...
    'FontWeight','bold',...
    'Position',[230 660 300 30]); %[ejex ejey ancho alto]

    uilabel(fig,...
    'Text','GRUPO DE INVESTIGACIÓN EN INGENIERÍA BIOMÉDICA (GIIB)',...
    'FontName','Arial',...
    'FontSize',14,...
    'FontWeight','bold',...
    'Position',[550 660 500 30]); %[ejex ejey ancho alto]

%     % ===== TITULO =====
%     uilabel(fig,...
%         'Text','Sistema P.A.M',...
%         'FontSize',20,...
%         'FontWeight','bold',...
%         'Position',[170 620 300 30]);

    
    ax = uiaxes(fig,'Position',[50 200 1100 450]);
    title(ax,'Señal')
    xlabel(ax,'Tiempo (s)')
    ylabel(ax,'Ángulo (°)')
    grid(ax,'on')

    %% ================= 2. CONTROLES PRINCIPALES =================

    btnSistema = uibutton(fig,'Text','Cargar Sistema',...
        'Position',[50 170 100 25],...
        'ButtonPushedFcn', @(~,~) cargarSistema());

    btnKino = uibutton(fig,'Text','Cargar Kinovea',...
        'Position',[170 170 100 25],...
        'ButtonPushedFcn', @(~,~) cargarKinovea());
      
    btnCiclo = uibutton(fig,'Text','Seleccionar Ciclo',...
        'Position',[290 170 110 25],...
        'ButtonPushedFcn', @(~,~) seleccionarCiclo());

    btnComparar = uibutton(fig,'Text','Comparar',...
        'Position',[420 170 100 25],...
        'ButtonPushedFcn', @(~,~) comparar());

    %% ================= 3. CHECKBOX DE SEÑALES =================

    panelChecksSys = uipanel(fig,...
    'Title','Señales del Sistema P.A.M',...
    'Position',[50 40 500 110]);

    gridChecks = uigridlayout(panelChecksSys,[3 4]);
    gridChecks.RowHeight = {'1x','1x','1x'};
    gridChecks.ColumnWidth = {'1x','1x','1x','1x'};
    

     panelChecksKino = uipanel(fig,...
    'Title','Señales de Kinovea',...
    'Position',[560 90 250 60]);

    gridChecksKino = uigridlayout(panelChecksKino,[1 3]);
    gridChecksKino.RowHeight = {'1x'};
    gridChecksKino.ColumnWidth = {'1x','1x','1x'};
    
    
    cbRodilla = uicheckbox(gridChecks,...
        'Text','Rodilla Izq',...
        'Value',true,...
        'ValueChangedFcn', @(~,~) actualizarVista());
    
    cbRodillaDerecha = uicheckbox(gridChecks,...
        'Text','Rodilla Der',...
        'Value',false,...
        'ValueChangedFcn', @(~,~) actualizarVista());
    
    cbCadera = uicheckbox(gridChecks,...
        'Text','Cadera lado Izq',...
        'Value',true,...
        'ValueChangedFcn', @(~,~) actualizarVista());
    
    cbCaderaDerecha = uicheckbox(gridChecks,...
        'Text','Cadera lado Der',...
        'Value',false,...
        'ValueChangedFcn', @(~,~) actualizarVista());
    
    cbTobillo = uicheckbox(gridChecks,...
        'Text','Tobillo Izq',...
        'Value',true,...
        'ValueChangedFcn', @(~,~) actualizarVista());
    
    cbTobilloDerecho = uicheckbox(gridChecks,...
        'Text','Tobillo Der',...
        'Value',false,...
        'ValueChangedFcn', @(~,~) actualizarVista());
    
    cbHombroIzquierdo = uicheckbox(gridChecks,...
        'Text','Hombro Izq',...
        'Value',false,...
        'ValueChangedFcn', @(~,~) actualizarVista());
    
    cbHombroDerecho = uicheckbox(gridChecks,...
        'Text','Hombro Der',...
        'Value',false,...
        'ValueChangedFcn', @(~,~) actualizarVista());
    
    cbCodoIzquierdo = uicheckbox(gridChecks,...
        'Text','Codo Izq',...
        'Value',false,...
        'ValueChangedFcn', @(~,~) actualizarVista());
    
    cbCodoDerecho = uicheckbox(gridChecks,...
        'Text','Codo Der',...
        'Value',false,...
        'ValueChangedFcn', @(~,~) actualizarVista());
    
    cbMunecaIzquierda = uicheckbox(gridChecks,...
        'Text','Muñeca Izq',...
        'Value',false,...
        'ValueChangedFcn', @(~,~) actualizarVista());
    
    cbMunecaDerecha = uicheckbox(gridChecks,...
        'Text','Muñeca Der',...
        'Value',false,...
        'ValueChangedFcn', @(~,~) actualizarVista());
    
    cbRodillaK = uicheckbox(gridChecksKino,...
        'Text','Rodilla',...
        'Value',false,...
        'ValueChangedFcn', @(~,~) actualizarVista());
    
    cbCaderaK = uicheckbox(gridChecksKino,...
        'Text','Cadera',...
        'Value',false,...
        'ValueChangedFcn', @(~,~) actualizarVista());
    
    cbTobilloK = uicheckbox(gridChecksKino,...
        'Text','Tobillo ',...
        'Value',false,...
        'ValueChangedFcn', @(~,~) actualizarVista());

    %% ================= 4. CONTROL DE FILTRO =================

    uilabel(fig,'Text','Frecuencia corte',...
        'Position',[850 160 150 20]);

    lblFc = uilabel(fig,...
        'Position',[850 180 200 20],...
        'Text','Fc = 2.0 Hz');

    slider = uislider(fig,...
        'Position',[850 140 300 3],...
        'Limits',[0.5 10],...
        'Value',2,...
        'MajorTicks',0:1:10,...
        'MinorTicks',0:0.5:10,...
        'ValueChangedFcn', @(sld,~) filtrar(sld.Value, lblFc));

    %% ================= 5. DATOS DE LA APP =================

    data = struct();

    %% ================= 6. CARGA DE DATOS =================

    function cargarSistema()

        [file,path] = uigetfile({'*.csv;*.xlsx'}, 'Selecciona archivo del sistema');

        if isequal(file,0)
            return;
        end

        ruta = fullfile(path,file);

        T = readtable(ruta);
        archivo = readmatrix(ruta);
        t_raw = table2array(T(:,1));

        if isdatetime(t_raw)
            disp('tipo de dato datetime')
            data.Tiempo = seconds(t_raw - t_raw(1));
        elseif isnumeric(t_raw)
            disp('tipo de dato scalar')
            data.Tiempo = t_raw - t_raw(1);
        else
            uialert(fig,'Formato de tiempo no soportado','Error')
            return
        end

        data.CaderaIzq   = archivo(:,2);
        data.CaderaDer   = archivo(:,3);
        data.RodillaIzq  = archivo(:,4);
        data.RodillaDer  = archivo(:,5);
        data.TobilloIzq  = archivo(:,6);
        data.TobilloDer  = archivo(:,7);
        data.HombroIzq   = archivo(:,8);
        data.HombroDer   = archivo(:,9);
        data.CodoIzq     = archivo(:,10);
        data.CodoDer     = archivo(:,11);
        data.MunecaIzq   = archivo(:,12);
        data.MunecaDer   = archivo(:,13);

        data.Cadera  = data.CaderaIzq;
        data.Rodilla = data.RodillaIzq;
        data.Tobillo = data.TobilloIzq;

    end

    function cargarKinovea()

        [file,path] = uigetfile({'*.csv;*.xlsx'}, 'Selecciona archivo Kinovea');

        if isequal(file,0)
            return;
        end

        ruta = fullfile(path,file);
        kino = readmatrix(ruta);

        data.kino_t = kino(:,1) / 1000;
        data.kino_t = data.kino_t - data.kino_t(1);

        data.kino_Rodilla = kino(:,2)*(-1);
        data.kino_Tobillo = kino(:,3)*(-1);
        data.kino_Cadera  = kino(:,4)*(-1);

        uialert(fig,'Datos Kinovea cargados','OK');

        actualizarVista()
    end

    %% ================= 7. FILTRADO =================

    function filtrar(fc, lblFc)

        fc = round(fc,1);
        lblFc.Text = ['Fc = ', num2str(fc), ' Hz'];

        if ~isfield(data,'Rodilla')
            return
        end

        dt = mean(diff(data.Tiempo));
        Fs = 1/dt;

        fc = min(fc, 0.9*(Fs/2));

        if fc <= 0
            uialert(fig,'Frecuencia inválida','Error')
            return
        end

        Wn = fc/(Fs/2);
        b = fir1(30, Wn, 'low');

        data.Rodilla_f = filtfilt(b,1,data.Rodilla);
        data.Cadera_f  = filtfilt(b,1,data.Cadera);
        data.Tobillo_f = filtfilt(b,1,data.Tobillo);

        data.RodillaDer_f = filtfilt(b,1,data.RodillaDer);
        data.CaderaDer_f = filtfilt(b,1,data.CaderaDer);
        data.TobilloDer_f = filtfilt(b,1,data.TobilloDer);
        data.HombroIzq_f = filtfilt(b,1,data.HombroIzq);
        data.HombroDer_f = filtfilt(b,1,data.HombroDer);
        data.CodoIzq_f = filtfilt(b,1,data.CodoIzq);
        data.CodoDer_f = filtfilt(b,1,data.CodoDer);
        data.MunecaIzq_f = filtfilt(b,1,data.MunecaIzq);
        data.MunecaDer_f = filtfilt(b,1,data.MunecaDer);

        data.modoComparacion = false;
        actualizarVista()
    end

    %% ================= 8. VISUALIZACIÓN =================

    function actualizarGrafica()

        if ~isfield(data,'Rodilla_f')
            return
        end
    
        cla(ax)
        hold(ax,'on')
    
        labels = {};
    
        % ===== SISTEMA P.A.M - MIEMBRO INFERIOR =====
        if cbRodilla.Value && isfield(data,'Rodilla_f')
            plot(ax, data.Tiempo, data.Rodilla_f, 'b','LineWidth',1.5)
            labels{end+1} = 'Rodilla Izq Sys';
        end
    
        if cbRodillaDerecha.Value && isfield(data,'RodillaDer_f')
            plot(ax, data.Tiempo, data.RodillaDer_f, 'b--','LineWidth',1.5)
            labels{end+1} = 'Rodilla Der Sys';
        end
    
        if cbCadera.Value && isfield(data,'Cadera_f')
            plot(ax, data.Tiempo, data.Cadera_f, 'r','LineWidth',1.5)
            labels{end+1} = 'Cadera Izq Sys';
        end
    
        if cbCaderaDerecha.Value && isfield(data,'CaderaDer_f')
            plot(ax, data.Tiempo, data.CaderaDer_f, 'r--','LineWidth',1.5)
            labels{end+1} = 'Cadera Der Sys';
        end
    
        if cbTobillo.Value && isfield(data,'Tobillo_f')
            plot(ax, data.Tiempo, data.Tobillo_f, 'g','LineWidth',1.5)
            labels{end+1} = 'Tobillo Izq Sys';
        end
    
        if cbTobilloDerecho.Value && isfield(data,'TobilloDer_f')
            plot(ax, data.Tiempo, data.TobilloDer_f, 'g--','LineWidth',1.5)
            labels{end+1} = 'Tobillo Der Sys';
        end
    
        % ===== SISTEMA P.A.M - MIEMBRO SUPERIOR =====
        if cbHombroIzquierdo.Value && isfield(data,'HombroIzq_f')
            plot(ax, data.Tiempo, data.HombroIzq_f, 'm','LineWidth',1.5)
            labels{end+1} = 'Hombro Izq Sys';
        end
    
        if cbHombroDerecho.Value && isfield(data,'HombroDer_f')
            plot(ax, data.Tiempo, data.HombroDer_f, 'm--','LineWidth',1.5)
            labels{end+1} = 'Hombro Der Sys';
        end
    
        if cbCodoIzquierdo.Value && isfield(data,'CodoIzq_f')
            plot(ax, data.Tiempo, data.CodoIzq_f, 'c','LineWidth',1.5)
            labels{end+1} = 'Codo Izq Sys';
        end
    
        if cbCodoDerecho.Value && isfield(data,'CodoDer_f')
            plot(ax, data.Tiempo, data.CodoDer_f, 'c--','LineWidth',1.5)
            labels{end+1} = 'Codo Der Sys';
        end
    
        if cbMunecaIzquierda.Value && isfield(data,'MunecaIzq_f')
            plot(ax, data.Tiempo, data.MunecaIzq_f, 'k','LineWidth',1.5)
            labels{end+1} = 'Muñeca Izq Sys';
        end
    
        if cbMunecaDerecha.Value && isfield(data,'MunecaDer_f')
            plot(ax, data.Tiempo, data.MunecaDer_f, 'k--','LineWidth',1.5)
            labels{end+1} = 'Muñeca Der Sys';
        end
    
        % ===== KINOVEA =====
        if isfield(data,'kino_Rodilla') && cbRodillaK.Value
            plot(ax, data.kino_t, data.kino_Rodilla, 'b:','LineWidth',1.8)
            labels{end+1} = 'Rodilla K';
        end
    
        if isfield(data,'kino_Cadera') && cbCaderaK.Value
            plot(ax, data.kino_t, data.kino_Cadera, 'r:','LineWidth',1.8)
            labels{end+1} = 'Cadera K';
        end
    
        if isfield(data,'kino_Tobillo') && cbTobilloK.Value
            plot(ax, data.kino_t, data.kino_Tobillo, 'g:','LineWidth',1.8)
            labels{end+1} = 'Tobillo K';
        end
    
        hold(ax,'off')
    
        if ~isempty(labels)
            legend(ax, labels)
        else
            legend(ax,'off')
        end
    
        title(ax,'Comparación de señales')
        xlabel(ax,'Tiempo (s)')
        ylabel(ax,'Ángulo (°)')
        grid(ax,'on')
    
        xlim(ax,'auto')
        ylim(ax,'auto')
    
        activarCursor()
    end

    %% ================= 9. CURSOR INTERACTIVO =================

    function activarCursor()

        fig.WindowButtonMotionFcn = [];

        delete(findall(ax,'Tag','cursorLine'))
        delete(findall(ax,'Tag','cursorText'))

        hLine = xline(ax, data.Tiempo(1),'--r','Tag','cursorLine');
        hText = text(ax, data.Tiempo(1), data.Rodilla_f(1), '', 'Tag','cursorText');

        fig.WindowButtonMotionFcn = @(~,~) mouseMove(hLine,hText);
    end

    function mouseMove(hLine,hText)

        if ~isvalid(hLine) || ~isvalid(hText)
            return
        end
    
        senalesActivas = {};
        senalX = [];
        senalY = [];
    
        % ===== SISTEMA P.A.M - MIEMBRO INFERIOR =====
        if cbRodilla.Value && isfield(data,'Rodilla_f')
            senalesActivas{end+1} = 'Rodilla Izq Sys';
            senalX = data.Tiempo;
            senalY = data.Rodilla_f;
        end
    
        if cbRodillaDerecha.Value && isfield(data,'RodillaDer_f')
            senalesActivas{end+1} = 'Rodilla Der Sys';
            senalX = data.Tiempo;
            senalY = data.RodillaDer_f;
        end
    
        if cbCadera.Value && isfield(data,'Cadera_f')
            senalesActivas{end+1} = 'Cadera Izq Sys';
            senalX = data.Tiempo;
            senalY = data.Cadera_f;
        end
    
        if cbCaderaDerecha.Value && isfield(data,'CaderaDer_f')
            senalesActivas{end+1} = 'Cadera Der Sys';
            senalX = data.Tiempo;
            senalY = data.CaderaDer_f;
        end
    
        if cbTobillo.Value && isfield(data,'Tobillo_f')
            senalesActivas{end+1} = 'Tobillo Izq Sys';
            senalX = data.Tiempo;
            senalY = data.Tobillo_f;
        end
    
        if cbTobilloDerecho.Value && isfield(data,'TobilloDer_f')
            senalesActivas{end+1} = 'Tobillo Der Sys';
            senalX = data.Tiempo;
            senalY = data.TobilloDer_f;
        end
    
        % ===== SISTEMA P.A.M - MIEMBRO SUPERIOR =====
        if cbHombroIzquierdo.Value && isfield(data,'HombroIzq_f')
            senalesActivas{end+1} = 'Hombro Izq Sys';
            senalX = data.Tiempo;
            senalY = data.HombroIzq_f;
        end
    
        if cbHombroDerecho.Value && isfield(data,'HombroDer_f')
            senalesActivas{end+1} = 'Hombro Der Sys';
            senalX = data.Tiempo;
            senalY = data.HombroDer_f;
        end
    
        if cbCodoIzquierdo.Value && isfield(data,'CodoIzq_f')
            senalesActivas{end+1} = 'Codo Izq Sys';
            senalX = data.Tiempo;
            senalY = data.CodoIzq_f;
        end
    
        if cbCodoDerecho.Value && isfield(data,'CodoDer_f')
            senalesActivas{end+1} = 'Codo Der Sys';
            senalX = data.Tiempo;
            senalY = data.CodoDer_f;
        end
    
        if cbMunecaIzquierda.Value && isfield(data,'MunecaIzq_f')
            senalesActivas{end+1} = 'Muñeca Izq Sys';
            senalX = data.Tiempo;
            senalY = data.MunecaIzq_f;
        end
    
        if cbMunecaDerecha.Value && isfield(data,'MunecaDer_f')
            senalesActivas{end+1} = 'Muñeca Der Sys';
            senalX = data.Tiempo;
            senalY = data.MunecaDer_f;
        end
    
        % ===== KINOVEA =====
        if cbRodillaK.Value && isfield(data,'kino_Rodilla')
            senalesActivas{end+1} = 'Rodilla K';
            senalX = data.kino_t;
            senalY = data.kino_Rodilla;
        end
    
        if cbCaderaK.Value && isfield(data,'kino_Cadera')
            senalesActivas{end+1} = 'Cadera K';
            senalX = data.kino_t;
            senalY = data.kino_Cadera;
        end
    
        if cbTobilloK.Value && isfield(data,'kino_Tobillo')
            senalesActivas{end+1} = 'Tobillo K';
            senalX = data.kino_t;
            senalY = data.kino_Tobillo;
        end
    
        if isempty(senalesActivas)
            return
        end
    
        if length(senalesActivas) > 1
            hText.String = 'Seleccione solo una señal';
            return
        end
    
        C = ax.CurrentPoint;
        x = C(1,1);
    
        [~, idx] = min(abs(senalX - x));
    
        x_real = senalX(idx);
        y_real = senalY(idx);
    
        hLine.Value = x_real;
    
        offset_x = 0.2;
        offset_y = 5;
    
        if x_real > mean(xlim(ax))
            offset_x = -0.5;
        end
    
        if y_real > mean(ylim(ax))
            offset_y = -5;
        end
    
        hText.Position = [x_real + offset_x, y_real + offset_y, 0];
    
        hText.String = sprintf('%s\nt=%.2f s\nθ=%.2f°', ...
            senalesActivas{1}, x_real, y_real);
    
    end

    %% ================= 10. SELECCIÓN DE CICLO =================

    function seleccionarCiclo()

        if ~isfield(data,'Rodilla_f')
            uialert(fig,'Filtra primero','Error')
            return
        end
    
        senalesActivas = {};
        senalY = [];
        senalX = [];
        tipoCiclo = '';
    
        % ===== SISTEMA P.A.M - MIEMBRO INFERIOR =====
        if cbRodilla.Value && isfield(data,'Rodilla_f')
            senalesActivas{end+1} = 'Rodilla Izq Sys';
            senalY = data.Rodilla_f;
            senalX = data.Tiempo;
            tipoCiclo = 'sistema';
        end
    
        if cbRodillaDerecha.Value && isfield(data,'RodillaDer_f')
            senalesActivas{end+1} = 'Rodilla Der Sys';
            senalY = data.RodillaDer_f;
            senalX = data.Tiempo;
            tipoCiclo = 'sistema';
        end
    
        if cbCadera.Value && isfield(data,'Cadera_f')
            senalesActivas{end+1} = 'Cadera Izq Sys';
            senalY = data.Cadera_f;
            senalX = data.Tiempo;
            tipoCiclo = 'sistema';
        end
    
        if cbCaderaDerecha.Value && isfield(data,'CaderaDer_f')
            senalesActivas{end+1} = 'Cadera Der Sys';
            senalY = data.CaderaDer_f;
            senalX = data.Tiempo;
            tipoCiclo = 'sistema';
        end
    
        if cbTobillo.Value && isfield(data,'Tobillo_f')
            senalesActivas{end+1} = 'Tobillo Izq Sys';
            senalY = data.Tobillo_f;
            senalX = data.Tiempo;
            tipoCiclo = 'sistema';
        end
    
        if cbTobilloDerecho.Value && isfield(data,'TobilloDer_f')
            senalesActivas{end+1} = 'Tobillo Der Sys';
            senalY = data.TobilloDer_f;
            senalX = data.Tiempo;
            tipoCiclo = 'sistema';
        end
    
        % ===== SISTEMA P.A.M - MIEMBRO SUPERIOR =====
        if cbHombroIzquierdo.Value && isfield(data,'HombroIzq_f')
            senalesActivas{end+1} = 'Hombro Izq Sys';
            senalY = data.HombroIzq_f;
            senalX = data.Tiempo;
            tipoCiclo = 'sistema';
        end
    
        if cbHombroDerecho.Value && isfield(data,'HombroDer_f')
            senalesActivas{end+1} = 'Hombro Der Sys';
            senalY = data.HombroDer_f;
            senalX = data.Tiempo;
            tipoCiclo = 'sistema';
        end
    
        if cbCodoIzquierdo.Value && isfield(data,'CodoIzq_f')
            senalesActivas{end+1} = 'Codo Izq Sys';
            senalY = data.CodoIzq_f;
            senalX = data.Tiempo;
            tipoCiclo = 'sistema';
        end
    
        if cbCodoDerecho.Value && isfield(data,'CodoDer_f')
            senalesActivas{end+1} = 'Codo Der Sys';
            senalY = data.CodoDer_f;
            senalX = data.Tiempo;
            tipoCiclo = 'sistema';
        end
    
        if cbMunecaIzquierda.Value && isfield(data,'MunecaIzq_f')
            senalesActivas{end+1} = 'Muñeca Izq Sys';
            senalY = data.MunecaIzq_f;
            senalX = data.Tiempo;
            tipoCiclo = 'sistema';
        end
    
        if cbMunecaDerecha.Value && isfield(data,'MunecaDer_f')
            senalesActivas{end+1} = 'Muñeca Der Sys';
            senalY = data.MunecaDer_f;
            senalX = data.Tiempo;
            tipoCiclo = 'sistema';
        end
    
        % ===== KINOVEA =====
        if cbRodillaK.Value && isfield(data,'kino_Rodilla')
            senalesActivas{end+1} = 'Rodilla K';
            senalY = data.kino_Rodilla;
            senalX = data.kino_t;
            tipoCiclo = 'kinovea';
        end
    
        if cbCaderaK.Value && isfield(data,'kino_Cadera')
            senalesActivas{end+1} = 'Cadera K';
            senalY = data.kino_Cadera;
            senalX = data.kino_t;
            tipoCiclo = 'kinovea';
        end
    
        if cbTobilloK.Value && isfield(data,'kino_Tobillo')
            senalesActivas{end+1} = 'Tobillo K';
            senalY = data.kino_Tobillo;
            senalX = data.kino_t;
            tipoCiclo = 'kinovea';
        end
    
        % ===== VALIDACIONES =====
        if isempty(senalesActivas)
            uialert(fig,'Debes visualizar una señal','Error')
            return
        end
    
        if length(senalesActivas) > 1
            uialert(fig,...
                'Solo se puede seleccionar el ciclo sobre una grafica a la vez',...
                'Advertencia')
            return
        end
    
        title(ax, ['Seleccionando ciclo: ', senalesActivas{1}])
        fig.Pointer = 'crosshair';
    
        delete(findall(ax,'Tag','puntoCiclo'))
    
        clicks = [];
    
        fig.WindowButtonDownFcn = @(~,~) click();
    
        uiwait(fig)
    
        if ~isvalid(fig)
            return
        end
    
        if length(clicks) < 2
            if isvalid(fig)
                uialert(fig,'Debes seleccionar 2 puntos','Error')
            end
            return
        end
    
        pos_ini = clicks(1);
        pos_fin = clicks(2);
    
        if pos_ini > pos_fin
            [pos_ini,pos_fin] = deal(pos_fin,pos_ini);
        end
    
        % ===== GUARDAR CICLO SEGÚN ORIGEN =====
        if strcmp(tipoCiclo,'sistema')
            data.sys_pos_ini = pos_ini;
            data.sys_pos_fin = pos_fin;
            data.sys_ciclo_nombre = senalesActivas{1};
            disp(['Ciclo del sistema seleccionado: ', senalesActivas{1}])
    
        elseif strcmp(tipoCiclo,'kinovea')
            data.kino_pos_ini = pos_ini;
            data.kino_pos_fin = pos_fin;
            data.kino_ciclo_nombre = senalesActivas{1};
            disp(['Ciclo de Kinovea seleccionado: ', senalesActivas{1}])
        end
    
        function click()
    
            C = ax.CurrentPoint;
            x = C(1,1);
    
            [~, idx] = min(abs(senalX - x));
    
            clicks = [clicks idx];
    
            hold(ax,'on')
    
            plot(ax, senalX(idx), senalY(idx), ...
                'ro','MarkerSize',8,'LineWidth',1.5,'Tag','puntoCiclo')
    
            hold(ax,'off')
    
            title(ax, ['Clicks: ', num2str(length(clicks)), '/2'])
    
            drawnow limitrate
    
            if length(clicks) == 2
                fig.WindowButtonDownFcn = [];
                fig.Pointer = 'arrow';
                uiresume(fig)
            end
        end
    end

    %% ================= 11. COMPARACIÓN =================

    function comparar()

        if ~isfield(data,'sys_pos_ini') || ~isfield(data,'kino_pos_ini')
            uialert(fig,...
                'Seleccione un ciclo del sistema y otro ciclo de Kinovea para poder comparar',...
                'Faltan ciclos')
            return
        end
    
        N = 101;
        data.ciclo_pct = linspace(0,100,N);
    
        if ~isfield(data,'kino_Rodilla')
            uialert(fig,'Carga primero los datos de Kinovea','Error')
            return
        end
    
        % ===== CICLOS SISTEMA: MIEMBRO INFERIOR =====
        sys_RodIzq = data.Rodilla_f(data.sys_pos_ini:data.sys_pos_fin);
        sys_RodDer = data.RodillaDer_f(data.sys_pos_ini:data.sys_pos_fin);
    
        sys_CadIzq = data.Cadera_f(data.sys_pos_ini:data.sys_pos_fin);
        sys_CadDer = data.CaderaDer_f(data.sys_pos_ini:data.sys_pos_fin);
    
        sys_TobIzq = data.Tobillo_f(data.sys_pos_ini:data.sys_pos_fin);
        sys_TobDer = data.TobilloDer_f(data.sys_pos_ini:data.sys_pos_fin);
    
        % ===== CICLOS SISTEMA: MIEMBRO SUPERIOR =====
        sys_HomIzq = data.HombroIzq_f(data.sys_pos_ini:data.sys_pos_fin);
        sys_HomDer = data.HombroDer_f(data.sys_pos_ini:data.sys_pos_fin);
    
        sys_CodoIzq = data.CodoIzq_f(data.sys_pos_ini:data.sys_pos_fin);
        sys_CodoDer = data.CodoDer_f(data.sys_pos_ini:data.sys_pos_fin);
    
        sys_MunIzq = data.MunecaIzq_f(data.sys_pos_ini:data.sys_pos_fin);
        sys_MunDer = data.MunecaDer_f(data.sys_pos_ini:data.sys_pos_fin);
    
        % ===== CICLOS KINOVEA =====
        kino_Rod = data.kino_Rodilla(data.kino_pos_ini:data.kino_pos_fin);
        kino_Cad = data.kino_Cadera(data.kino_pos_ini:data.kino_pos_fin);
        kino_Tob = data.kino_Tobillo(data.kino_pos_ini:data.kino_pos_fin);
    
        % ===== OFFSET SISTEMA =====
        sys_RodIzq = sys_RodIzq - sys_RodIzq(1);
        sys_RodDer = sys_RodDer - sys_RodDer(1);
    
        sys_CadIzq = sys_CadIzq + (30 - sys_CadIzq(1));
        sys_CadDer = sys_CadDer + (30 - sys_CadDer(1));
    
        sys_TobIzq = sys_TobIzq - sys_TobIzq(1);
        sys_TobDer = sys_TobDer - sys_TobDer(1);
    
        sys_HomIzq = sys_HomIzq - sys_HomIzq(1);
        sys_HomDer = sys_HomDer - sys_HomDer(1);
    
        sys_CodoIzq = sys_CodoIzq - sys_CodoIzq(1);
        sys_CodoDer = sys_CodoDer - sys_CodoDer(1);
    
        sys_MunIzq = sys_MunIzq - sys_MunIzq(1);
        sys_MunDer = sys_MunDer - sys_MunDer(1);
    
        % ===== OFFSET KINOVEA =====
        kino_Rod = kino_Rod - kino_Rod(1);
        kino_Cad = kino_Cad + (30 - kino_Cad(1));
        kino_Tob = kino_Tob - kino_Tob(1);
    
        % ===== NORMALIZAR SISTEMA A 0–100% =====
        data.comp_Rodilla_sys = normalizarCiclo(sys_RodIzq,N);
        data.comp_RodillaDer_sys = normalizarCiclo(sys_RodDer,N);
    
        data.comp_Cadera_sys = normalizarCiclo(sys_CadIzq,N);
        data.comp_CaderaDer_sys = normalizarCiclo(sys_CadDer,N);
    
        data.comp_Tobillo_sys = normalizarCiclo(sys_TobIzq,N);
        data.comp_TobilloDer_sys = normalizarCiclo(sys_TobDer,N);
    
        data.comp_HombroIzq_sys = normalizarCiclo(sys_HomIzq,N);
        data.comp_HombroDer_sys = normalizarCiclo(sys_HomDer,N);
    
        data.comp_CodoIzq_sys = normalizarCiclo(sys_CodoIzq,N);
        data.comp_CodoDer_sys = normalizarCiclo(sys_CodoDer,N);
    
        data.comp_MunecaIzq_sys = normalizarCiclo(sys_MunIzq,N);
        data.comp_MunecaDer_sys = normalizarCiclo(sys_MunDer,N);
    
        % ===== NORMALIZAR KINOVEA A 0–100% =====
        data.comp_Rodilla_kino = normalizarCiclo(kino_Rod,N);
        data.comp_Cadera_kino  = normalizarCiclo(kino_Cad,N);
        data.comp_Tobillo_kino = normalizarCiclo(kino_Tob,N);
    
        data.modoComparacion = true;
    
        fig.WindowButtonMotionFcn = [];
        delete(findall(ax,'Tag','cursorLine'))
        delete(findall(ax,'Tag','cursorText'))
    
        actualizarGraficaComparacion()
    
    end
%% ================= 12. Funcion Auxiliar =================

    function ciclo_norm = normalizarCiclo(ciclo,N)

        if length(ciclo) < 2
            ciclo_norm = nan(1,N);
            return
        end
    
        x_original = linspace(0,100,length(ciclo));
        x_nuevo = linspace(0,100,N);
        ciclo_norm = interp1(x_original, ciclo, x_nuevo, 'linear');
    
    end

%% ================= 13. Funcion Graficar Comparacion =================

    function actualizarGraficaComparacion()

        if ~isfield(data,'modoComparacion')
            return
        end
    
        cla(ax)
        hold(ax,'on')
    
        labels = {};
    
        % ===== SISTEMA P.A.M - MIEMBRO INFERIOR =====
        if cbRodilla.Value && isfield(data,'comp_Rodilla_sys')
            plot(ax,data.ciclo_pct,data.comp_Rodilla_sys,'b','LineWidth',1.5)
            labels{end+1} = 'Rodilla Izq Sys';
        end
    
        if cbRodillaDerecha.Value && isfield(data,'comp_RodillaDer_sys')
            plot(ax,data.ciclo_pct,data.comp_RodillaDer_sys,'b--','LineWidth',1.5)
            labels{end+1} = 'Rodilla Der Sys';
        end
    
        if cbCadera.Value && isfield(data,'comp_Cadera_sys')
            plot(ax,data.ciclo_pct,data.comp_Cadera_sys,'r','LineWidth',1.5)
            labels{end+1} = 'Cadera Izq Sys';
        end
    
        if cbCaderaDerecha.Value && isfield(data,'comp_CaderaDer_sys')
            plot(ax,data.ciclo_pct,data.comp_CaderaDer_sys,'r--','LineWidth',1.5)
            labels{end+1} = 'Cadera Der Sys';
        end
    
        if cbTobillo.Value && isfield(data,'comp_Tobillo_sys')
            plot(ax,data.ciclo_pct,data.comp_Tobillo_sys,'g','LineWidth',1.5)
            labels{end+1} = 'Tobillo Izq Sys';
        end
    
        if cbTobilloDerecho.Value && isfield(data,'comp_TobilloDer_sys')
            plot(ax,data.ciclo_pct,data.comp_TobilloDer_sys,'g--','LineWidth',1.5)
            labels{end+1} = 'Tobillo Der Sys';
        end
    
        % ===== SISTEMA P.A.M - MIEMBRO SUPERIOR =====
        if cbHombroIzquierdo.Value && isfield(data,'comp_HombroIzq_sys')
            plot(ax,data.ciclo_pct,data.comp_HombroIzq_sys,'m','LineWidth',1.5)
            labels{end+1} = 'Hombro Izq Sys';
        end
    
        if cbHombroDerecho.Value && isfield(data,'comp_HombroDer_sys')
            plot(ax,data.ciclo_pct,data.comp_HombroDer_sys,'m--','LineWidth',1.5)
            labels{end+1} = 'Hombro Der Sys';
        end
    
        if cbCodoIzquierdo.Value && isfield(data,'comp_CodoIzq_sys')
            plot(ax,data.ciclo_pct,data.comp_CodoIzq_sys,'c','LineWidth',1.5)
            labels{end+1} = 'Codo Izq Sys';
        end
    
        if cbCodoDerecho.Value && isfield(data,'comp_CodoDer_sys')
            plot(ax,data.ciclo_pct,data.comp_CodoDer_sys,'c--','LineWidth',1.5)
            labels{end+1} = 'Codo Der Sys';
        end
    
        if cbMunecaIzquierda.Value && isfield(data,'comp_MunecaIzq_sys')
            plot(ax,data.ciclo_pct,data.comp_MunecaIzq_sys,'k','LineWidth',1.5)
            labels{end+1} = 'Muñeca Izq Sys';
        end
    
        if cbMunecaDerecha.Value && isfield(data,'comp_MunecaDer_sys')
            plot(ax,data.ciclo_pct,data.comp_MunecaDer_sys,'k--','LineWidth',1.5)
            labels{end+1} = 'Muñeca Der Sys';
        end
    
        % ===== KINOVEA =====
        if cbRodillaK.Value && isfield(data,'comp_Rodilla_kino')
            plot(ax,data.ciclo_pct,data.comp_Rodilla_kino,'b:','LineWidth',1.8)
            labels{end+1} = 'Rodilla K';
        end
    
        if cbCaderaK.Value && isfield(data,'comp_Cadera_kino')
            plot(ax,data.ciclo_pct,data.comp_Cadera_kino,'r:','LineWidth',1.8)
            labels{end+1} = 'Cadera K';
        end
    
        if cbTobilloK.Value && isfield(data,'comp_Tobillo_kino')
            plot(ax,data.ciclo_pct,data.comp_Tobillo_kino,'g:','LineWidth',1.8)
            labels{end+1} = 'Tobillo K';
        end
    
        hold(ax,'off')
    
        if ~isempty(labels)
            legend(ax,labels)
        else
            legend(ax,'off')
        end
    
        title(ax,'Comparación por porcentaje del ciclo de marcha')
        xlabel(ax,'% ciclo de marcha')
        ylabel(ax,'Ángulo (°)')
        xlim(ax,[0 100])
        grid(ax,'on')
    
        ax.Toolbar.Visible = 'on';
    
    end

%% ================= 14. Funcion Actualizar vista =================

    function actualizarVista()
    
        if isfield(data,'modoComparacion') && data.modoComparacion
            actualizarGraficaComparacion()
        else
            actualizarGrafica()
        end
    
    end

end