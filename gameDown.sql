DELIMITER $$

DROP PROCEDURE IF EXISTS simular_connection_capturing_periodo_queda$$

CREATE PROCEDURE simular_connection_capturing_periodo_queda(IN inicio DATETIME, IN fim DATETIME)
BEGIN
    DECLARE t DATETIME DEFAULT inicio;
    DECLARE hora INT;
    DECLARE dia INT;
    DECLARE jogadores INT;
    DECLARE i INT;
    DECLARE ip VARCHAR(15);
    DECLARE lat DECIMAL(9,6);
    DECLARE lon DECIMAL(9,6);
    DECLARE pais VARCHAR(45);
    DECLARE continente CHAR(2);
    DECLARE decrescimo FLOAT DEFAULT 1.0;

    WHILE t < fim DO
        SET hora = HOUR(t);
        SET dia = WEEKDAY(t);

        -- Decrescimento da comunidade ao longo do tempo (queda de 40%)
        SET decrescimo = 1.0 - (DATEDIFF(t, inicio) / 90.0) * 0.4;
        IF decrescimo < 0.6 THEN
            SET decrescimo = 0.6; -- mínimo de 60% da base original
        END IF;

        -- Base de jogadores
        SET jogadores = FLOOR((4 + RAND()*4) * decrescimo);

        -- Pico entre 18h e 23h
        IF hora BETWEEN 18 AND 23 THEN
            SET jogadores = jogadores + FLOOR(RAND() * 6 * decrescimo);
        END IF;

        -- Fim de semana (sábado ou domingo)
        IF dia IN (5, 6) THEN
            SET jogadores = jogadores + FLOOR(RAND() * 4 * decrescimo);
        END IF;

        SET i = 0;
        WHILE i < jogadores DO
            -- IP simulando jogadores recorrentes
            SET ip = CONCAT(
                FLOOR(100 + RAND()*100), '.',
                FLOOR(RAND()*256), '.',
                FLOOR(RAND()*256), '.',
                FLOOR(1 + RAND()*254)
            );

            -- Localização aleatória
            CASE FLOOR(RAND()*4)
                WHEN 0 THEN
                    SET pais = 'Brasil'; SET lat = -14.2350 + (RAND()*5); SET lon = -51.9253 + (RAND()*5); SET continente = 'SA';
                WHEN 1 THEN
                    SET pais = 'Estados Unidos'; SET lat = 37.0902 + (RAND()*5); SET lon = -95.7129 + (RAND()*5); SET continente = 'NA';
                WHEN 2 THEN
                    SET pais = 'Alemanha'; SET lat = 51.1657 + (RAND()*2); SET lon = 10.4515 + (RAND()*2); SET continente = 'EU';
                WHEN 3 THEN
                    SET pais = 'Japão'; SET lat = 36.2048 + (RAND()*2); SET lon = 138.2529 + (RAND()*2); SET continente = 'AS';
            END CASE;

            -- Inserção (agora com o campo date_time)
            INSERT INTO connection_capturing (
                ip_player, longitude, latitude, country, continent_code, fk_server, date_time
            )
            VALUES (
                ip, lon, lat, pais, continente, 2, t
            );

            SET i = i + 1;
        END WHILE;

        -- Avança 15 minutos
        SET t = t + INTERVAL 15 MINUTE;
    END WHILE;
END$$

DELIMITER ;

-- Execução
CALL simular_connection_capturing_periodo_queda(
    '2025-02-01 00:00:00',
    '2025-05-31 00:00:00'
);
