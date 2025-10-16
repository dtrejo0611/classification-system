function [ResRes, ResResnum] = Firmado(firma, RUTARaiz, dhu)
    resultados = [];
    etiquetas = [];
    
    elementos = dir(RUTARaiz);
    esCarpeta = [elementos.isdir] & ~ismember({elementos.name}, {'.', '..'});
    carpetas = {elementos(esCarpeta).name};
    
    %Se carga la carpeta con el nombre que se obtuvo en momentos
    %invariantes
    switch dhu
        case 1
            carpeta_actual = carpetas{1};
        case 2
            carpeta_actual = carpetas{2};
        case 3
            carpeta_actual = carpetas{3};
        otherwise
        ResRes = "Valor dhu no válido";
        ResResnum = 0;
        return;  % salir de la función si el valor no es válido
    end
            
    %Se carga la ruta de la carpeta a analizar
    ruta_carpeta = fullfile(RUTARaiz, carpeta_actual);
    archivos_mat = dir(fullfile(ruta_carpeta, '*.mat'));
        
    for j = 1:length(archivos_mat)
        archivo = fullfile(ruta_carpeta, archivos_mat(j).name);
        datos = load(archivo);
        
        if isfield(datos, 'dis')
            firma_bd = datos.dis;
        elseif isfield(datos, 'firma')
            firma_bd = datos.firma;
        else
            continue;
        end
        
        % Interpolación si las longitudes difieren
        len1 = length(firma);
        len2 = length(firma_bd);
        
        %Hacer el analisis solo si la firma tiene un tamaño optimo
        if len1 > 1 && len2 > 1
            if len1 > len2
                x_old = linspace(1, len1, len2);
                x_new = 1:len1;
                firma_bd_interp = interp1(x_old, firma_bd, x_new, 'linear');
                r = corrcoef(firma, firma_bd_interp);
            else
                x_old = linspace(1, len2, len1);
                x_new = 1:len2;
                firma_interp = interp1(x_old, firma, x_new, 'linear');
                r = corrcoef(firma_interp, firma_bd);
            end
            
            correlacion = r(1,2);
            resultados(end+1) = correlacion;
            etiquetas{end+1} = carpeta_actual;
        end
    end

    if isempty(resultados)
        ResRes = "No coincidencias";
        ResResnum = 0;
    else
        [max_val, idx_max] = max(resultados);
        ResRes = etiquetas{idx_max};
        ResResnum = round(max_val * 100, 2);  % como porcentaje
    end
end
