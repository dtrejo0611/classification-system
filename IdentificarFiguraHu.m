function [nombreFigura, porcentaje] = IdentificarFiguraHu(imagen_binaria, rutaBD)
    %Obtengo los momentos invariantes de la fotografia
    momentosImagen = CalcularMomentosHu(imagen_binaria);  % 1x7
    
    %Cargo la base de datos
    archivos = dir(fullfile(rutaBD, '*.mat'));
    mejorDist = inf;
    mejorNombre = '';
    
    %Analizo archivo por archivo
    for i = 1:length(archivos)
        archivo = fullfile(rutaBD, archivos(i).name);
        datos = load(archivo);
        
        % Encontrar la matriz de momentos (7xN)
        nombresVars = fieldnames(datos);
        momentosBD = datos.(nombresVars{1})';

        if size(momentosBD, 2) ~= 7
            continue;  % Saltar si no tiene el formato correcto
        end

        % Comparar con cada fila (objeto registrado)
        for j = 1:size(momentosBD, 1)
            dist = sum(abs(momentosBD(j, :) - momentosImagen));
            if dist < mejorDist
                mejorDist = dist;
                mejorNombre = erase(archivos(i).name, '.mat');  % nombre sin extensión
            end
        end
    end

    % Normalizamos la distancia a una escala tipo porcentaje inversa
    porcentaje = max(0, 100 - mejorDist * 1000); 
    porcentaje = round(porcentaje, 2);
    nombreFigura = mejorNombre;
end