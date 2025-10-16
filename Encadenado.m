function [dist, cx, cy] = Encadenado(f2)
    % Mostrar la imagen
    %imshow(f2)
    
    % Tamaño de la imagen
    [filas, columnas] = size(f2);
    x = 1:columnas;
    fx = sum(f2, 1);
    y = 1:filas;
    fy = sum(f2, 2)';
    
    % Centroide aproximado
    cx = round(sum((x .* fx) / sum(fx)));
    cy = round(sum((y .* fy) / sum(fy)));
    
    % Buscar el primer píxel activo
    encontrado = false;
    for i = 1:filas
        for j = 1:columnas
            if f2(i, j) == 1
                encontrado = true;
                break;
            end
        end
        if encontrado
            break;
        end
    end
    
    % Matriz de direcciones
    dir = [3 2 1; 4 0 8; 5 6 7];
    
    % Punto inicial
    inicio = [i, j];
    n = 0;
    dist = [];
    
    % Bucle para recorrer el contorno
    while true
        % Ventana local
        if i <= 1 || i >= filas || j <= 1 || j >= columnas
            break;
        end
        V = f2(i-1:i+1, j-1:j+1);
        
        % Marcar el píxel actual como procesado
        f2(i, j) = 0;
        
        % Guardar distancia al centroide
        n = n + 1;
        dist(n) = sqrt((cx - j)^2 + (cy - i)^2);
        
        % Dirección del siguiente píxel
        d = max(max(dir .* V));
        switch d
            case 1
                i = i - 1;
                j = j + 1;
            case 2
                i = i - 1;
            case 3
                i = i - 1;
                j = j - 1;
            case 4
                j = j - 1;
            case 5
                i = i + 1;
                j = j - 1;
            case 6
                i = i + 1;
            case 7
                i = i + 1;
                j = j + 1;
            case 8
                j = j + 1;
            otherwise
                break;
        end
        
        % Si regresamos al punto inicial, detener
        if i == inicio(1) && j == inicio(2)
            break;
        end
    end
end
