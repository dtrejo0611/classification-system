clc;
clear;
close all;

% Ruta de base de datos de firmas
RUTA_FIRMAS = "BDF\";
% Ruta de base de datos de momentos Hu
RUTA_HU = "BDHU\";
%Seleccion de camara
cam = webcam(2);

% Umbral binarización
umbral = 130;
%Tamaño del area de clasificacion
recorteAncho = 370;
recorteAlto  = 300;

% Comunicación con Arduino
arduinoPort = 'COM4';
a = serialport(arduinoPort, 9600);

% Inicialización Excel
inicioexcel = 6;
archivoExcel = 'informe.xlsx';
if ~isfile(archivoExcel)
    nombre = "Trejo Perez David Alejandro";
    writematrix(nombre, archivoExcel, 'Sheet', 1, 'Range', 'A1');
    encabezados = ["No. Objeto","Fecha", "Hora", "Lote", "Tipo Firma", "Tipo Hu", "Color", "Estado", "Confiabilidad Firma", "Confiabilidad Hu"];
    writematrix(encabezados, archivoExcel, 'Sheet', 1, 'Range', 'A5');
end

%Inicializacion del conteo de productos
productosAnalizados = 0;

while true
    % Captura obtencion del centro de la imagen
    IMA = snapshot(cam);
    [alto, ancho, ~] = size(IMA);
    x = round(ancho/2 - recorteAncho/2);
    y = round(alto/2  - recorteAlto/2);

    % Definir rectángulo de recorte [x, y, ancho, alto]
    rect = [x+20, y, recorteAncho, recorteAlto];        % Coordenadas de recorte
    IMA = imcrop(IMA, rect);  
    %Binarizacion
    imagen_gris = rgb2gray(IMA);
    imagen_binaria = imagen_gris < umbral;

    % Calcular centroide
    [filas, columnas] = size(imagen_binaria);
    x = 1:columnas;
    fx = sum(imagen_binaria, 1);
    y = 1:filas;
    fy = sum(imagen_binaria, 2)';
    cx = round(sum((x .* fx) / sum(fx)));
    cy = round(sum((y .* fy) / sum(fy)));
    
    % Convertir imagen a HSV
    imagenHSV = rgb2hsv(IMA);
    
    % Verificar que el centroide esté dentro de límites válidos
    if cx > 1 && cy > 1 && cx < size(IMA,2)-1 && cy < size(IMA,1)-1
        % Tomar región 3x3 alrededor del centroide y promediar
        ventana = imagenHSV(cy-1:cy+1, cx-1:cx+1, :);
        hsvProm = mean(reshape(ventana, [], 3), 1);
        H = hsvProm(1);
        S = hsvProm(2);
        V = hsvProm(3);
    else
        H = 0; S = 0; V = 0;
    end
    
    % Clasificación de color
    if V < 0.2
        colorNombre = "Negro";
    elseif H < 0.05 || H > 0.95
        colorNombre = "Rojo";
    elseif H >= 0.25 && H < 0.45
        colorNombre = "Verde";
    elseif H >= 0.45 && H < 0.55
        colorNombre = "Cian";
    elseif H >= 0.55 && H < 0.85
        colorNombre = "Azul";
    else
        colorNombre = "Otro";
    end

    
    %Llamada a la funcion para identificar que figura es mediante momentos
    %invariantes
    [nombreHu, porcentajeHu] = IdentificarFiguraHu(imagen_binaria, RUTA_HU);
    
    dhu = 0;

    switch nombreHu
        case "Circulo"
            dhu = 1;
        case "Cuadrado"
            dhu = 2;
        case "Rectangulo"
            dhu = 3;
    end

    % Obtencion de los bordes de la imagen
    IMAbordes = edge(double(imagen_binaria), 'Canny', [0.1 0.9], 1);
    IMAbordes = bwmorph(IMAbordes, "thin", inf); %Funcion para adelgazar los bordes
    %Se dibuja los bordes del objeto
    for i=1:filas
        for j=1:columnas
            if IMAbordes(i,j) == 1
                IMA(i,j,1) = 0;
                IMA(i,j,2) = 255;
                IMA(i,j,3) = 0;
            end
        end
    end
    %Se obtiene la firma y se compara con la base de datos
    firma = Encadenado(IMAbordes);
    [nombreFirma, porcentajeFirma] = Firmado(firma, RUTA_FIRMAS, dhu);

    % Validación de forma
    if porcentajeHu > 40
        productosAnalizados = productosAnalizados + 1;
        
        estado = "Bueno";
        
        %Se define el estado del objeto por la confiabilidad de la firma
        switch nombreHu
            case "Circulo"
                if porcentajeFirma < 0
                    estado = "Malo";
                end
            case "Cuadrado"
                if porcentajeFirma < 40
                    estado = "Malo";
                end
        end

        %Enviar estado a Arduino
        if estado == "Bueno"
            writeline(a, "1");
        else
            writeline(a, "2");
        end
        %Se muestra el resultado del analisis
        texto = sprintf("Producto: %s\nEstado del objeto: %s\nColor: %s", nombreFirma, estado, colorNombre);
        IMA = insertText(IMA, [10, 10], texto, 'FontSize', 16, 'BoxColor', 'yellow');
        imshow(IMA); title('Resultado');

        % Guardar en Excel
        inicioexcel = inicioexcel + 1;
        fila = strcat("A", num2str(inicioexcel));
        fecha = datestr(now, 'dd-mm-yyyy');
        hora = datestr(now, 'HH:MM:SS');
        loteNumero = ceil(productosAnalizados / 5);
        lote = sprintf("Lote %03d", loteNumero);
        filaDatos = {productosAnalizados, fecha, hora, lote, nombreFirma, nombreHu, colorNombre, estado, porcentajeFirma, porcentajeHu};
        writecell(filaDatos, archivoExcel, 'Sheet', 1, 'Range', fila);

        pause(10);
    elseif nombreFirma == "Rectangulo" %El rectangulo roto es un caso especial para hu
        estado = "Malo";
        writeline(a, "2");
        inicioexcel = inicioexcel + 1;
        fila = strcat("A", num2str(inicioexcel));
        fecha = datestr(now, 'dd-mm-yyyy');
        hora = datestr(now, 'HH:MM:SS');
        loteNumero = ceil(productosAnalizados / 5);
        lote = sprintf("Lote %03d", loteNumero);
        filaDatos = {productosAnalizados, fecha, hora, lote, nombreFirma, nombreHu, colorNombre, estado, porcentajeFirma, porcentajeHu};
        writecell(filaDatos, archivoExcel, 'Sheet', 1, 'Range', fila);
        texto = sprintf("Producto: %s \nEstado del objeto: %s\nColor: %s", nombreFirma, estado, colorNombre);
        IMA = insertText(IMA, [10, 10], texto, 'FontSize', 16, 'BoxColor', 'yellow');
        imshow(IMA); title('Resultado con texto');
        pause(10);
    else
        % Verificar si hay más de un objeto en la imagen
        etiquetas = bwlabel(imagen_binaria);
        numObjetos = max(etiquetas(:));
        
        if numObjetos > 1
            disp(['Se detectaron múltiples objetos: ', num2str(numObjetos)]);
        else
            disp('Objeto no reconocido o no encontrado');
        end

        pause(5);
    end
end 
