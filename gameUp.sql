
DELIMITER $$

DROP PROCEDURE IF EXISTS simular_connection_capturing_avancado$$

CREATE PROCEDURE simular_connection_capturing_avancado(IN inicio DATETIME, IN fim DATETIME)
BEGIN
    DECLARE t DATETIME DEFAULT inicio;
    DECLARE hora INT;
    DECLARE dia INT;
    DECLARE jogadores INT;
    DECLARE i INT;
    DECLARE servidor_atual INT;
    DECLARE ip VARCHAR(15);
    DECLARE lat DECIMAL(9,6);
    DECLARE lon DECIMAL(9,6);
    DECLARE pais VARCHAR(45);
    DECLARE continente CHAR(2);
    DECLARE crescimento FLOAT DEFAULT 1.0;
    DECLARE tem_alerta INT DEFAULT 0;
    DECLARE reducao_por_alerta FLOAT DEFAULT 1.0;
    DECLARE continente_escolhido INT;
    DECLARE pais_escolhido INT;
    
    -- Arrays de países e coordenadas por continente
    DECLARE brasil_lat DECIMAL(9,6);
    DECLARE brasil_lon DECIMAL(9,6);
    
    WHILE t < fim DO
        SET hora = HOUR(t);
        SET dia = WEEKDAY(t);
        
        -- Crescimento gradual ao longo do tempo
        SET crescimento = 1.0 + DATEDIFF(t, inicio) / 90.0;
        
        -- Loop através dos servidores (1 a 6)
        SET servidor_atual = 1;
        WHILE servidor_atual <= 6 DO
            
            -- Verificar se há alertas ativos para este servidor no horário atual
            SELECT COUNT(*) INTO tem_alerta 
            FROM alert a 
            JOIN metric m ON a.fk_Metric = m.id_metric 
            JOIN component c ON m.fk_component = c.id_component 
            WHERE c.fk_server = servidor_atual 
            AND a.dateAlert <= t 
            AND a.dateAlert >= DATE_SUB(t, INTERVAL 2 HOUR)
            AND a.status IN ('aberto', 'acompanhamento');
            
            -- Se há alerta, reduzir drasticamente os jogadores
            IF tem_alerta > 0 THEN
                SET reducao_por_alerta = 0.1 + RAND() * 0.3; -- Redução de 70-90%
            ELSE
                SET reducao_por_alerta = 1.0;
            END IF;
            
            -- Calcular número base de jogadores
            SET jogadores = FLOOR((50 + RAND() * 200) * crescimento * reducao_por_alerta);
            
            -- Horário de pico (18h às 23h)
            IF hora BETWEEN 18 AND 23 THEN
                SET jogadores = jogadores + FLOOR(RAND() * 3000 * crescimento * reducao_por_alerta);
            END IF;
            
            -- Final de semana (Sábado=5, Domingo=6)
            IF dia IN (5, 6) THEN
                SET jogadores = jogadores + FLOOR(RAND() * 2000 * crescimento * reducao_por_alerta);
            END IF;
            
            -- Ajuste por servidor (alguns são mais populares)
            CASE servidor_atual
                WHEN 1 THEN SET jogadores = jogadores * 1.5; -- Far Cry 5 - popular
                WHEN 2 THEN SET jogadores = jogadores * 1.3; -- Assassin's Creed - popular
                WHEN 6 THEN SET jogadores = jogadores * 1.4; -- Rainbow Six - muito popular
                ELSE SET jogadores = jogadores * (0.8 + RAND() * 0.4);
            END CASE;
            
            SET jogadores = FLOOR(jogadores);
            
            -- Inserir conexões para este servidor
            SET i = 0;
            WHILE i < jogadores DO
                -- Gerar IP aleatório
                SET ip = CONCAT(
                    FLOOR(1 + RAND() * 223), '.',  -- Evitar IPs inválidos
                    FLOOR(RAND() * 256), '.',
                    FLOOR(RAND() * 256), '.',
                    FLOOR(1 + RAND() * 254)
                );
                
                -- Escolher continente (incluindo África e Oceania)
                SET continente_escolhido = FLOOR(RAND() * 6);
                
                CASE continente_escolhido
                    -- América do Sul
                    WHEN 0 THEN
                        SET pais_escolhido = FLOOR(RAND() * 3);
                        CASE pais_escolhido
                            WHEN 0 THEN 
                                SET pais = 'Brasil'; 
                                SET lat = -30.0 + RAND() * 35.0; -- -30 a 5
                                SET lon = -74.0 + RAND() * 40.0; -- -74 a -34
                                SET continente = 'SA';
                            WHEN 1 THEN 
                                SET pais = 'Argentina'; 
                                SET lat = -55.0 + RAND() * 33.0;
                                SET lon = -73.0 + RAND() * 20.0;
                                SET continente = 'SA';
                            WHEN 2 THEN 
                                SET pais = 'Chile'; 
                                SET lat = -56.0 + RAND() * 39.0;
                                SET lon = -76.0 + RAND() * 8.0;
                                SET continente = 'SA';
                        END CASE;
                    
                    -- América do Norte
                    WHEN 1 THEN
                        SET pais_escolhido = FLOOR(RAND() * 3);
                        CASE pais_escolhido
                            WHEN 0 THEN 
                                SET pais = 'Estados Unidos'; 
                                SET lat = 25.0 + RAND() * 24.0; -- 25 a 49
                                SET lon = -125.0 + RAND() * 58.0; -- -125 a -67
                                SET continente = 'NA';
                            WHEN 1 THEN 
                                SET pais = 'Canadá'; 
                                SET lat = 42.0 + RAND() * 41.0;
                                SET lon = -141.0 + RAND() * 89.0;
                                SET continente = 'NA';
                            WHEN 2 THEN 
                                SET pais = 'México'; 
                                SET lat = 14.5 + RAND() * 18.0;
                                SET lon = -117.0 + RAND() * 31.0;
                                SET continente = 'NA';
                        END CASE;
                    
                    -- Europa
                    WHEN 2 THEN
                        SET pais_escolhido = FLOOR(RAND() * 4);
                        CASE pais_escolhido
                            WHEN 0 THEN 
                                SET pais = 'Alemanha'; 
                                SET lat = 47.3 + RAND() * 7.9;
                                SET lon = 5.9 + RAND() * 10.2;
                                SET continente = 'EU';
                            WHEN 1 THEN 
                                SET pais = 'França'; 
                                SET lat = 41.3 + RAND() * 10.0;
                                SET lon = -5.1 + RAND() * 13.7;
                                SET continente = 'EU';
                            WHEN 2 THEN 
                                SET pais = 'Reino Unido'; 
                                SET lat = 49.9 + RAND() * 10.8;
                                SET lon = -8.2 + RAND() * 9.9;
                                SET continente = 'EU';
                            WHEN 3 THEN 
                                SET pais = 'Espanha'; 
                                SET lat = 35.2 + RAND() * 8.5;
                                SET lon = -9.3 + RAND() * 13.8;
                                SET continente = 'EU';
                        END CASE;
                    
                    -- Ásia
                    WHEN 3 THEN
                        SET pais_escolhido = FLOOR(RAND() * 4);
                        CASE pais_escolhido
                            WHEN 0 THEN 
                                SET pais = 'Japão'; 
                                SET lat = 24.4 + RAND() * 21.5;
                                SET lon = 123.0 + RAND() * 22.9;
                                SET continente = 'AS';
                            WHEN 1 THEN 
                                SET pais = 'China'; 
                                SET lat = 18.2 + RAND() * 35.4;
                                SET lon = 73.7 + RAND() * 60.9;
                                SET continente = 'AS';
                            WHEN 2 THEN 
                                SET pais = 'Coreia do Sul'; 
                                SET lat = 33.1 + RAND() * 5.2;
                                SET lon = 124.6 + RAND() * 5.7;
                                SET continente = 'AS';
                            WHEN 3 THEN 
                                SET pais = 'Índia'; 
                                SET lat = 6.8 + RAND() * 30.5;
                                SET lon = 68.2 + RAND() * 29.4;
                                SET continente = 'AS';
                        END CASE;
                    
                    -- África
                    WHEN 4 THEN
                        SET pais_escolhido = FLOOR(RAND() * 3);
                        CASE pais_escolhido
                            WHEN 0 THEN 
                                SET pais = 'África do Sul'; 
                                SET lat = -35.0 + RAND() * 13.0;
                                SET lon = 16.5 + RAND() * 16.0;
                                SET continente = 'AF';
                            WHEN 1 THEN 
                                SET pais = 'Nigéria'; 
                                SET lat = 4.3 + RAND() * 9.6;
                                SET lon = 2.7 + RAND() * 11.8;
                                SET continente = 'AF';
                            WHEN 2 THEN 
                                SET pais = 'Egito'; 
                                SET lat = 22.0 + RAND() * 9.5;
                                SET lon = 25.0 + RAND() * 10.0;
                                SET continente = 'AF';
                        END CASE;
                    
                    -- Oceania
                    WHEN 5 THEN
                        SET pais_escolhido = FLOOR(RAND() * 2);
                        CASE pais_escolhido
                            WHEN 0 THEN 
                                SET pais = 'Austrália'; 
                                SET lat = -44.0 + RAND() * 34.0;
                                SET lon = 113.0 + RAND() * 40.0;
                                SET continente = 'OC';
                            WHEN 1 THEN 
                                SET pais = 'Nova Zelândia'; 
                                SET lat = -47.3 + RAND() * 12.8;
                                SET lon = 166.4 + RAND() * 12.4;
                                SET continente = 'OC';
                        END CASE;
                END CASE;
                
                -- Inserir conexão
                INSERT INTO connection_capturing (
                    ip_player, longitude, latitude, country, continent_code, fk_server, date_time
                )
                VALUES (
                    ip, lon, lat, pais, continente, servidor_atual, t
                );
                
                SET i = i + 1;
            END WHILE;
            
            SET servidor_atual = servidor_atual + 1;
        END WHILE;
        
        SET t = t + INTERVAL 1 DAY;
    END WHILE;
END$$

DELIMITER ;

-- Executar a simulação
CALL simular_connection_capturing_avancado(
    '2025-02-01 00:00:00',
    '2025-05-31 00:00:00'
);


DROP PROCEDURE simular_connection_capturing_avancado;
