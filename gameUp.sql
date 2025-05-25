DELIMITER $$

DROP PROCEDURE IF EXISTS simular_connection_capturing_periodo$$

CREATE PROCEDURE simular_connection_capturing_periodo(IN inicio DATETIME, IN fim DATETIME)
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
    DECLARE crescimento FLOAT DEFAULT 1.0;

    WHILE t < fim DO
        SET hora = HOUR(t);
        SET dia = WEEKDAY(t);


        SET crescimento = 1.0 + DATEDIFF(t, inicio) / 90.0; -- cresce até dobrar em 90 dias

        SET jogadores = FLOOR((1 + RAND()*3) * crescimento);

        IF hora BETWEEN 18 AND 23 THEN
            SET jogadores = jogadores + FLOOR(RAND() * 6000 * crescimento);
        END IF;

        IF dia IN (5, 6) THEN
            SET jogadores = jogadores + FLOOR(RAND() * 3000 * crescimento);
        END IF;

        SET i = 0;
        WHILE i < jogadores DO
            SET ip = CONCAT(
                FLOOR(100 + RAND()*100), '.',
                FLOOR(RAND()*256), '.',
                FLOOR(RAND()*256), '.',
                FLOOR(1 + RAND()*254)
            );

            -- Localização aleatória (4 exemplos)
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

            -- Inserção com date_time
            INSERT INTO connection_capturing (
                ip_player, longitude, latitude, country, continent_code, fk_server, date_time
            )
            VALUES (
                ip, lon, lat, pais, continente, 1, t
            );

            SET i = i + 1;
        END WHILE;

        SET t = t + INTERVAL 1 DAY;
    END WHILE;
END$$

DELIMITER ;


CALL simular_connection_capturing_periodo(
    '2025-02-01 00:00:00',
    '2025-05-31 00:00:00'
);


