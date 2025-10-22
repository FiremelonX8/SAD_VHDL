--------------------------------------------------
--	Author:      Ismael Seidel (entity)
--	Created:     May 1, 2025
--
--	Project:     Exercício 6 de INE5406
--	Description: Contém a descrição da entidade sad_bc, que representa o
--               bloco de controle (BC) do circuito para cálculo da soma das
--               diferenças absolutas (SAD - Sum of Absolute Differences).
--               Este bloco é responsável pela geração dos sinais de controle
--               necessários para coordenar o funcionamento do bloco operativo
--               (BO), como enable de registradores, seletores de multiplexadores,
--               sinais de início e término de processamento, etc.
--               A arquitetura é comportamental e deverá descrever uma máquina
--               de estados finitos (FSM) adequada ao controle do datapath.
--               Os sinais adicionais de controle devem ser definidos conforme
--               a necessidade do projeto. PS: já foram definidos nos slides
--               da aula 6T.
--------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sad_pack.all;

entity sad_bc is
    port(
        clk       : in  std_logic;
        rst_a     : in  std_logic;
        enable    : in  std_logic;
        done      : out std_logic;
        read_mem  : out std_logic;
        i_status  : in  status_t;
        o_comandos: out comandos_t
    );
end entity;

architecture behavior of sad_bc is

    type state_t is (S0, S1, S2, S3, S4, S5);
    signal current_state, next_state : state_t;

begin

    state_register_proc : process(clk, rst_a)
    begin
        if rst_a = '1' then
            current_state <= S0;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;


    next_state_logic_proc : process(current_state, enable, i_status)
    begin
        case current_state is
            when S0 =>
                if enable = '1' then
                    next_state <= S1;
                else
                    next_state <= S0;
                end if;
            when S1 =>
                next_state <= S2;
            when S2 =>
                if i_status.menor = '1' then
                    next_state <= S3;
                else
                    next_state <= S5;
                end if;
            when S3 =>
                next_state <= S4;
            when S4 =>
                next_state <= S2;
            when S5 =>
                next_state <= S0;
            when others =>
                next_state <= S0;
        end case;
    end process;

    output_logic_proc : process(current_state)
    begin

        done       <= '0';
        read_mem   <= '0';
        o_comandos.zi      <= '0';
        o_comandos.ci      <= '0';
        o_comandos.cpA     <= '0';
        o_comandos.cpB     <= '0';
        o_comandos.zsoma   <= '0';
        o_comandos.csoma   <= '0';
        o_comandos.csad_reg <= '0';

        case current_state is
            when S0 => -- Estado Idle
                done <= '1';

            when S1 => -- Estado de Inicialização
                o_comandos.zi      <= '1';
                o_comandos.ci      <= '1';
                o_comandos.zsoma   <= '1';
                o_comandos.csoma   <= '1';

            when S2 => -- Estado de Verificação do Loop (não faz nada)
                null;

            when S3 => -- Estado de Leitura e Captura
                read_mem   <= '1';
                o_comandos.cpA <= '1';
                o_comandos.cpB <= '1';

            when S4 => -- Estado de Acumulação e Incremento
                o_comandos.ci    <= '1';
                o_comandos.csoma <= '1';

            when S5 => -- Estado Final
                o_comandos.csad_reg <= '1';
            
            when others =>
                null;

        end case;
    end process;
end architecture;