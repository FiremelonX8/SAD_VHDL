--------------------------------------------------
--	Author:      Ismael Seidel (entidade)
--	Created:     May 1, 2025
--
--	Project:     Exercício 6 de INE5406
--	Description: Contém a descrição da entidade sad_bo, que representa o
--               bloco operativo (BO) do circuito para cálculo da soma das
--               diferenças absolutas (SAD - Sum of Absolute Differences).
--               Este bloco implementa o datapath principal do circuito e
--               realiza operações como subtração, valor absoluto e acumulação
--               dos valores calculados. Além disso, também será feito aqui o
--               calculo de endereçamento e do sinal de controle do laço de
--               execução (menor), que deve ser enviado ao bloco de controle (i.e.,
--               menor será um sinal de status gerado no BO).
--               A parametrização é feita por meio do tipo
--               datapath_configuration_t definido no pacote sad_pack.
--               Os parâmetros incluem:
--               - bits_per_sample: número de bits por amostra; (uso obrigatório)
--               - samples_per_block: número total de amostras por bloco; (uso 
--                 opcional, útil para definição do número de bits da sad ea
--                 endereço, conforme feito no top-level, i.e., no arquivo sad.vhdl)
--               - parallel_samples: número de amostras processadas em paralelo.
--                 (uso opcional)
--               A arquitetura estrutural instanciará os componentes necessários
--               à implementação completa do bloco operativo.
--------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sad_pack.all;

entity sad_bo is
    generic(
        CFG : datapath_configuration_t := (
            bits_per_sample   => 8,
            samples_per_block => 64,
            parallel_samples  => 1
        )
    );
    port(
        clk        : in  std_logic;
        i_comandos : in  comandos_t;
        o_status   : out status_t;
        A          : in  unsigned(CFG.bits_per_sample - 1 downto 0);
        B          : in  unsigned(CFG.bits_per_sample - 1 downto 0);
        endereco   : out unsigned(address_length(CFG.samples_per_block, CFG.parallel_samples) - 1 downto 0);
        SAD        : out unsigned(sad_length(CFG.bits_per_sample, CFG.samples_per_block) - 1 downto 0)
    );
end entity;

architecture structure OF sad_bo is

    -- Constantes de largura
    constant ADDR_WIDTH : positive := address_length(CFG.samples_per_block, CFG.parallel_samples);
    constant SAD_WIDTH  : positive := sad_length(CFG.bits_per_sample, CFG.samples_per_block);
    constant COUNT_WIDTH: positive := ADDR_WIDTH + 1; -- Bit extra para condicao de parada

    -- Sinais do contador (endereco)
    signal contador_q   : unsigned(COUNT_WIDTH - 1 downto 0);
    signal contador_d   : unsigned(COUNT_WIDTH - 1 downto 0);
    signal contador_inc : unsigned(COUNT_WIDTH - 1 downto 0);
    
    -- Sinais dos registradores de entrada (A e B)
    signal a_reg_q      : unsigned(CFG.bits_per_sample - 1 downto 0);
    signal b_reg_q      : unsigned(CFG.bits_per_sample - 1 downto 0);
    
    -- Saida do |A-B|
    signal abs_diff_out : unsigned(CFG.bits_per_sample - 1 downto 0);
    
    -- Sinais do acumulador (SAD)
    signal soma_q       : unsigned(SAD_WIDTH - 1 downto 0);
    signal soma_d       : unsigned(SAD_WIDTH - 1 downto 0);
    signal soma_sum     : unsigned(SAD_WIDTH downto 0);
    signal soma_in_b    : unsigned(SAD_WIDTH - 1 downto 0);

begin

    -- UNIDADE CONTADORA (Endereco e Controle de Loop)
    contador_inc <= contador_q + 1;
    contador_d <= (others => '0') when i_comandos.zi = '1' else contador_inc;
    reg_contador : entity work.unsigned_register
        generic map(N => COUNT_WIDTH)
        port map(clk => clk, enable => i_comandos.ci, d => contador_d, q => contador_q);
    
    -- Saidas de status e endereco (baseadas no contador)
    o_status.menor <= not contador_q(COUNT_WIDTH - 1); -- Flag 'menor que 64'
    endereco <= contador_q(ADDR_WIDTH - 1 downto 0); -- Endereco para memoria

    -- REGISTRADORES DE ENTRADA (A e B)
    reg_A : entity work.unsigned_register
        generic map(N => CFG.bits_per_sample)
        port map(clk => clk, enable => i_comandos.cpA, d => A, q => a_reg_q);

    reg_B : entity work.unsigned_register
        generic map(N => CFG.bits_per_sample)
        port map(clk => clk, enable => i_comandos.cpB, d => B, q => b_reg_q);

    -- CALCULO DA DIFERENCA ABSOLUTA
    calc_abs_diff : entity work.absolute_difference
        generic map(N => CFG.bits_per_sample)
        port map(input_a => a_reg_q, input_b => b_reg_q, abs_diff => abs_diff_out);

    -- UNIDADE ACUMULADORA (Soma)
    soma_in_b <= resize(abs_diff_out, SAD_WIDTH); -- Ajusta largura do resultado
    
    adder_soma : entity work.unsigned_adder
        generic map(N => SAD_WIDTH)
        port map(input_a => soma_q, input_b => soma_in_b, sum => soma_sum);
    
    soma_d <= (others => '0') when i_comandos.zsoma = '1' else soma_sum(SAD_WIDTH - 1 downto 0);
    
    reg_soma : entity work.unsigned_register -- Registrador do acumulador
        generic map(N => SAD_WIDTH)
        port map(clk => clk, enable => i_comandos.csoma, d => soma_d, q => soma_q);

    -- REGISTRADOR DE SAIDA (SAD)
    reg_SAD : entity work.unsigned_register
        generic map(N => SAD_WIDTH)
        port map(clk => clk, enable => i_comandos.csad_reg, d => soma_q, q => SAD);

end architecture structure;