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
    DECLARE dias_passados INT;
    DECLARE fator_tempo FLOAT DEFAULT 1.0;
    DECLARE multiplicador_jogo FLOAT DEFAULT 1.0;
    
    WHILE t < fim DO
        SET hora = HOUR(t);
        SET dia = WEEKDAY(t);
        SET dias_passados = DATEDIFF(t, inicio);
        
        -- Crescimento gradual ao longo do tempo (base)
        SET crescimento = 1.0 + dias_passados / 90.0;
        
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
            
            -- Comportamentos específicos por jogo baseado no tempo
            CASE servidor_atual
                -- Far Cry 5 (Servidor 1) - Estável, crescimento moderado
                WHEN 1 THEN 
                    SET fator_tempo = 1.0;
                    SET multiplicador_jogo = 1.2;
                    SET jogadores = FLOOR((80 + RAND() * 150) * crescimento * fator_tempo * multiplicador_jogo * reducao_por_alerta);
                
                -- Assassin's Creed (Servidor 2) - Bom índice mas estável, menor que Rainbow
                WHEN 2 THEN 
                    SET fator_tempo = 1.0 + (SIN(dias_passados / 30.0) * 0.1); -- Variação sutil
                    SET multiplicador_jogo = 1.8; -- Bom índice mas menor que Rainbow
                    SET jogadores = FLOOR((120 + RAND() * 180) * crescimento * fator_tempo * multiplicador_jogo * reducao_por_alerta);
                
                -- Skull and Bones (Servidor 3) - Estável, menor popularidade
                WHEN 3 THEN 
                    SET fator_tempo = 1.0;
                    SET multiplicador_jogo = 0.9;
                    SET jogadores = FLOOR((40 + RAND() * 100) * crescimento * fator_tempo * multiplicador_jogo * reducao_por_alerta);
                
                -- Watch Dogs 2 (Servidor 4) - Começa alto, queda drástica
                WHEN 4 THEN 
                    IF dias_passados <= 30 THEN
                        -- Primeiros 30 dias: muito alto
                        SET fator_tempo = 2.0 - (dias_passados / 30.0) * 0.5; -- De 2.0 para 1.5
                    ELSEIF dias_passados <= 60 THEN
                        -- 30-60 dias: queda gradual
                        SET fator_tempo = 1.5 - ((dias_passados - 30) / 30.0) * 0.8; -- De 1.5 para 0.7
                    ELSE
                        -- Após 60 dias: bem baixo
                        SET fator_tempo = 0.7 - ((dias_passados - 60) / 60.0) * 0.4; -- De 0.7 para 0.3
                        IF fator_tempo < 0.3 THEN SET fator_tempo = 0.3; END IF;
                    END IF;
                    SET multiplicador_jogo = 1.5;
                    SET jogadores = FLOOR((100 + RAND() * 200) * crescimento * fator_tempo * multiplicador_jogo * reducao_por_alerta);
                
                -- Star Wars Outlaws (Servidor 5) - Estável, crescimento moderado
                WHEN 5 THEN 
                    SET fator_tempo = 1.0 + (dias_passados / 120.0) * 0.3; -- Crescimento lento
                    SET multiplicador_jogo = 1.1;
                    SET jogadores = FLOOR((60 + RAND() * 120) * crescimento * fator_tempo * multiplicador_jogo * reducao_por_alerta);
                
                -- Rainbow Six Siege (Servidor 6) - Sempre alta quantidade
                WHEN 6 THEN 
                    SET fator_tempo = 1.0 + (dias_passados / 60.0) * 0.2; -- Crescimento constante
                    SET multiplicador_jogo = 2.5; -- Mais popular
                    SET jogadores = FLOOR((150 + RAND() * 250) * crescimento * fator_tempo * multiplicador_jogo * reducao_por_alerta);
            END CASE;
            
            -- Horário de pico (18h às 23h) - ajustado por jogo
            IF hora BETWEEN 18 AND 23 THEN
                CASE servidor_atual
                    WHEN 4 THEN -- Watch Dogs: pico menor após queda
                        IF dias_passados > 60 THEN
                            SET jogadores = jogadores + FLOOR(RAND() * 800 * fator_tempo * reducao_por_alerta);
                        ELSE
                            SET jogadores = jogadores + FLOOR(RAND() * 2500 * fator_tempo * reducao_por_alerta);
                        END IF;
                    WHEN 6 THEN -- Rainbow Six: pico sempre alto
                        SET jogadores = jogadores + FLOOR(RAND() * 3500 * reducao_por_alerta);
                    WHEN 2 THEN -- Assassin's Creed: pico bom mas controlado
                        SET jogadores = jogadores + FLOOR(RAND() * 2200 * reducao_por_alerta);
                    ELSE -- Outros jogos: pico padrão variado
                        SET jogadores = jogadores + FLOOR(RAND() * (1500 + servidor_atual * 200) * reducao_por_alerta);
                END CASE;
            END IF;
            
            -- Final de semana (Sábado=5, Domingo=6) - ajustado por jogo
            IF dia IN (5, 6) THEN
                CASE servidor_atual
                    WHEN 4 THEN -- Watch Dogs: fim de semana menor após queda
                        IF dias_passados > 60 THEN
                            SET jogadores = jogadores + FLOOR(RAND() * 600 * fator_tempo * reducao_por_alerta);
                        ELSE
                            SET jogadores = jogadores + FLOOR(RAND() * 1800 * fator_tempo * reducao_por_alerta);
                        END IF;
                    WHEN 6 THEN -- Rainbow Six: fim de semana sempre forte
                        SET jogadores = jogadores + FLOOR(RAND() * 2800 * reducao_por_alerta);
                    WHEN 2 THEN -- Assassin's Creed: fim de semana bom
                        SET jogadores = jogadores + FLOOR(RAND() * 1600 * reducao_por_alerta);
                    ELSE -- Outros jogos: fim de semana variado
                        SET jogadores = jogadores + FLOOR(RAND() * (1000 + servidor_atual * 150) * reducao_por_alerta);
                END CASE;
            END IF;
            
            -- Garantir valor mínimo por jogo
            CASE servidor_atual
                WHEN 1 THEN IF jogadores < 50 THEN SET jogadores = 50 + FLOOR(RAND() * 50); END IF;
                WHEN 2 THEN IF jogadores < 80 THEN SET jogadores = 80 + FLOOR(RAND() * 70); END IF;
                WHEN 3 THEN IF jogadores < 20 THEN SET jogadores = 20 + FLOOR(RAND() * 30); END IF;
                WHEN 4 THEN 
                    IF dias_passados > 60 THEN
                        IF jogadores < 15 THEN SET jogadores = 15 + FLOOR(RAND() * 25); END IF;
                    ELSE
                        IF jogadores < 60 THEN SET jogadores = 60 + FLOOR(RAND() * 80); END IF;
                    END IF;
                WHEN 5 THEN IF jogadores < 35 THEN SET jogadores = 35 + FLOOR(RAND() * 45); END IF;
                WHEN 6 THEN IF jogadores < 100 THEN SET jogadores = 100 + FLOOR(RAND() * 100); END IF;
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