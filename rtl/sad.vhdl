--------------------------------------------------
--	Author:      Ismael Seidel (entity)
--	Created:     May 1, 2025
--
--	Project:     Exercício 6 de INE5406
--	Description: Contém a descrição da entidade sad (que é o top-level). Tal
--               Entidade calcula a Soma das Diferenças Absolutas (SAD) entre
--               duas matrizes (blocos) de amostras, chamadas de bloco original
--               e bloco candidato. Ambos os blocos estão armazenados em memórias 
--               externas: o bloco original está em uma memória chamada de Mem_A
--               e o bloco candidato está em uma memória chamada de Mem_B. As
--               memórias são lidas de maneira assíncrona, através de um sinal
--               de endereço (address) e um sinal que habilita a leitura (read_mem).
--               O valor lido de Mem_A fica disponível na entrada sample_ori, 
--               enquanto que o valor lido de Mem_B fica fisponível na entrada
--               sample_can. O número de bits de cada amostra é parametrizado
--               através do generic bits_per_sample, que tem valor padrão 8. Os
--               valores de cada amostra são números inteiros sem sinal. Além 
--               disso, o número total de amostras por bloco também é parametrizável
--               através do generic samples_per_block. Porém, neste exercício você
--               pode assumir que esse valor não será modificado e será sempre 64.
--               Com 64 amostras em um bloco, podemos assumir que nossa arquitetura
--               será capaz de calcular a SAD entre dois blocos com tamanho 8x8 (cada).
--               Outro parâmetro da entidade é parallel_samples, que define o número
--               de amostras que serão processadas em paralelo. Neste exercício
--               podemos assumir também que esse valor não será modificado, e o 
--               valor padrão será adotado (ou seja, apenas 1 amostra de cada 
--               bloco será lida da memória por vez). Ainda que não sejam obrigatórios,
--               os generics samples_per_block e parallel_samples devem ser mantidos
--               na descrição da entidade. 
--------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sad_pack.all;

entity sad is
    generic(
        bits_per_sample   : positive := 8;
        samples_per_block : positive := 64;
        parallel_samples  : positive := 1
    );
    port(
        clk        : in  std_logic;
        rst_a      : in  std_logic;
        enable     : in  std_logic;
        sample_ori : in  std_logic_vector(bits_per_sample * parallel_samples - 1 downto 0);
        sample_can : in  std_logic_vector(bits_per_sample * parallel_samples - 1 downto 0);
        read_mem   : out std_logic;
        address    : out std_logic_vector(address_length(samples_per_block, parallel_samples) - 1 downto 0);
        sad_value  : out std_logic_vector(sad_length(bits_per_sample, samples_per_block) - 1 downto 0);
        done       : out std_logic
    );
end entity sad;

architecture structure of sad is
    constant CFG_BO : datapath_configuration_t := (
        bits_per_sample   => bits_per_sample,
        samples_per_block => samples_per_block,
        parallel_samples  => parallel_samples
    );
    signal s_comandos : comandos_t;
    signal s_status   : status_t;
    signal s_address_unsigned : unsigned(address'range);
    signal s_sad_unsigned     : unsigned(sad_value'range);
begin
    BC_inst : entity work.sad_bc
        port map(
            clk        => clk,
            rst_a      => rst_a,
            enable     => enable,
            done       => done,
            read_mem   => read_mem,
            i_status   => s_status,
            o_comandos => s_comandos
        );
    BO_inst : entity work.sad_bo
        generic map(
            CFG => CFG_BO
        )
        port map(
            clk        => clk,
            A          => unsigned(sample_ori),
            B          => unsigned(sample_can),
            SAD        => s_sad_unsigned,
            endereco   => s_address_unsigned,
            i_comandos => s_comandos,
            o_status   => s_status
        );
    address   <= std_logic_vector(s_address_unsigned);
    sad_value <= std_logic_vector(s_sad_unsigned);
end architecture structure;